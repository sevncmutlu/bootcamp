import hashlib
from datetime import datetime
from enum import StrEnum
from typing import Protocol

from pydantic import Field

from maki.common.models import ApiModel
from maki.jobs.errors import JobNotFoundError
from maki.jobs.models import JobKind, JobRecord, JobStatus
from maki.jobs.results import JobResult


class JobReader(Protocol):
    async def get_for_owner(
        self,
        job_id: str,
        owner_hash: str,
    ) -> JobRecord | None: ...


class JobResultReader(Protocol):
    async def get(
        self,
        job_id: str,
        kind: JobKind,
    ) -> JobResult | None: ...


class ResultState(StrEnum):
    PENDING = "pending"
    READY = "ready"
    EXPIRED = "expired"
    FAILED = "failed"


class JobStatusView(ApiModel):
    job_id: str = Field(pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$")
    kind: JobKind
    status: JobStatus
    result_state: ResultState
    result: JobResult | None = None
    failure_code: str | None = Field(default=None, max_length=64)
    updated_at: datetime


class JobQueryService:
    def __init__(
        self,
        *,
        jobs: JobReader,
        results: JobResultReader,
    ) -> None:
        self._jobs = jobs
        self._results = results

    async def get(self, *, job_id: str, owner_id: str) -> JobStatusView:
        job = await self._jobs.get_for_owner(
            job_id,
            self.owner_hash(owner_id),
        )
        if job is None:
            raise JobNotFoundError
        result = (
            await self._results.get(job.job_id, job.kind)
            if job.status is JobStatus.SUCCEEDED
            else None
        )
        return JobStatusView(
            job_id=job.job_id,
            kind=job.kind,
            status=job.status,
            result_state=_result_state(job.status, result),
            result=result,
            failure_code=job.failure_code,
            updated_at=job.updated_at,
        )

    @staticmethod
    def owner_hash(owner_id: str) -> str:
        return hashlib.sha256(owner_id.encode()).hexdigest()


def _result_state(
    status: JobStatus,
    result: JobResult | None,
) -> ResultState:
    if status is JobStatus.FAILED:
        return ResultState.FAILED
    if status is JobStatus.SUCCEEDED:
        return ResultState.READY if result is not None else ResultState.EXPIRED
    return ResultState.PENDING
