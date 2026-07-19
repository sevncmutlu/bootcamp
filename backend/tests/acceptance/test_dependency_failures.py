import asyncio
from collections import deque
from datetime import UTC, datetime, timedelta

import httpx
import pytest
from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container, ReadinessProbe
from maki.common.config import Environment, Settings
from maki.jobs.models import JobKind, JobRecord, JobStatus
from maki.jobs.queue import JobClaim, JobClaimOutcome, JobMessage, QueueDelivery
from maki.official_data.clients.base import OfficialHttpClient, ProviderHttpError
from maki.workers.runtime import WorkerRuntime

_NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)


class BrokenProbe:
    name = "postgresql"

    async def is_ready(self) -> bool:
        msg = "postgres-private-host:5432"
        raise ConnectionError(msg)


class SlowProbe:
    name = "redis"

    async def is_ready(self) -> bool:
        await asyncio.sleep(1)
        return True


class MemoryQueue:
    def __init__(self, delivery: QueueDelivery) -> None:
        self.pending = deque((delivery,))
        self.dead: list[tuple[str, str]] = []

    async def publish(self, _message: JobMessage) -> str:
        return "teslim-1"

    async def consume(self) -> QueueDelivery | None:
        return self.pending.popleft() if self.pending else None

    async def ack(self, _delivery: QueueDelivery) -> None:
        return

    async def retry(self, delivery: QueueDelivery) -> None:
        self.pending.append(delivery)

    async def release(self, delivery: QueueDelivery) -> None:
        self.pending.append(delivery)

    async def dead_letter(
        self,
        delivery: QueueDelivery,
        failure_code: str,
    ) -> None:
        self.dead.append((delivery.delivery_id, failure_code))


class MemoryWorkerRepository:
    def __init__(self, job: JobRecord) -> None:
        self.job = job

    async def claim_for_work(self, job_id: str, now: datetime) -> JobClaim:
        assert job_id == self.job.job_id
        self.job = self.job.claim(now=now, lease_duration=timedelta(seconds=1))
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


class RecordingTelemetry:
    def __init__(self) -> None:
        self.counters: list[tuple[str, dict[str, object]]] = []
        self.histograms: list[tuple[str, float, dict[str, object]]] = []

    def increment(
        self,
        name: str,
        attributes: dict[str, object],
        *,
        amount: int = 1,
    ) -> None:
        assert amount == 1
        self.counters.append((name, attributes))

    def observe(
        self,
        name: str,
        value: float,
        attributes: dict[str, object],
    ) -> None:
        self.histograms.append((name, value, attributes))


async def test_readiness_fails_without_leaking_dependency_detail() -> None:
    probes: tuple[ReadinessProbe, ...] = (BrokenProbe(), SlowProbe())
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(readiness_probes=probes),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/health/ready")

    assert response.status_code == 503
    assert response.json()["bagimliliklar"] == [
        {"ad": "postgresql", "durum": "hazir_degil"},
        {"ad": "redis", "durum": "zaman_asimi"},
    ]
    assert "postgres-private-host" not in response.text


async def test_slow_provider_is_mapped_to_retryable_safe_error() -> None:
    async def timeout_handler(_request: httpx.Request) -> httpx.Response:
        msg = "provider-private-token"
        raise httpx.ReadTimeout(msg)

    client = httpx.AsyncClient(transport=httpx.MockTransport(timeout_handler))
    provider = OfficialHttpClient(
        client,
        "https://veri.example/",
    )

    async with client:
        with pytest.raises(ProviderHttpError) as captured:
            await provider.get_json("/seri")

    assert captured.value.retryable is True
    assert "provider-private-token" not in str(captured.value)


def test_expired_worker_lease_is_reclaimed_without_stale_completion() -> None:
    queued = _queued_job()
    first = queued.claim(now=_NOW, lease_duration=timedelta(seconds=1))
    later = _NOW + timedelta(seconds=2)
    second = first.claim(now=later, lease_duration=timedelta(seconds=1))

    assert first.lease_token != second.lease_token
    with pytest.raises(ValueError, match="kiralaması artık geçerli değil"):
        second.finish_claim(
            JobStatus.SUCCEEDED,
            now=later,
            claim_token=first.lease_token or "",
        )


async def test_message_without_handler_fails_and_moves_to_dead_letter() -> None:
    repository = MemoryWorkerRepository(_queued_job())
    delivery = QueueDelivery(
        delivery_id="teslim-1",
        message=JobMessage(
            event_id="01K0A1B2C3D4E5F6G7H8J9K0MN",
            job_id=repository.job.job_id,
            kind=JobKind.FORECAST,
            version=1,
        ),
    )
    queue = MemoryQueue(delivery)
    telemetry = RecordingTelemetry()
    runtime = WorkerRuntime(
        queue=queue,
        repository=repository,
        handlers={},
        clock=lambda: _NOW,
        telemetry=telemetry,
    )

    assert await runtime.run_once() is True
    assert repository.job.status is JobStatus.FAILED
    assert repository.job.failure_code == "ISLEYICI_BULUNAMADI"
    assert queue.dead == [("teslim-1", "ISLEYICI_BULUNAMADI")]
    assert telemetry.counters == [
        (
            "maki.jobs.completed",
            {
                "error.code": "ISLEYICI_BULUNAMADI",
                "job.kind": "forecast",
                "job.outcome": "failed",
            },
        )
    ]
    assert telemetry.histograms[0][0] == "maki.job.duration_ms"


def _queued_job() -> JobRecord:
    accepted = JobRecord.new(
        kind=JobKind.FORECAST,
        owner_hash="a" * 64,
        payload={"series_hash": "abc"},
        payload_hash="b" * 64,
        now=_NOW,
    )
    return accepted.transition(JobStatus.QUEUED, now=_NOW)
