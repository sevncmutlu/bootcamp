from datetime import UTC, datetime, timedelta

from maki.privacy.retention import (
    RetentionDataClass,
    RetentionPolicy,
)
from maki.workers.retention import RetentionWorker

NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)


class FakeRetentionBackend:
    def __init__(self) -> None:
        self.calls: list[tuple[RetentionDataClass, datetime, int]] = []
        self._counts = {
            RetentionDataClass.IDEMPOTENCY: [2, 1],
            RetentionDataClass.JOB_METADATA: [0],
            RetentionDataClass.OCR_RESULT: [0],
            RetentionDataClass.TELEMETRY: [0],
        }

    async def purge_before(
        self,
        *,
        data_class: RetentionDataClass,
        cutoff: datetime,
        batch_size: int,
    ) -> int:
        self.calls.append((data_class, cutoff, batch_size))
        return self._counts[data_class].pop(0)


def test_retention_boundaries_are_explicit_to_the_second() -> None:
    policy = RetentionPolicy()

    expected = {
        RetentionDataClass.IDEMPOTENCY: timedelta(hours=24),
        RetentionDataClass.JOB_METADATA: timedelta(days=7),
        RetentionDataClass.OCR_RESULT: timedelta(minutes=10),
        RetentionDataClass.TELEMETRY: timedelta(days=14),
    }
    for data_class, duration in expected.items():
        assert policy.is_expired(
            data_class=data_class,
            recorded_at=NOW - duration - timedelta(seconds=1),
            now=NOW,
        )
        assert not policy.is_expired(
            data_class=data_class,
            recorded_at=NOW - duration + timedelta(seconds=1),
            now=NOW,
        )


async def test_retention_worker_batches_and_emits_only_low_cardinality_counts() -> None:
    backend = FakeRetentionBackend()
    metrics: list[tuple[RetentionDataClass, int]] = []
    worker = RetentionWorker(
        backend=backend,
        policy=RetentionPolicy(),
        clock=lambda: NOW,
        batch_size=2,
        on_purge=lambda data_class, count: metrics.append((data_class, count)),
    )

    result = await worker.run()

    assert result.deleted[RetentionDataClass.IDEMPOTENCY] == 3
    assert len(backend.calls) == 5
    assert all(call[2] == 2 for call in backend.calls)
    assert metrics == [(RetentionDataClass.IDEMPOTENCY, 3)]
