from collections import deque
from datetime import UTC, datetime, timedelta

from maki.jobs.models import JobKind, JobRecord, JobStatus
from maki.jobs.queue import JobClaim, JobClaimOutcome, JobMessage, QueueDelivery
from maki.workers.runtime import PermanentJobError, TransientJobError, WorkerRuntime

_NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)


class FakeQueue:
    def __init__(self) -> None:
        self.pending: deque[QueueDelivery] = deque()
        self.acked: list[str] = []
        self.dead: list[tuple[str, str]] = []

    async def publish(self, message: JobMessage) -> str:
        delivery_id = f"teslim-{len(self.pending) + 1}"
        self.pending.append(QueueDelivery(delivery_id=delivery_id, message=message))
        return delivery_id

    async def consume(self) -> QueueDelivery | None:
        return self.pending.popleft() if self.pending else None

    async def ack(self, delivery: QueueDelivery) -> None:
        self.acked.append(delivery.delivery_id)

    async def retry(self, delivery: QueueDelivery) -> None:
        self.acked.append(delivery.delivery_id)
        self.pending.append(
            delivery.model_copy(
                update={
                    "delivery_id": f"{delivery.delivery_id}-r",
                    "attempt": delivery.attempt + 1,
                }
            )
        )

    async def release(self, delivery: QueueDelivery) -> None:
        self.pending.append(delivery)

    async def dead_letter(self, delivery: QueueDelivery, failure_code: str) -> None:
        self.dead.append((delivery.delivery_id, failure_code))
        self.acked.append(delivery.delivery_id)


class FakeWorkerRepository:
    def __init__(self, job: JobRecord) -> None:
        self.job = job

    async def claim_for_work(self, job_id: str, now: datetime) -> JobClaim:
        assert job_id == self.job.job_id
        if self.job.status.is_terminal:
            return JobClaim(outcome=JobClaimOutcome.TERMINAL, job=self.job)
        if (
            self.job.status is JobStatus.RUNNING
            and self.job.lease_expires_at is not None
            and self.job.lease_expires_at > now
        ):
            return JobClaim(outcome=JobClaimOutcome.BUSY)
        self.job = self.job.claim(now=now, lease_duration=timedelta(minutes=5))
        return JobClaim(
            outcome=JobClaimOutcome.CLAIMED,
            job=self.job,
            claim_token=self.job.lease_token,
        )

    async def finish(
        self,
        job_id: str,
        target: JobStatus,
        now: datetime,
        claim_token: str,
        failure_code: str | None = None,
    ) -> JobRecord:
        assert job_id == self.job.job_id
        self.job = self.job.finish_claim(
            target,
            now=now,
            claim_token=claim_token,
            failure_code=failure_code,
        )
        return self.job


class CountingHandler:
    def __init__(self) -> None:
        self.calls = 0

    async def __call__(self, _job: JobRecord) -> None:
        self.calls += 1


class FlakyHandler:
    def __init__(self) -> None:
        self.calls = 0

    async def __call__(self, _job: JobRecord) -> None:
        self.calls += 1
        if self.calls == 1:
            code = "GECICI_MODEL_HATASI"
            raise TransientJobError(code)


class BrokenHandler:
    async def __call__(self, _job: JobRecord) -> None:
        code = "GECERSIZ_IS_GIRDISI"
        raise PermanentJobError(code)


async def test_worker_acknowledges_duplicate_without_second_effect() -> None:
    repository = FakeWorkerRepository(_queued_job())
    queue = FakeQueue()
    handler = CountingHandler()
    message = _message(repository.job)
    await queue.publish(message)
    await queue.publish(message)
    runtime = WorkerRuntime(
        queue=queue,
        repository=repository,
        handlers={JobKind.FORECAST: handler},
        clock=lambda: _NOW,
    )

    await runtime.run_once()
    await runtime.run_once()

    assert handler.calls == 1
    assert repository.job.status is JobStatus.SUCCEEDED
    assert len(queue.acked) == 2


async def test_transient_error_is_retried_then_succeeds() -> None:
    repository = FakeWorkerRepository(_queued_job())
    queue = FakeQueue()
    handler = FlakyHandler()
    await queue.publish(_message(repository.job))
    runtime = WorkerRuntime(
        queue=queue,
        repository=repository,
        handlers={JobKind.FORECAST: handler},
        clock=lambda: _NOW,
        max_attempts=3,
    )

    await runtime.run_once()
    await runtime.run_once()

    assert handler.calls == 2
    assert repository.job.status is JobStatus.SUCCEEDED
    assert not queue.dead


async def test_permanent_error_goes_to_dead_letter() -> None:
    repository = FakeWorkerRepository(_queued_job())
    queue = FakeQueue()
    await queue.publish(_message(repository.job))
    runtime = WorkerRuntime(
        queue=queue,
        repository=repository,
        handlers={JobKind.FORECAST: BrokenHandler()},
        clock=lambda: _NOW,
    )

    await runtime.run_once()

    assert repository.job.status is JobStatus.FAILED
    assert queue.dead[0][1] == "GECERSIZ_IS_GIRDISI"


def _queued_job() -> JobRecord:
    accepted = JobRecord.new(
        kind=JobKind.FORECAST,
        owner_hash="a" * 64,
        payload={"series_hash": "abc"},
        payload_hash="b" * 64,
        now=_NOW,
    )
    return accepted.transition(JobStatus.QUEUED, now=_NOW)


def _message(job: JobRecord) -> JobMessage:
    return JobMessage(
        event_id="01K0A1B2C3D4E5F6G7H8J9K0MN",
        job_id=job.job_id,
        kind=job.kind,
        version=1,
    )
