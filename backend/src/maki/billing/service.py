from maki.billing.models import Entitlement, StoreTransaction
from maki.billing.ports import EntitlementRepository


class UnverifiedTransaction(ValueError):  # noqa: N818
    pass


class BillingService:
    def __init__(self, *, repository: EntitlementRepository) -> None:
        self._repository = repository

    async def apply(self, transaction: StoreTransaction) -> Entitlement:
        if not transaction.verified:
            msg = "Doğrulanmamış mağaza işlemi hak veremez."
            raise UnverifiedTransaction(msg)
        proposed = Entitlement.from_transaction(transaction)
        return await self._repository.apply(transaction, proposed)

    async def list_for_subject(
        self,
        *,
        subject_hash: str,
    ) -> tuple[Entitlement, ...]:
        return await self._repository.list_for_subject(subject_hash=subject_hash)
