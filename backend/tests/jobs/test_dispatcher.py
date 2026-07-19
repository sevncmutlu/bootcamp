from datetime import UTC, datetime, timedelta

import pytest

from maki.jobs.models import JobKind, OutboxRecord
from maki.jobs.queue import JobMessage
from maki.workers.dispatcher import OutboxDispatcher

_NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)


class FakeOutboxRepository:
    def __init__(self, records: tuple[OutboxRecord, ...]) -> None:
        self.records = records
        self.marked: list[str] = []

    async def list_unpublished(self, limit: int) -> tuple[OutboxRecord, ...]:
        return self.records[:limit]

    async def mark_published(self, event_id: str, published_at: datetime) -> bool:
        assert published_at == _NOW
        self.marked.append(event_id)
        return True


class RecordingQueue:
    def __init__(self, *, fail: bool = False) -> None:
        self.messages: list[JobMessage] = []
        self.fail = fail

    async def publish(self, message: JobMessage) -> str:
        if self.fail:
            msg = "Redis kullanılamıyor."
            raise ConnectionError(msg)
        self.messages.append(message)
        return "1-0"


class RecordingTelemetry:
    def __init__(self) -> None:
        self.values: list[tuple[str, float, dict[str, object]]] = []

    def observe(
        self,
        name: str,
        value: float,
        attributes: dict[str, object],
    ) -> None:
        self.values.append((name, value, attributes))


async def test_dispatcher_publishes_only_safe_job_metadata() -> None:
    record = _outbox()
    repository = FakeOutboxRepository((record,))
    queue = RecordingQueue()
    dispatcher = OutboxDispatcher(repository=repository, queue=queue, clock=lambda: _NOW)

    count = await dispatcher.run_once()

    assert count == 1
    assert repository.marked == [record.event_id]
    assert queue.messages[0].model_dump(mode="json") == {
        "event_id": record.event_id,
        "job_id": record.job_id,
        "kind": "forecast",
        "version": 1,
        "traceparent": None,
    }


async def test_dispatcher_does_not_mark_failed_publish() -> None:
    repository = FakeOutboxRepository((_outbox(),))
    dispatcher = OutboxDispatcher(
        repository=repository,
        queue=RecordingQueue(fail=True),
        clock=lambda: _NOW,
    )

    with pytest.raises(ConnectionError, match="Redis kullanılamıyor"):
        await dispatcher.run_once()

    assert not repository.marked


async def test_dispatcher_records_oldest_queue_age_without_payload() -> None:
    record = _outbox().model_copy(
        update={"created_at": _NOW - timedelta(seconds=5)},
    )
    telemetry = RecordingTelemetry()
    dispatcher = OutboxDispatcher(
        repository=FakeOutboxRepository((record,)),
        queue=RecordingQueue(),
        clock=lambda: _NOW,
        telemetry=telemetry,
    )

    await dispatcher.run_once()

    assert telemetry.values == [
        (
            "maki.queue.age_ms",
            5_000,
            {"queue.name": "maki:jobs"},
        )
    ]


def _outbox() -> OutboxRecord:
    return OutboxRecord(
        event_id="01K0A1B2C3D4E5F6G7H8J9K0MN",
        job_id="01K0N1P2Q3R4S5T6V7W8X9Y0ZA",
        topic="jobs.forecast",
        payload={
            "job_id": "01K0N1P2Q3R4S5T6V7W8X9Y0ZA",
            "kind": JobKind.FORECAST.value,
            "version": 1,
        },
        created_at=_NOW,
    )
