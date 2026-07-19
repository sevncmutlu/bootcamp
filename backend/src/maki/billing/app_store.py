import hashlib
from collections.abc import Callable
from datetime import UTC, datetime
from typing import Literal
from uuid import UUID

from cryptography import x509
from pydantic import Field, field_validator

from maki.billing.google_play import StoreVerificationError
from maki.billing.jws import AppleJwsVerifier
from maki.billing.models import Store, StoreEvent, StoreTransaction
from maki.common.models import ApiModel


class _AppleTransaction(ApiModel):
    transaction_id: str = Field(alias="transactionId", min_length=1, max_length=256)
    original_transaction_id: str = Field(
        alias="originalTransactionId",
        min_length=1,
        max_length=256,
    )
    bundle_id: str = Field(alias="bundleId", min_length=3, max_length=256)
    product_id: str = Field(alias="productId", min_length=3, max_length=128)
    purchase_date: int = Field(alias="purchaseDate", ge=0)
    expires_date: int = Field(alias="expiresDate", ge=0)
    signed_date: int = Field(alias="signedDate", ge=0)
    environment: Literal["Production", "Sandbox"]
    app_account_token: UUID = Field(alias="appAccountToken")
    type: Literal["Auto-Renewable Subscription"]
    revocation_date: int | None = Field(default=None, alias="revocationDate", ge=0)
    revocation_reason: int | None = Field(default=None, alias="revocationReason")

    @field_validator("environment", mode="before")
    @classmethod
    def parse_environment(cls, value: object) -> str:
        return str(value)


class AppStoreVerifier:
    def __init__(
        self,
        *,
        trusted_root: x509.Certificate,
        bundle_id: str,
        allowed_products: frozenset[str],
        environment: Literal["Production", "Sandbox"],
        clock: Callable[[], datetime],
    ) -> None:
        if not bundle_id or not allowed_products:
            msg = "App Store bundle ve ürün izin listesi boş olamaz."
            raise ValueError(msg)
        self._jws = AppleJwsVerifier(trusted_root=trusted_root, clock=clock)
        self._bundle_id = bundle_id
        self._allowed_products = allowed_products
        self._environment = environment
        self._clock = clock

    def verify(
        self,
        *,
        signed_transaction: str,
        expected_account_token: str,
        subject_hash: str,
    ) -> StoreTransaction:
        payload = self._jws.verify(signed_transaction)
        try:
            transaction = _AppleTransaction.model_validate_json(payload)
        except ValueError:
            msg = "Apple işlem şeması doğrulanamadı."
            raise StoreVerificationError(msg) from None
        self._validate_binding(transaction, expected_account_token)
        now = self._clock().astimezone(UTC)
        expires_at = _milliseconds(transaction.expires_date)
        event = _event(transaction, expires_at, now)
        identity = (
            f"{transaction.transaction_id}:"
            f"{transaction.signed_date}:"
            f"{transaction.revocation_date or 0}"
        )
        return StoreTransaction(
            event_id=hashlib.sha256(identity.encode()).hexdigest(),
            store=Store.APP_STORE,
            transaction_id=transaction.transaction_id,
            original_transaction_id=transaction.original_transaction_id,
            product_id=transaction.product_id,
            subject_hash=subject_hash,
            verified=True,
            event=event,
            event_version=transaction.signed_date,
            occurred_at=_milliseconds(transaction.revocation_date or transaction.purchase_date),
            expires_at=expires_at,
        )

    def _validate_binding(
        self,
        transaction: _AppleTransaction,
        expected_account_token: str,
    ) -> None:
        if transaction.bundle_id != self._bundle_id:
            msg = "Apple bundle kimliği eşleşmiyor."
            raise StoreVerificationError(msg)
        if transaction.product_id not in self._allowed_products:
            msg = "Apple ürün kimliği izinli değil."
            raise StoreVerificationError(msg)
        if transaction.environment != self._environment:
            msg = "Apple mağaza ortamı eşleşmiyor."
            raise StoreVerificationError(msg)
        if str(transaction.app_account_token) != expected_account_token:
            msg = "Apple hesap bağı eşleşmiyor."
            raise StoreVerificationError(msg)


def _event(
    transaction: _AppleTransaction,
    expires_at: datetime,
    now: datetime,
) -> StoreEvent:
    if transaction.revocation_date is not None:
        return StoreEvent.REFUNDED
    if expires_at <= now:
        return StoreEvent.EXPIRED
    return StoreEvent.RENEWED


def _milliseconds(value: int) -> datetime:
    return datetime.fromtimestamp(value / 1_000, tz=UTC)
