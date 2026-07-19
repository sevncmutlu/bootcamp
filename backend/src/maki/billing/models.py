from datetime import UTC, datetime
from enum import StrEnum
from typing import Self

from pydantic import Field, field_validator, model_validator

from maki.common.models import ApiModel


class Store(StrEnum):
    GOOGLE_PLAY = "google_play"
    APP_STORE = "app_store"


class StoreEvent(StrEnum):
    PURCHASED = "purchased"
    RENEWED = "renewed"
    GRACE_PERIOD = "grace_period"
    CANCELED = "canceled"
    EXPIRED = "expired"
    REVOKED = "revoked"
    REFUNDED = "refunded"
    RESTORED = "restored"


class EntitlementStatus(StrEnum):
    ACTIVE = "active"
    GRACE_PERIOD = "grace_period"
    EXPIRED = "expired"
    REVOKED = "revoked"
    REFUNDED = "refunded"


_EVENT_STATUS = {
    StoreEvent.PURCHASED: EntitlementStatus.ACTIVE,
    StoreEvent.RENEWED: EntitlementStatus.ACTIVE,
    StoreEvent.GRACE_PERIOD: EntitlementStatus.GRACE_PERIOD,
    StoreEvent.CANCELED: EntitlementStatus.ACTIVE,
    StoreEvent.EXPIRED: EntitlementStatus.EXPIRED,
    StoreEvent.REVOKED: EntitlementStatus.REVOKED,
    StoreEvent.REFUNDED: EntitlementStatus.REFUNDED,
    StoreEvent.RESTORED: EntitlementStatus.ACTIVE,
}
_EVENT_PRIORITY = {
    StoreEvent.PURCHASED: 10,
    StoreEvent.RENEWED: 20,
    StoreEvent.RESTORED: 30,
    StoreEvent.CANCELED: 40,
    StoreEvent.GRACE_PERIOD: 50,
    StoreEvent.EXPIRED: 60,
    StoreEvent.REVOKED: 70,
    StoreEvent.REFUNDED: 80,
}
_EXPIRING_EVENTS = frozenset(
    {
        StoreEvent.PURCHASED,
        StoreEvent.RENEWED,
        StoreEvent.CANCELED,
        StoreEvent.GRACE_PERIOD,
        StoreEvent.RESTORED,
    }
)


class StoreTransaction(ApiModel):
    event_id: str = Field(min_length=1, max_length=256)
    store: Store
    transaction_id: str = Field(min_length=1, max_length=256)
    original_transaction_id: str = Field(min_length=1, max_length=256)
    product_id: str = Field(pattern=r"^[a-z0-9_.-]{3,128}$")
    subject_hash: str = Field(pattern=r"^[0-9a-f]{64}$")
    verified: bool
    event: StoreEvent
    event_version: int = Field(ge=0)
    occurred_at: datetime
    expires_at: datetime | None = None

    @field_validator("store", mode="before")
    @classmethod
    def parse_store(cls, value: object) -> Store:
        return value if isinstance(value, Store) else Store(str(value))

    @field_validator("event", mode="before")
    @classmethod
    def parse_event(cls, value: object) -> StoreEvent:
        return value if isinstance(value, StoreEvent) else StoreEvent(str(value))

    @field_validator("occurred_at", "expires_at")
    @classmethod
    def timestamps_must_be_utc(cls, value: datetime | None) -> datetime | None:
        if value is not None and (
            value.tzinfo is None or value.utcoffset() != UTC.utcoffset(value)
        ):
            msg = "Mağaza işlem zamanları UTC olmalıdır."
            raise ValueError(msg)
        return value

    @model_validator(mode="after")
    def active_events_must_have_expiry(self) -> Self:
        if self.event in _EXPIRING_EVENTS and self.expires_at is None:
            msg = "Erişim veren mağaza olayı süre sonu taşımalıdır."
            raise ValueError(msg)
        return self

    @property
    def event_order(self) -> tuple[datetime, int, int]:
        return (
            self.occurred_at,
            self.event_version,
            _EVENT_PRIORITY[self.event],
        )


class Entitlement(ApiModel):
    subject_hash: str = Field(pattern=r"^[0-9a-f]{64}$")
    product_id: str = Field(pattern=r"^[a-z0-9_.-]{3,128}$")
    store: Store
    status: EntitlementStatus
    original_transaction_id: str = Field(min_length=1, max_length=256)
    expires_at: datetime | None
    last_event_id: str = Field(min_length=1, max_length=256)
    last_event: StoreEvent
    last_event_version: int = Field(ge=0)
    last_event_at: datetime

    @property
    def event_order(self) -> tuple[datetime, int, int]:
        return (
            self.last_event_at,
            self.last_event_version,
            _EVENT_PRIORITY[self.last_event],
        )

    @classmethod
    def from_transaction(cls, transaction: StoreTransaction) -> "Entitlement":
        return cls(
            subject_hash=transaction.subject_hash,
            product_id=transaction.product_id,
            store=transaction.store,
            status=_EVENT_STATUS[transaction.event],
            original_transaction_id=transaction.original_transaction_id,
            expires_at=transaction.expires_at,
            last_event_id=transaction.event_id,
            last_event=transaction.event,
            last_event_version=transaction.event_version,
            last_event_at=transaction.occurred_at,
        )
