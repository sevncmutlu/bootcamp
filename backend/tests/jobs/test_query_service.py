from datetime import UTC, datetime

import pytest

from maki.jobs.errors import JobNotFoundError
from maki.jobs.models import JobKind, JobRecord, JobStatus
from maki.jobs.query import JobQueryService, ResultState
from maki.jobs.results import CoachJobResult

NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)


class MemoryReader:
    def __init__(self, job: JobRecord) -> None:
        self.job = job

    async def get_for_owner(
        self,
        job_id: str,
        owner_hash: str,
    ) -> JobRecord | None:
        if job_id == self.job.job_id and owner_hash == self.job.owner_hash:
            return self.job
        return None


class MemoryResults:
    def __init__(self, result: CoachJobResult | None) -> None:
        self.result = result
        self.calls = 0

    async def get(
        self,
        job_id: str,
        kind: JobKind,
    ) -> CoachJobResult | None:
        del job_id, kind
        self.calls += 1
        return self.result


async def test_job_query_hides_jobs_owned_by_another_subject() -> None:
    job = _job(status=JobStatus.ACCEPTED)
    service = JobQueryService(
        jobs=MemoryReader(job),
        results=MemoryResults(None),
    )

    with pytest.raises(JobNotFoundError):
        await service.get(job_id=job.job_id, owner_id="baska-cihaz")


async def test_succeeded_job_returns_typed_result() -> None:
    job = _job(status=JobStatus.SUCCEEDED)
    result = CoachJobResult.model_validate_json(
        """
        {
          "kind": "coach",
          "schema_version": 1,
          "answer": {
            "answer": null,
            "safety": "insufficient_sources",
            "sources": []
          }
        }
        """
    )
    service = JobQueryService(
        jobs=MemoryReader(job),
        results=MemoryResults(result),
    )

    view = await service.get(job_id=job.job_id, owner_id="cihaz-1")

    assert view.result_state is ResultState.READY
    assert view.result == result


def _job(*, status: JobStatus) -> JobRecord:
    accepted = JobRecord.new(
        kind=JobKind.COACH,
        owner_hash=JobQueryService.owner_hash("cihaz-1"),
        payload={"question": "x"},
        payload_hash="b" * 64,
        now=NOW,
    )
    if status is JobStatus.ACCEPTED:
        return accepted
    queued = accepted.transition(JobStatus.QUEUED, now=NOW)
    running = queued.transition(JobStatus.RUNNING, now=NOW)
    return running.transition(status, now=NOW)
