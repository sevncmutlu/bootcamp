from __future__ import annotations

import re
from typing import TYPE_CHECKING, Protocol

from sqlalchemy import func, or_, select

from maki.coach.models import SourceCard
from maki.infrastructure.tables import (
    SeriesPointTable,
    SourcePublicationTable,
    SourceSnapshotTable,
)

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

_INSTITUTIONS = {
    "tuik": "TÜİK",
    "tcmb_evds": "TCMB",
}
_SERIES_ALIASES = {
    "TUFE_GENEL": frozenset(
        {
            "tüfe",
            "tuketici",
            "tüketici",
            "enflasyon",
            "fiyat",
            "endeksi",
        }
    ),
    "TP.FG.J0": frozenset({"politika", "faiz", "oranı", "orani"}),
}
_TOKEN = re.compile(r"[0-9a-zçğıöşü.]+")


class SourceCardRepository(Protocol):
    async def search_published(
        self,
        query: str,
        limit: int,
    ) -> tuple[SourceCard, ...]: ...


class SqlAlchemySourceCardRepository:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
    ) -> None:
        self._session_factory = session_factory

    async def search_published(
        self,
        query: str,
        limit: int,
    ) -> tuple[SourceCard, ...]:
        series_ids = _matching_series_ids(query)
        searchable = func.concat(
            SeriesPointTable.series_id,
            " ",
            SeriesPointTable.unit,
        )
        text_match = func.to_tsvector("simple", searchable).op("@@")(
            func.plainto_tsquery("simple", query)
        )
        condition = (
            or_(text_match, SeriesPointTable.series_id.in_(series_ids))
            if series_ids
            else text_match
        )
        statement = (
            select(SeriesPointTable, SourceSnapshotTable)
            .join(
                SourceSnapshotTable,
                SourceSnapshotTable.snapshot_id == SeriesPointTable.snapshot_id,
            )
            .join(
                SourcePublicationTable,
                SourcePublicationTable.snapshot_id == SourceSnapshotTable.snapshot_id,
            )
            .where(condition)
            .order_by(
                SeriesPointTable.release_date.desc(),
                SeriesPointTable.period.desc(),
                SeriesPointTable.series_id,
            )
            .limit(limit)
        )
        async with self._session_factory() as session:
            rows = (await session.execute(statement)).all()
        return tuple(
            SourceCard.model_validate(
                {
                    "snapshot_id": snapshot.snapshot_id,
                    "snapshot_digest": snapshot.content_sha256,
                    "institution": _INSTITUTIONS.get(
                        snapshot.source_name,
                        snapshot.source_name.upper(),
                    ),
                    "series_id": point.series_id,
                    "period": point.period,
                    "value": point.value,
                    "unit": point.unit,
                    "release_date": point.release_date,
                    "source_url": point.source_url,
                    "retrieved_at": point.retrieved_at,
                }
            )
            for point, snapshot in rows
        )


def _matching_series_ids(query: str) -> tuple[str, ...]:
    tokens = frozenset(_TOKEN.findall(query.casefold()))
    return tuple(series_id for series_id, aliases in _SERIES_ALIASES.items() if tokens & aliases)
