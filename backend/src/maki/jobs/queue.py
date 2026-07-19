from datetime import datetime
from enum import StrEnum
from typing import Protocol

from pydantic import Field, model_validator

from maki.common.models import ApiModel
from maki.jobs.models import JobKind, JobRecord, JobStatus


class JobMessage(ApiModel):
    event_id: str = Field(pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$")
    job_id: str = Field(pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$")
    kind: JobKind
    version: int = Field(ge=1)
    traceparent: str | None = Field(default=None, max_length=128)


class QueueDelivery(ApiModel):
    delivery_id: str = Field(min_length=1, max_length=128)
    message: JobMessage
    attempt: int = Field(default=0, ge=0)


class JobClaimOutcome(StrEnum):
    CLAIMED = "claimed"
    TERMINAL = "terminal"
    BUSY = "busy"
    MISSING = "missing"


class JobClaim(ApiModel):
    outcome: JobClaimOutcome
    job: JobRecord | None = None
    claim_token: str | None = Field(
        default=None,
        pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$",
    )

    @model_validator(mode="after")
    def validate_claim(self) -> "JobClaim":
        if self.outcome is JobClaimOutcome.CLAIMED and (
            self.job is None or self.claim_token is None
        ):
            msg = "Alınan iş sonucu iş kaydı ve kiralama anahtarı içermelidir."
            raise ValueError(msg)
        return self


class JobQueue(Protocol):
    async def publish(self, message: JobMessage) -> str: ...

    async def consume(self) -> QueueDelivery | None: ...

    async def ack(self, delivery: QueueDelivery) -> None: ...

    async def retry(self, delivery: QueueDelivery) -> None: ...

    async def release(self, delivery: QueueDelivery) -> None: ...

    async def dead_letter(self, delivery: QueueDelivery, failure_code: str) -> None: ...


class WorkerJobRepository(Protocol):
    async def claim_for_work(self, job_id: str, now: datetime) -> JobClaim: ...

    async def finish(
        self,
        job_id: str,
        target: JobStatus,
        now: datetime,
        claim_token: str,
        failure_code: str | None = None,
    ) -> JobRecord: ...
