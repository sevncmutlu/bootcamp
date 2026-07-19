from datetime import datetime

from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from maki.infrastructure.subject_lock import lock_subject
from maki.infrastructure.tables import LeaderboardContributionTable


class SqlAlchemyLeaderboardRepository:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
    ) -> None:
        self._session_factory = session_factory

    async def record_and_list(
        self,
        *,
        cohort_hash: str,
        subject_hash: str,
        score_basis_points: int,
        now: datetime,
        expires_at: datetime,
    ) -> tuple[int, ...]:
        statement = (
            insert(LeaderboardContributionTable)
            .values(
                cohort_hash=cohort_hash,
                subject_hash=subject_hash,
                contribution_day=now.date(),
                score_basis_points=score_basis_points,
                created_at=now,
                expires_at=expires_at,
            )
            .on_conflict_do_update(
                index_elements=[
                    LeaderboardContributionTable.cohort_hash,
                    LeaderboardContributionTable.subject_hash,
                    LeaderboardContributionTable.contribution_day,
                ],
                set_={
                    "score_basis_points": score_basis_points,
                    "expires_at": expires_at,
                },
            )
        )
        async with self._session_factory() as session, session.begin():
            await lock_subject(session, subject_hash)
            await session.execute(
                delete(LeaderboardContributionTable).where(
                    LeaderboardContributionTable.expires_at <= now,
                )
            )
            await session.execute(statement)
            scores = await session.scalars(
                select(LeaderboardContributionTable.score_basis_points)
                .where(
                    LeaderboardContributionTable.cohort_hash == cohort_hash,
                    LeaderboardContributionTable.subject_hash != subject_hash,
                    LeaderboardContributionTable.expires_at > now,
                )
                .order_by(
                    LeaderboardContributionTable.score_basis_points,
                    LeaderboardContributionTable.subject_hash,
                )
            )
            return tuple(scores)
