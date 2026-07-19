import hashlib

import orjson
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from maki.billing.models import (
    Entitlement,
    EntitlementStatus,
    Store,
    StoreEvent,
    StoreTransaction,
)
from maki.infrastructure.subject_lock import lock_subject
from maki.infrastructure.tables import (
    EntitlementTable,
    StoreTransactionTable,
)


class SqlAlchemyEntitlementRepository:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
    ) -> None:
        self._session_factory = session_factory

    async def apply(
        self,
        transaction: StoreTransaction,
        proposed: Entitlement,
    ) -> Entitlement:
        async with self._session_factory() as session, session.begin():
            await lock_subject(session, transaction.subject_hash)
            existing_event = await session.get(
                StoreTransactionTable,
                transaction.event_id,
            )
            entitlement_row = await session.scalar(
                select(EntitlementTable)
                .where(
                    EntitlementTable.subject_hash == transaction.subject_hash,
                    EntitlementTable.product_id == transaction.product_id,
                )
                .with_for_update()
            )
            if existing_event is not None:
                if entitlement_row is None:
                    msg = "Mağaza olayı hak kaydına bağlı değil."
                    raise RuntimeError(msg)
                return _to_entitlement(entitlement_row)

            session.add(_transaction_row(transaction))
            await session.flush()
            if entitlement_row is None:
                session.add(_entitlement_row(proposed))
                return proposed
            current = _to_entitlement(entitlement_row)
            if proposed.event_order > current.event_order:
                _apply_entitlement(entitlement_row, proposed)
                return proposed
            return current

    async def list_for_subject(
        self,
        *,
        subject_hash: str,
    ) -> tuple[Entitlement, ...]:
        async with self._session_factory() as session:
            rows = await session.scalars(
                select(EntitlementTable)
                .where(EntitlementTable.subject_hash == subject_hash)
                .order_by(
                    EntitlementTable.product_id,
                    EntitlementTable.store,
                )
            )
            return tuple(_to_entitlement(row) for row in rows)


def _transaction_row(transaction: StoreTransaction) -> StoreTransactionTable:
    summary = transaction.model_dump(
        mode="json",
        exclude={"verified"},
    )
    digest = hashlib.sha256(orjson.dumps(summary, option=orjson.OPT_SORT_KEYS)).hexdigest()
    return StoreTransactionTable(
        event_id=transaction.event_id,
        store=transaction.store.value,
        transaction_id=transaction.transaction_id,
        original_transaction_id=transaction.original_transaction_id,
        product_id=transaction.product_id,
        subject_hash=transaction.subject_hash,
        event=transaction.event.value,
        event_version=transaction.event_version,
        occurred_at=transaction.occurred_at,
        expires_at=transaction.expires_at,
        event_sha256=digest,
    )


def _entitlement_row(entitlement: Entitlement) -> EntitlementTable:
    return EntitlementTable(
        subject_hash=entitlement.subject_hash,
        product_id=entitlement.product_id,
        store=entitlement.store.value,
        status=entitlement.status.value,
        original_transaction_id=entitlement.original_transaction_id,
        expires_at=entitlement.expires_at,
        last_event_id=entitlement.last_event_id,
        last_event=entitlement.last_event.value,
        last_event_version=entitlement.last_event_version,
        last_event_at=entitlement.last_event_at,
    )


def _to_entitlement(row: EntitlementTable) -> Entitlement:
    return Entitlement(
        subject_hash=row.subject_hash,
        product_id=row.product_id,
        store=Store(row.store),
        status=EntitlementStatus(row.status),
        original_transaction_id=row.original_transaction_id,
        expires_at=row.expires_at,
        last_event_id=row.last_event_id,
        last_event=StoreEvent(row.last_event),
        last_event_version=row.last_event_version,
        last_event_at=row.last_event_at,
    )


def _apply_entitlement(
    row: EntitlementTable,
    entitlement: Entitlement,
) -> None:
    row.store = entitlement.store.value
    row.status = entitlement.status.value
    row.original_transaction_id = entitlement.original_transaction_id
    row.expires_at = entitlement.expires_at
    row.last_event_id = entitlement.last_event_id
    row.last_event = entitlement.last_event.value
    row.last_event_version = entitlement.last_event_version
    row.last_event_at = entitlement.last_event_at
