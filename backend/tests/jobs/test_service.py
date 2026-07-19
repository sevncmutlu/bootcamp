import asyncio
from datetime import UTC, datetime, timedelta

import pytest

from maki.jobs.errors import IdempotencyConflictError, UnsafeJobPayloadError
from maki.jobs.models import (
    IdempotencyRecord,
    JobKind,
    JobRecord,
    JobStatus,
    OutboxRecord,
)
from maki.jobs.service import JobService

_NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)


class InMemoryJobRepository:
    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        self.jobs: dict[str, JobRecord] = {}
        self.keys: dict[str, IdempotencyRecord] = {}
        self.outbox: dict[str, OutboxRecord] = {}

    async def create_with_outbox(
        self,
        job: JobRecord,
        outbox: OutboxRecord,
        idempotency: IdempotencyRecord,
    ) -> JobRecord:
        async with self._lock:
            existing_key = self.keys.get(idempotency.key_hash)
            if existing_key is not None:
                if existing_key.payload_hash != idempotency.payload_hash:
                    raise IdempotencyConflictError
                return self.jobs[existing_key.job_id]

            self.jobs[job.job_id] = job
            self.keys[idempotency.key_hash] = idempotency
            self.outbox[outbox.event_id] = outbox
            return job

    async def outbox_count(self) -> int:
        return len(self.outbox)


def fixed_clock() -> datetime:
    return _NOW


async def test_accept_returns_same_job_for_same_key() -> None:
    repository = InMemoryJobRepository()
    service = JobService(repository=repository, clock=fixed_clock)

    first = await service.accept(
        JobKind.FORECAST,
        {"series_hash": "abc"},
        "device-1",
        "same-key",
    )
    second = await service.accept(
        JobKind.FORECAST,
        {"series_hash": "abc"},
        "device-1",
        "same-key",
    )

    assert first.job_id == second.job_id
    assert await repository.outbox_count() == 1
    assert first.owner_hash != "device-1"


async def test_same_key_with_different_payload_is_rejected() -> None:
    repository = InMemoryJobRepository()
    service = JobService(repository=repository, clock=fixed_clock)
    await service.accept(JobKind.FORECAST, {"series_hash": "abc"}, "device-1", "same-key")

    with pytest.raises(IdempotencyConflictError, match="farklı bir istek"):
        await service.accept(
            JobKind.FORECAST,
            {"series_hash": "different"},
            "device-1",
            "same-key",
        )


async def test_concurrent_accept_creates_one_job_and_one_event() -> None:
    repository = InMemoryJobRepository()
    service = JobService(repository=repository, clock=fixed_clock)

    jobs = await asyncio.gather(
        *(
            service.accept(JobKind.RECEIPT, {"object_ref": "tmp-1"}, "device-1", "race-key")
            for _ in range(20)
        )
    )

    assert len({job.job_id for job in jobs}) == 1
    assert await repository.outbox_count() == 1


async def test_service_rechecks_privacy_policy() -> None:
    service = JobService(repository=InMemoryJobRepository(), clock=fixed_clock)

    with pytest.raises(UnsafeJobPayloadError, match="gizlilik politikasına"):
        await service.accept(
            JobKind.FORECAST,
            {"amount": 5_000},
            "device-1",
            "private-key",
        )


def test_job_state_machine_rejects_invalid_transition() -> None:
    job = JobRecord.new(
        kind=JobKind.FORECAST,
        owner_hash="a" * 64,
        payload={"series_hash": "abc"},
        payload_hash="b" * 64,
        now=_NOW,
    )

    with pytest.raises(ValueError, match="Geçersiz iş durumu geçişi"):
        job.transition(JobStatus.SUCCEEDED, now=_NOW)


def test_job_state_machine_sets_terminal_timestamp() -> None:
    accepted = JobRecord.new(
        kind=JobKind.FORECAST,
        owner_hash="a" * 64,
        payload={"series_hash": "abc"},
        payload_hash="b" * 64,
        now=_NOW,
    )

    queued = accepted.transition(JobStatus.QUEUED, now=_NOW)
    running = queued.transition(JobStatus.RUNNING, now=_NOW)
    succeeded = running.transition(JobStatus.SUCCEEDED, now=_NOW)

    assert running.started_at == _NOW
    assert succeeded.completed_at == _NOW
    assert succeeded.version == 3
    assert succeeded.payload == {}


def test_expired_worker_lease_can_be_reclaimed_safely() -> None:
    accepted = JobRecord.new(
        kind=JobKind.FORECAST,
        owner_hash="a" * 64,
        payload={"series_hash": "abc"},
        payload_hash="b" * 64,
        now=_NOW,
    )
    queued = accepted.transition(JobStatus.QUEUED, now=_NOW)
    first = queued.claim(now=_NOW, lease_duration=timedelta(seconds=1))
    later = _NOW + timedelta(seconds=2)

    second = first.claim(now=later, lease_duration=timedelta(seconds=1))

    assert second.lease_token != first.lease_token
    assert second.attempt == 2
    with pytest.raises(ValueError, match="İşçi kiralaması artık geçerli değil"):
        second.finish_claim(
            JobStatus.SUCCEEDED,
            now=later,
            claim_token=first.lease_token or "",
        )
