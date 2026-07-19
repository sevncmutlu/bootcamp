from collections.abc import Callable
from datetime import datetime
from typing import Protocol

from maki.jobs.models import JobKind, OutboxRecord
from maki.jobs.queue import JobMessage

_MAX_BATCH_SIZE = 1_000


class OutboxRepository(Protocol):
    async def list_unpublished(self, limit: int) -> tuple[OutboxRecord, ...]: ...

    async def mark_published(self, event_id: str, published_at: datetime) -> bool: ...


class JobPublisher(Protocol):
    async def publish(self, message: JobMessage) -> str: ...


class DispatcherTelemetry(Protocol):
    def observe(
        self,
        name: str,
        value: float,
        attributes: dict[str, object],
    ) -> None: ...


class OutboxDispatcher:
    def __init__(
        self,
        *,
        repository: OutboxRepository,
        queue: JobPublisher,
        clock: Callable[[], datetime],
        batch_size: int = 100,
        telemetry: DispatcherTelemetry | None = None,
    ) -> None:
        if not 1 <= batch_size <= _MAX_BATCH_SIZE:
            msg = "Outbox parti büyüklüğü 1 ile 1000 arasında olmalıdır."
            raise ValueError(msg)
        self._repository = repository
        self._queue = queue
        self._clock = clock
        self._batch_size = batch_size
        self._telemetry = telemetry

    async def run_once(self) -> int:
        records = await self._repository.list_unpublished(self._batch_size)
        published = 0
        for record in records:
            if self._telemetry is not None:
                age_ms = max(
                    (self._clock() - record.created_at).total_seconds() * 1_000,
                    0,
                )
                self._telemetry.observe(
                    "maki.queue.age_ms",
                    age_ms,
                    {"queue.name": "maki:jobs"},
                )
            message = JobMessage(
                event_id=record.event_id,
                job_id=record.job_id,
                kind=JobKind(record.topic.removeprefix("jobs.")),
                version=record.event_version,
                traceparent=record.traceparent,
            )
            await self._queue.publish(message)
            if await self._repository.mark_published(record.event_id, self._clock()):
                published += 1
        return published
