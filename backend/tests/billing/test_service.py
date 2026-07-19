from datetime import UTC, datetime, timedelta

import pytest

from maki.billing.models import (
    Entitlement,
    EntitlementStatus,
    Store,
    StoreEvent,
    StoreTransaction,
)
from maki.billing.service import BillingService, UnverifiedTransaction

NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)


class MemoryEntitlementRepository:
    def __init__(self) -> None:
        self.entitlement: Entitlement | None = None
        self.events: set[str] = set()

    async def apply(
        self,
        transaction: StoreTransaction,
        proposed: Entitlement,
    ) -> Entitlement:
        if transaction.event_id in self.events:
            assert self.entitlement is not None
            return self.entitlement
        self.events.add(transaction.event_id)
        if self.entitlement is None or proposed.event_order > self.entitlement.event_order:
            self.entitlement = proposed
        assert self.entitlement is not None
        return self.entitlement

    async def count(self) -> int:
        return len(self.events)


async def test_unverified_transaction_never_grants_entitlement() -> None:
    repository = MemoryEntitlementRepository()
    service = BillingService(repository=repository)

    with pytest.raises(UnverifiedTransaction):
        await service.apply(_transaction(verified=False))

    assert await repository.count() == 0


async def test_refund_wins_and_older_renewal_cannot_restore_access() -> None:
    repository = MemoryEntitlementRepository()
    service = BillingService(repository=repository)

    active = await service.apply(_transaction())
    refunded = await service.apply(
        _transaction(
            event_id="event-refund",
            event=StoreEvent.REFUNDED,
            occurred_at=NOW + timedelta(hours=2),
            event_version=2,
        )
    )
    stale = await service.apply(
        _transaction(
            event_id="event-stale",
            event=StoreEvent.RENEWED,
            occurred_at=NOW + timedelta(hours=1),
            event_version=1,
        )
    )

    assert active.status is EntitlementStatus.ACTIVE
    assert refunded.status is EntitlementStatus.REFUNDED
    assert stale.status is EntitlementStatus.REFUNDED


async def test_duplicate_event_is_idempotent() -> None:
    repository = MemoryEntitlementRepository()
    service = BillingService(repository=repository)
    transaction = _transaction()

    first = await service.apply(transaction)
    second = await service.apply(transaction)

    assert first == second
    assert await repository.count() == 1


def _transaction(
    *,
    event_id: str = "event-purchase",
    event: StoreEvent = StoreEvent.PURCHASED,
    occurred_at: datetime = NOW,
    event_version: int = 1,
    verified: bool = True,
) -> StoreTransaction:
    return StoreTransaction(
        event_id=event_id,
        store=Store.GOOGLE_PLAY,
        transaction_id="tx-1",
        original_transaction_id="original-1",
        product_id="maki_debt_pro",
        subject_hash="a" * 64,
        verified=verified,
        event=event,
        event_version=event_version,
        occurred_at=occurred_at,
        expires_at=NOW + timedelta(days=30),
    )
