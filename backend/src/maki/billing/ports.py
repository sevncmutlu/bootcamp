from typing import Protocol

from maki.billing.models import Entitlement, StoreTransaction


class EntitlementRepository(Protocol):
    async def apply(
        self,
        transaction: StoreTransaction,
        proposed: Entitlement,
    ) -> Entitlement: ...

    async def list_for_subject(
        self,
        *,
        subject_hash: str,
    ) -> tuple[Entitlement, ...]: ...
