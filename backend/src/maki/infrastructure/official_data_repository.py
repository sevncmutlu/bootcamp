from datetime import datetime

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from maki.infrastructure.tables import (
    SeriesPointTable,
    SourcePublicationTable,
    SourceSnapshotTable,
)
from maki.official_data.models import (
    PublicationState,
    SeriesPoint,
    SourceSnapshot,
)
from maki.official_data.service import UnexpectedSourceShrinkError


class SqlAlchemyOfficialDataRepository:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
    ) -> None:
        self._session_factory = session_factory

    async def find_by_identity(
        self,
        source_name: str,
        source_version: str,
        content_sha256: str,
    ) -> SourceSnapshot | None:
        async with self._session_factory() as session:
            row = await session.scalar(
                select(SourceSnapshotTable).where(
                    SourceSnapshotTable.source_name == source_name,
                    SourceSnapshotTable.source_version == source_version,
                    SourceSnapshotTable.content_sha256 == content_sha256,
                )
            )
            if row is None:
                return None
            return await self._to_domain(session, row)

    async def latest_published(self, source_name: str) -> SourceSnapshot | None:
        async with self._session_factory() as session:
            row = await session.scalar(
                select(SourceSnapshotTable)
                .join(
                    SourcePublicationTable,
                    SourcePublicationTable.snapshot_id == SourceSnapshotTable.snapshot_id,
                )
                .where(SourcePublicationTable.source_name == source_name)
            )
            if row is None:
                return None
            return await self._to_domain(session, row)

    async def publish(
        self,
        snapshot: SourceSnapshot,
        published_at: datetime,
    ) -> SourceSnapshot:
        try:
            return await self._publish_once(snapshot, published_at)
        except IntegrityError:
            existing = await self.find_by_identity(
                snapshot.source_name,
                snapshot.source_version,
                snapshot.content_sha256,
            )
            if existing is not None:
                return existing
            return await self._publish_once(snapshot, published_at)

    async def _publish_once(
        self,
        snapshot: SourceSnapshot,
        published_at: datetime,
    ) -> SourceSnapshot:
        async with self._session_factory() as session, session.begin():
            existing = await session.scalar(
                select(SourceSnapshotTable)
                .where(
                    SourceSnapshotTable.source_name == snapshot.source_name,
                    SourceSnapshotTable.source_version == snapshot.source_version,
                    SourceSnapshotTable.content_sha256 == snapshot.content_sha256,
                )
                .with_for_update()
            )
            if existing is not None:
                return await self._to_domain(session, existing)

            publication = await session.scalar(
                select(SourcePublicationTable)
                .where(SourcePublicationTable.source_name == snapshot.source_name)
                .with_for_update()
            )
            if publication is not None:
                previous = await session.get(
                    SourceSnapshotTable,
                    publication.snapshot_id,
                )
                if previous is None:
                    msg = "Kaynak yayın işaretçisi geçerli bir snapshota bağlı değil."
                    raise RuntimeError(msg)
                if len(snapshot.points) * 2 < previous.point_count:
                    raise UnexpectedSourceShrinkError

            row = SourceSnapshotTable(
                snapshot_id=snapshot.snapshot_id,
                source_name=snapshot.source_name,
                source_version=snapshot.source_version,
                schema_version=snapshot.schema_version,
                content_sha256=snapshot.content_sha256,
                etag=snapshot.etag,
                state=PublicationState.STAGED.value,
                point_count=len(snapshot.points),
                staged_at=published_at,
                published_at=None,
            )
            session.add(row)
            await session.flush()
            session.add_all(
                [
                    SeriesPointTable(
                        snapshot_id=snapshot.snapshot_id,
                        series_id=point.series_id,
                        period=point.period,
                        value=point.value,
                        unit=point.unit,
                        frequency=point.frequency,
                        release_date=point.release_date,
                        source_url=str(point.source_url),
                        retrieved_at=point.retrieved_at,
                    )
                    for point in snapshot.points
                ]
            )
            await session.flush()
            row.state = PublicationState.PUBLISHED.value
            row.published_at = published_at
            if publication is None:
                session.add(
                    SourcePublicationTable(
                        source_name=snapshot.source_name,
                        snapshot_id=snapshot.snapshot_id,
                        published_at=published_at,
                    )
                )
            else:
                publication.snapshot_id = snapshot.snapshot_id
                publication.published_at = published_at

            return self._published_copy(snapshot, published_at)

    @staticmethod
    async def _to_domain(
        session: AsyncSession,
        row: SourceSnapshotTable,
    ) -> SourceSnapshot:
        points = (
            await session.scalars(
                select(SeriesPointTable)
                .where(SeriesPointTable.snapshot_id == row.snapshot_id)
                .order_by(SeriesPointTable.series_id, SeriesPointTable.period)
            )
        ).all()
        return SourceSnapshot(
            snapshot_id=row.snapshot_id,
            source_name=row.source_name,
            source_version=row.source_version,
            schema_version=row.schema_version,
            content_sha256=row.content_sha256,
            etag=row.etag,
            state=PublicationState(row.state),
            published_at=row.published_at,
            points=tuple(
                SeriesPoint.model_validate(
                    {
                        "series_id": point.series_id,
                        "period": point.period,
                        "value": point.value,
                        "unit": point.unit,
                        "frequency": point.frequency,
                        "release_date": point.release_date,
                        "source_url": point.source_url,
                        "retrieved_at": point.retrieved_at,
                    }
                )
                for point in points
            ),
        )

    @staticmethod
    def _published_copy(
        snapshot: SourceSnapshot,
        published_at: datetime,
    ) -> SourceSnapshot:
        data = snapshot.model_dump(mode="python")
        data.update(
            {
                "state": PublicationState.PUBLISHED,
                "published_at": published_at,
            }
        )
        return SourceSnapshot.model_validate(data)
