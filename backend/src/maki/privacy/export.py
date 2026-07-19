import hashlib
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Literal, Protocol

from pydantic import Field, field_validator

from maki.billing.models import (
    Entitlement,
    EntitlementStatus,
    Store,
    StoreEvent,
)
from maki.common.models import ApiModel
from maki.jobs.models import JobKind, JobStatus

_MAXIMUM_SUBJECT_LENGTH = 256


class ExportJob(ApiModel):
    job_id: str = Field(pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$")
    kind: JobKind
    status: JobStatus
    created_at: datetime
    completed_at: datetime | None

    @field_validator("kind", mode="before")
    @classmethod
    def parse_kind(cls, value: object) -> JobKind:
        return value if isinstance(value, JobKind) else JobKind(str(value))

    @field_validator("status", mode="before")
    @classmethod
    def parse_status(cls, value: object) -> JobStatus:
        return value if isinstance(value, JobStatus) else JobStatus(str(value))

    @field_validator("created_at", "completed_at")
    @classmethod
    def validate_timestamps(cls, value: datetime | None) -> datetime | None:
        return _utc_timestamp(value)


class ExportBillingEvent(ApiModel):
    store: Store
    product_id: str = Field(pattern=r"^[a-z0-9_.-]{3,128}$")
    event: StoreEvent
    occurred_at: datetime
    expires_at: datetime | None

    @field_validator("occurred_at", "expires_at")
    @classmethod
    def validate_timestamps(cls, value: datetime | None) -> datetime | None:
        return _utc_timestamp(value)


@dataclass(frozen=True, slots=True)
class SubjectDataSnapshot:
    entitlements: tuple[Entitlement, ...]
    jobs: tuple[ExportJob, ...]
    billing_events: tuple[ExportBillingEvent, ...]


class ExportRepository(Protocol):
    async def load(self, *, subject_hash: str) -> SubjectDataSnapshot: ...


class ExportEntitlement(ApiModel):
    store: Store
    product_id: str = Field(pattern=r"^[a-z0-9_.-]{3,128}$")
    status: EntitlementStatus
    expires_at: datetime | None

    @classmethod
    def from_domain(cls, entitlement: Entitlement) -> "ExportEntitlement":
        return cls(
            store=entitlement.store,
            product_id=entitlement.product_id,
            status=entitlement.status,
            expires_at=entitlement.expires_at,
        )


class DataExport(ApiModel):
    schema_version: Literal["1.0"] = "1.0"
    generated_at: datetime
    entitlements: tuple[ExportEntitlement, ...]
    jobs: tuple[ExportJob, ...]
    billing_events: tuple[ExportBillingEvent, ...]

    @field_validator("generated_at")
    @classmethod
    def validate_generated_at(cls, value: datetime) -> datetime:
        validated = _utc_timestamp(value)
        if validated is None:
            msg = "Dışa aktarma zamanı eksik."
            raise ValueError(msg)
        return validated


class DataExporter:
    def __init__(
        self,
        *,
        repository: ExportRepository,
        clock: Callable[[], datetime],
    ) -> None:
        self._repository = repository
        self._clock = clock

    async def export(self, *, subject_id: str) -> DataExport:
        if not 1 <= len(subject_id) <= _MAXIMUM_SUBJECT_LENGTH:
            msg = "Dışa aktarma özne kimliği geçersiz."
            raise ValueError(msg)
        snapshot = await self._repository.load(
            subject_hash=_subject_hash(subject_id),
        )
        return DataExport(
            generated_at=self._clock(),
            entitlements=tuple(
                ExportEntitlement.from_domain(entitlement) for entitlement in snapshot.entitlements
            ),
            jobs=snapshot.jobs,
            billing_events=snapshot.billing_events,
        )


def _subject_hash(subject_id: str) -> str:
    return hashlib.sha256(subject_id.encode()).hexdigest()


def _utc_timestamp(value: datetime | None) -> datetime | None:
    if value is not None and (value.tzinfo is None or value.utcoffset() != UTC.utcoffset(value)):
        msg = "Dışa aktarma zamanları UTC olmalıdır."
        raise ValueError(msg)
    return value
