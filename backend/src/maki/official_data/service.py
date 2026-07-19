from collections.abc import Callable
from datetime import datetime

from maki.official_data.models import SourceSnapshot
from maki.official_data.ports import OfficialDataRepository


class OfficialDataError(Exception):
    """Resmî veri yayınlama hatası."""


class EmptySnapshotError(OfficialDataError):
    def __init__(self) -> None:
        super().__init__("Resmî veri snapshotı en az bir nokta taşımalıdır.")


class DuplicatePeriodError(OfficialDataError):
    def __init__(self) -> None:
        super().__init__("Resmî veri snapshotında tekrarlanan seri dönemi var.")


class UnexpectedSourceShrinkError(OfficialDataError):
    def __init__(self) -> None:
        super().__init__("Resmî veri nokta sayısı önceki yayına göre yüzde 50'den fazla azaldı.")


class OfficialDataService:
    def __init__(
        self,
        repository: OfficialDataRepository,
        clock: Callable[[], datetime],
    ) -> None:
        self._repository = repository
        self._clock = clock

    async def publish(self, snapshot: SourceSnapshot) -> SourceSnapshot:
        existing = await self._repository.find_by_identity(
            snapshot.source_name,
            snapshot.source_version,
            snapshot.content_sha256,
        )
        if existing is not None:
            return existing

        self._validate_snapshot(snapshot)
        previous = await self._repository.latest_published(snapshot.source_name)
        if previous is not None and len(snapshot.points) * 2 < len(previous.points):
            raise UnexpectedSourceShrinkError
        return await self._repository.publish(snapshot, self._clock())

    @staticmethod
    def _validate_snapshot(snapshot: SourceSnapshot) -> None:
        if not snapshot.points:
            raise EmptySnapshotError
        periods = {(point.series_id, point.period) for point in snapshot.points}
        if len(periods) != len(snapshot.points):
            raise DuplicatePeriodError
