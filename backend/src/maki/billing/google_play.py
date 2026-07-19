from __future__ import annotations

import asyncio
import hashlib
import importlib
import json
from datetime import UTC, datetime
from typing import TYPE_CHECKING, Annotated, Literal, Protocol, cast

import orjson
from pydantic import BeforeValidator, Field, JsonValue, field_validator

from maki.billing.models import Store, StoreEvent, StoreTransaction
from maki.common.models import ApiModel

if TYPE_CHECKING:
    from collections.abc import Callable


def _tuple_from_list(value: object) -> object:
    if isinstance(value, list):
        return tuple(value)
    return value


class StoreVerificationError(ValueError):
    pass


class StoreProviderUnavailableError(RuntimeError):
    pass


class GooglePublisher(Protocol):
    async def get_subscription(
        self,
        *,
        package_name: str,
        purchase_token: str,
    ) -> dict[str, object]: ...


class _GoogleRequest(Protocol):
    def execute(self) -> object: ...


class _GoogleSubscriptionsV2(Protocol):
    def get(
        self,
        *,
        packageName: str,  # noqa: N803
        token: str,
    ) -> _GoogleRequest: ...


class _GooglePurchases(Protocol):
    def subscriptionsv2(self) -> _GoogleSubscriptionsV2: ...


class _GoogleService(Protocol):
    def purchases(self) -> _GooglePurchases: ...


class _CredentialsFactory(Protocol):
    def from_service_account_info(
        self,
        info: dict[str, object],
        *,
        scopes: tuple[str, ...],
    ) -> object: ...


class GooglePublisherClient:
    def __init__(self, *, service: _GoogleService) -> None:
        self._service = service

    @classmethod
    def from_service_account_json(cls, value: str) -> GooglePublisherClient:
        document = _service_account_document(value)
        try:
            credentials_factory = cast(
                "_CredentialsFactory",
                importlib.import_module("google.oauth2.service_account").Credentials,
            )
            build = cast(
                "Callable[..., object]",
                importlib.import_module("googleapiclient.discovery").build,
            )
            credentials = credentials_factory.from_service_account_info(
                document,
                scopes=("https://www.googleapis.com/auth/androidpublisher",),
            )
            service = build(
                "androidpublisher",
                "v3",
                credentials=credentials,
                cache_discovery=False,
            )
        except (TypeError, ValueError):
            msg = "Google Play servis hesabı ayarı geçersiz."
            raise StoreVerificationError(msg) from None
        return cls(service=cast("_GoogleService", service))

    async def get_subscription(
        self,
        *,
        package_name: str,
        purchase_token: str,
    ) -> dict[str, object]:
        try:
            response = await asyncio.to_thread(
                self._execute,
                package_name,
                purchase_token,
            )
        except Exception as error:
            status = _provider_status(error)
            if status is not None and _CLIENT_ERROR_MINIMUM <= status < _SERVER_ERROR_MINIMUM:
                msg = "Google Play satın alım kanıtını reddetti."
                raise StoreVerificationError(msg) from error
            msg = "Google Play servisine ulaşılamadı."
            raise StoreProviderUnavailableError(msg) from error
        if not isinstance(response, dict) or not all(isinstance(key, str) for key in response):
            msg = "Google Play yanıtı nesne biçiminde değil."
            raise StoreVerificationError(msg)
        return cast("dict[str, object]", response)

    def _execute(self, package_name: str, purchase_token: str) -> object:
        return (
            self._service.purchases()
            .subscriptionsv2()
            .get(
                packageName=package_name,
                token=purchase_token,
            )
            .execute()
        )


def _service_account_document(value: str) -> dict[str, object]:
    try:
        document: object = json.loads(value)
    except (TypeError, ValueError):
        msg = "Google Play servis hesabı ayarı geçersiz."
        raise StoreVerificationError(msg) from None
    if not isinstance(document, dict) or not all(isinstance(key, str) for key in document):
        msg = "Google Play servis hesabı nesne biçiminde değil."
        raise StoreVerificationError(msg)
    return cast("dict[str, object]", document)


def _provider_status(error: Exception) -> int | None:
    response = getattr(error, "resp", None)
    status = getattr(response, "status", None)
    return status if isinstance(status, int) else None


class _ExternalIdentifiers(ApiModel):
    obfuscated_external_account_id: str = Field(
        alias="obfuscatedExternalAccountId",
        pattern=r"^[0-9a-f]{64}$",
    )
    obfuscated_external_profile_id: str | None = Field(
        default=None,
        alias="obfuscatedExternalProfileId",
    )


class _LineItem(ApiModel):
    product_id: str = Field(alias="productId", min_length=3, max_length=128)
    expiry_time: datetime = Field(alias="expiryTime")
    latest_successful_order_id: str | None = Field(
        default=None,
        alias="latestSuccessfulOrderId",
    )
    auto_renewing_plan: dict[str, JsonValue] | None = Field(
        default=None,
        alias="autoRenewingPlan",
    )
    prepaid_plan: dict[str, JsonValue] | None = Field(
        default=None,
        alias="prepaidPlan",
    )
    offer_details: dict[str, JsonValue] | None = Field(
        default=None,
        alias="offerDetails",
    )

    @field_validator("expiry_time", mode="before")
    @classmethod
    def parse_expiry_time(cls, value: object) -> datetime:
        return _parse_utc_datetime(value)


LineItems = Annotated[
    tuple[_LineItem, ...],
    BeforeValidator(_tuple_from_list),
    Field(min_length=1, max_length=20),
]


class _GoogleSubscription(ApiModel):
    kind: Literal["androidpublisher#subscriptionPurchaseV2"]
    subscription_state: str = Field(alias="subscriptionState")
    acknowledgement_state: str = Field(alias="acknowledgementState")
    latest_order_id: str = Field(alias="latestOrderId", min_length=1, max_length=256)
    start_time: datetime = Field(alias="startTime")
    region_code: str = Field(alias="regionCode", pattern=r"^[A-Z]{2}$")
    external_account_identifiers: _ExternalIdentifiers = Field(alias="externalAccountIdentifiers")
    line_items: LineItems = Field(alias="lineItems")
    linked_purchase_token: str | None = Field(
        default=None,
        alias="linkedPurchaseToken",
    )
    test_purchase: dict[str, JsonValue] | None = Field(
        default=None,
        alias="testPurchase",
    )
    etag: str | None = None
    paused_state_context: dict[str, JsonValue] | None = Field(
        default=None,
        alias="pausedStateContext",
    )
    canceled_state_context: dict[str, JsonValue] | None = Field(
        default=None,
        alias="canceledStateContext",
    )
    in_grace_period_state_context: dict[str, JsonValue] | None = Field(
        default=None,
        alias="inGracePeriodStateContext",
    )
    on_hold_state_context: dict[str, JsonValue] | None = Field(
        default=None,
        alias="onHoldStateContext",
    )

    @field_validator("start_time", mode="before")
    @classmethod
    def parse_start_time(cls, value: object) -> datetime:
        return _parse_utc_datetime(value)


_STATE_EVENT = {
    "SUBSCRIPTION_STATE_ACTIVE": StoreEvent.RENEWED,
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD": StoreEvent.GRACE_PERIOD,
    "SUBSCRIPTION_STATE_CANCELED": StoreEvent.CANCELED,
    "SUBSCRIPTION_STATE_EXPIRED": StoreEvent.EXPIRED,
    "SUBSCRIPTION_STATE_ON_HOLD": StoreEvent.EXPIRED,
    "SUBSCRIPTION_STATE_PAUSED": StoreEvent.EXPIRED,
}
_ACKNOWLEDGED = "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED"
_CLIENT_ERROR_MINIMUM = 400
_SERVER_ERROR_MINIMUM = 500


class GooglePlayVerifier:
    def __init__(
        self,
        *,
        publisher: GooglePublisher,
        package_name: str,
        allowed_products: frozenset[str],
        clock: Callable[[], datetime],
    ) -> None:
        if not package_name or not allowed_products:
            msg = "Google Play paket ve ürün izin listesi boş olamaz."
            raise ValueError(msg)
        self._publisher = publisher
        self._package_name = package_name
        self._allowed_products = allowed_products
        self._clock = clock

    async def verify(
        self,
        *,
        package_name: str,
        purchase_token: str,
        subject_hash: str,
    ) -> StoreTransaction:
        if package_name != self._package_name:
            msg = "Google Play paket kimliği eşleşmiyor."
            raise StoreVerificationError(msg)
        response = await self._publisher.get_subscription(
            package_name=self._package_name,
            purchase_token=purchase_token,
        )
        try:
            subscription = _GoogleSubscription.model_validate_json(orjson.dumps(response))
        except ValueError:
            msg = "Google Play yanıt şeması doğrulanamadı."
            raise StoreVerificationError(msg) from None
        line = self._validated_line(subscription, subject_hash)
        event = _STATE_EVENT.get(subscription.subscription_state)
        if event is None:
            msg = "Google Play abonelik durumu erişim vermiyor."
            raise StoreVerificationError(msg)
        now = self._clock().astimezone(UTC)
        if line.expiry_time <= now:
            event = StoreEvent.EXPIRED
        identity = (
            f"{subscription.latest_order_id}:"
            f"{subscription.subscription_state}:"
            f"{line.expiry_time.isoformat()}"
        )
        return StoreTransaction(
            event_id=hashlib.sha256(identity.encode()).hexdigest(),
            store=Store.GOOGLE_PLAY,
            transaction_id=subscription.latest_order_id,
            original_transaction_id=_original_id(subscription),
            product_id=line.product_id,
            subject_hash=subject_hash,
            verified=True,
            event=event,
            event_version=int(line.expiry_time.timestamp() * 1_000),
            occurred_at=now,
            expires_at=line.expiry_time,
        )

    def _validated_line(
        self,
        subscription: _GoogleSubscription,
        subject_hash: str,
    ) -> _LineItem:
        if subscription.acknowledgement_state != _ACKNOWLEDGED:
            msg = "Google Play satın alımı onaylanmamış."
            raise StoreVerificationError(msg)
        if subscription.test_purchase is not None:
            msg = "Google Play test satın alımı üretimde kabul edilmez."
            raise StoreVerificationError(msg)
        if subscription.external_account_identifiers.obfuscated_external_account_id != subject_hash:
            msg = "Google Play hesap bağı eşleşmiyor."
            raise StoreVerificationError(msg)
        if any(line.product_id not in self._allowed_products for line in subscription.line_items):
            msg = "Google Play ürün kimliği izinli değil."
            raise StoreVerificationError(msg)
        return max(subscription.line_items, key=lambda item: item.expiry_time)


def _original_id(subscription: _GoogleSubscription) -> str:
    if subscription.linked_purchase_token is None:
        return subscription.latest_order_id
    return hashlib.sha256(subscription.linked_purchase_token.encode()).hexdigest()


def _parse_utc_datetime(value: object) -> datetime:
    if isinstance(value, datetime):
        parsed = value
    elif isinstance(value, str):
        parsed = datetime.fromisoformat(value)
    else:
        msg = "Google Play zaman alanı geçersiz."
        raise TypeError(msg)
    if parsed.tzinfo is None:
        msg = "Google Play zamanı saat dilimi taşımalıdır."
        raise ValueError(msg)
    return parsed.astimezone(UTC)
