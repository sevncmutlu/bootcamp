from datetime import UTC, date, datetime

import pytest

from maki.official_data.models import PublicationState, SeriesPoint, SourceSnapshot
from maki.official_data.service import (
    DuplicatePeriodError,
    EmptySnapshotError,
    OfficialDataService,
    UnexpectedSourceShrinkError,
)

_NOW = datetime(2026, 7, 3, 12, tzinfo=UTC)


class InMemoryOfficialDataRepository:
    def __init__(self) -> None:
        self.snapshots: dict[tuple[str, str, str], SourceSnapshot] = {}
        self.published: dict[str, SourceSnapshot] = {}
        self.write_count = 0

    async def find_by_identity(
        self,
        source_name: str,
        source_version: str,
        content_sha256: str,
    ) -> SourceSnapshot | None:
        return self.snapshots.get((source_name, source_version, content_sha256))

    async def latest_published(self, source_name: str) -> SourceSnapshot | None:
        return self.published.get(source_name)

    async def publish(
        self,
        snapshot: SourceSnapshot,
        published_at: datetime,
    ) -> SourceSnapshot:
        published = snapshot.model_copy(
            update={
                "state": PublicationState.PUBLISHED,
                "published_at": published_at,
            }
        )
        key = (
            snapshot.source_name,
            snapshot.source_version,
            snapshot.content_sha256,
        )
        self.snapshots[key] = published
        self.published[snapshot.source_name] = published
        self.write_count += 1
        return published


async def test_publish_is_idempotent_for_same_source_version_and_digest() -> None:
    repository = InMemoryOfficialDataRepository()
    service = OfficialDataService(repository=repository, clock=lambda: _NOW)
    snapshot = _snapshot("a" * 64, point_count=4)

    first = await service.publish(snapshot)
    second = await service.publish(snapshot)

    assert first.snapshot_id == second.snapshot_id
    assert first.state is PublicationState.PUBLISHED
    assert repository.write_count == 1


async def test_empty_and_duplicate_period_snapshots_are_rejected() -> None:
    service = OfficialDataService(
        repository=InMemoryOfficialDataRepository(),
        clock=lambda: _NOW,
    )

    with pytest.raises(EmptySnapshotError, match="nokta"):
        await service.publish(_snapshot("b" * 64, point_count=0))

    duplicate = _snapshot("c" * 64, point_count=2)
    duplicate = duplicate.model_copy(update={"points": (duplicate.points[0],) * 2})
    with pytest.raises(DuplicatePeriodError, match="tekrarlanan"):
        await service.publish(duplicate)


async def test_more_than_half_source_shrink_preserves_previous_publication() -> None:
    repository = InMemoryOfficialDataRepository()
    service = OfficialDataService(repository=repository, clock=lambda: _NOW)
    previous = await service.publish(_snapshot("d" * 64, point_count=10))

    with pytest.raises(UnexpectedSourceShrinkError, match="yüzde 50"):
        await service.publish(
            _snapshot(
                "e" * 64,
                point_count=4,
                source_version="2026-08-03",
            )
        )

    assert await repository.latest_published("tuik") == previous
    assert repository.write_count == 1


def _snapshot(
    digest: str,
    *,
    point_count: int,
    source_version: str = "2026-07-03",
) -> SourceSnapshot:
    points = tuple(
        SeriesPoint(
            series_id="TUFE_GENEL",
            period=date(2025, index + 1, 1),
            value=str(100 + index),
            unit="index",
            release_date=date(2026, 7, 3),
            source_url="https://data.tuik.gov.tr/",
            retrieved_at=_NOW,
        )
        for index in range(point_count)
    )
    return SourceSnapshot(
        source_name="tuik",
        source_version=source_version,
        schema_version=1,
        content_sha256=digest,
        etag=None,
        points=points,
    )
