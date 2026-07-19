from collections.abc import Mapping
from datetime import datetime, timedelta
from enum import StrEnum
from typing import ClassVar, Self

from pydantic import Field, JsonValue, field_validator

from maki.common.ids import new_ulid
from maki.common.models import ApiModel


class JobKind(StrEnum):
    COACH = "coach"
    FORECAST = "forecast"
    RECEIPT = "receipt"
    MODEL_TRAINING = "model_training"
    BILLING_VERIFICATION = "billing_verification"
    RETENTION = "retention"


class JobStatus(StrEnum):
    ACCEPTED = "accepted"
    QUEUED = "queued"
    RUNNING = "running"
    RETRY_WAIT = "retry_wait"
    SUCCEEDED = "succeeded"
    FAILED = "failed"

    @property
    def is_terminal(self) -> bool:
        return self in {JobStatus.SUCCEEDED, JobStatus.FAILED}


class JobRecord(ApiModel):
    _TRANSITIONS: ClassVar[Mapping[JobStatus, frozenset[JobStatus]]] = {
        JobStatus.ACCEPTED: frozenset({JobStatus.QUEUED, JobStatus.FAILED}),
        JobStatus.QUEUED: frozenset({JobStatus.RUNNING, JobStatus.FAILED}),
        JobStatus.RUNNING: frozenset({JobStatus.SUCCEEDED, JobStatus.FAILED, JobStatus.RETRY_WAIT}),
        JobStatus.RETRY_WAIT: frozenset({JobStatus.QUEUED, JobStatus.FAILED}),
        JobStatus.SUCCEEDED: frozenset(),
        JobStatus.FAILED: frozenset(),
    }

    job_id: str = Field(pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$")
    kind: JobKind
    status: JobStatus
    owner_hash: str = Field(pattern=r"^[a-f0-9]{64}$")
    payload: dict[str, JsonValue]
    payload_hash: str = Field(pattern=r"^[a-f0-9]{64}$")
    created_at: datetime
    updated_at: datetime
    started_at: datetime | None = None
    completed_at: datetime | None = None
    failure_code: str | None = Field(default=None, max_length=64)
    lease_token: str | None = Field(
        default=None,
        pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$",
    )
    lease_expires_at: datetime | None = None
    attempt: int = Field(default=0, ge=0)
    version: int = Field(default=0, ge=0)

    @field_validator(
        "created_at",
        "updated_at",
        "started_at",
        "completed_at",
        "lease_expires_at",
    )
    @classmethod
    def timestamps_must_have_timezone(cls, value: datetime | None) -> datetime | None:
        if value is not None and value.utcoffset() is None:
            msg = "İş zaman damgaları saat dilimi içermelidir."
            raise ValueError(msg)
        return value

    @classmethod
    def new(
        cls,
        *,
        kind: JobKind,
        owner_hash: str,
        payload: dict[str, JsonValue],
        payload_hash: str,
        now: datetime,
    ) -> Self:
        return cls(
            job_id=new_ulid(),
            kind=kind,
            status=JobStatus.ACCEPTED,
            owner_hash=owner_hash,
            payload=payload,
            payload_hash=payload_hash,
            created_at=now,
            updated_at=now,
        )

    def transition(
        self,
        target: JobStatus,
        *,
        now: datetime,
        failure_code: str | None = None,
    ) -> Self:
        if target not in self._TRANSITIONS[self.status]:
            msg = f"Geçersiz iş durumu geçişi: {self.status.value} -> {target.value}."
            raise ValueError(msg)

        started_at = (
            now if target is JobStatus.RUNNING and self.started_at is None else self.started_at
        )
        completed_at = now if target.is_terminal else self.completed_at
        attempt = self.attempt + 1 if target is JobStatus.RUNNING else self.attempt
        return self.model_copy(
            update={
                "status": target,
                "updated_at": now,
                "started_at": started_at,
                "completed_at": completed_at,
                "failure_code": failure_code,
                "payload": {} if target.is_terminal else self.payload,
                "lease_token": None if target is not JobStatus.RUNNING else self.lease_token,
                "lease_expires_at": (
                    None if target is not JobStatus.RUNNING else self.lease_expires_at
                ),
                "attempt": attempt,
                "version": self.version + 1,
            }
        )

    def claim(self, *, now: datetime, lease_duration: timedelta) -> Self:
        if lease_duration <= timedelta(0):
            msg = "İşçi kiralama süresi sıfırdan büyük olmalıdır."
            raise ValueError(msg)

        current = self
        if current.status is JobStatus.RETRY_WAIT:
            current = current.transition(JobStatus.QUEUED, now=now)
        if current.status is JobStatus.QUEUED:
            current = current.transition(JobStatus.RUNNING, now=now)
        elif current.status is JobStatus.RUNNING:
            if current.lease_expires_at is None or current.lease_expires_at > now:
                msg = "İş başka bir işçi tarafından yürütülüyor."
                raise ValueError(msg)
            current = current.model_copy(
                update={
                    "updated_at": now,
                    "failure_code": None,
                    "attempt": current.attempt + 1,
                    "version": current.version + 1,
                }
            )
        else:
            msg = f"{current.status.value} durumundaki iş kiralanamaz."
            raise ValueError(msg)

        return current.model_copy(
            update={
                "lease_token": new_ulid(),
                "lease_expires_at": now + lease_duration,
            }
        )

    def finish_claim(
        self,
        target: JobStatus,
        *,
        now: datetime,
        claim_token: str,
        failure_code: str | None = None,
    ) -> Self:
        if self.status is not JobStatus.RUNNING or self.lease_token != claim_token:
            msg = "İşçi kiralaması artık geçerli değil."
            raise ValueError(msg)
        return self.transition(target, now=now, failure_code=failure_code)


class OutboxRecord(ApiModel):
    event_id: str = Field(pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$")
    job_id: str = Field(pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$")
    topic: str = Field(min_length=1, max_length=96)
    event_version: int = Field(default=1, ge=1)
    payload: dict[str, JsonValue]
    traceparent: str | None = Field(default=None, max_length=128)
    created_at: datetime
    published_at: datetime | None = None


class IdempotencyRecord(ApiModel):
    key_hash: str = Field(pattern=r"^[a-f0-9]{64}$")
    payload_hash: str = Field(pattern=r"^[a-f0-9]{64}$")
    job_id: str = Field(pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$")
    created_at: datetime
