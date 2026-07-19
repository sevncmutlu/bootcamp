import hashlib
from typing import Protocol

from maki.billing.account_tokens import AppleAccountTokenIssuer
from maki.billing.models import Entitlement, StoreTransaction
from maki.billing.service import BillingService


class ProviderNotConfigured(RuntimeError):  # noqa: N818
    pass


class GoogleVerifier(Protocol):
    async def verify(
        self,
        *,
        package_name: str,
        purchase_token: str,
        subject_hash: str,
    ) -> StoreTransaction: ...


class AppleVerifier(Protocol):
    def verify(
        self,
        *,
        signed_transaction: str,
        expected_account_token: str,
        subject_hash: str,
    ) -> StoreTransaction: ...


class BillingVerificationService:
    def __init__(
        self,
        *,
        billing: BillingService | None,
        google: GoogleVerifier | None,
        apple: AppleVerifier | None,
        apple_account_tokens: AppleAccountTokenIssuer | None = None,
    ) -> None:
        self._billing = billing
        self._google = google
        self._apple = apple
        self._apple_account_tokens = apple_account_tokens

    async def verify_google(
        self,
        *,
        package_name: str,
        purchase_token: str,
        subject_id: str,
    ) -> Entitlement:
        if self._google is None or self._billing is None:
            raise ProviderNotConfigured
        transaction = await self._google.verify(
            package_name=package_name,
            purchase_token=purchase_token,
            subject_hash=_subject_hash(subject_id),
        )
        return await self._billing.apply(transaction)

    async def verify_apple(
        self,
        *,
        signed_transaction: str,
        subject_id: str,
    ) -> Entitlement:
        if self._apple is None or self._billing is None or self._apple_account_tokens is None:
            raise ProviderNotConfigured
        transaction = self._apple.verify(
            signed_transaction=signed_transaction,
            expected_account_token=self._apple_account_tokens.for_subject(subject_id),
            subject_hash=_subject_hash(subject_id),
        )
        return await self._billing.apply(transaction)

    async def entitlements(self, *, subject_id: str) -> tuple[Entitlement, ...]:
        if self._billing is None:
            raise ProviderNotConfigured
        return await self._billing.list_for_subject(
            subject_hash=_subject_hash(subject_id),
        )


def _subject_hash(subject_id: str) -> str:
    return hashlib.sha256(subject_id.encode()).hexdigest()
