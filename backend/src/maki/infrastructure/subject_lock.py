from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

_UNSIGNED_64_LIMIT = 2**64
_SIGNED_64_LIMIT = 2**63


def subject_lock_key(subject_hash: str) -> int:
    unsigned = int(subject_hash[:16], 16)
    if unsigned >= _SIGNED_64_LIMIT:
        return unsigned - _UNSIGNED_64_LIMIT
    return unsigned


async def lock_subject(session: AsyncSession, subject_hash: str) -> None:
    await session.execute(
        text("SELECT pg_advisory_xact_lock(:lock_key)"),
        {"lock_key": subject_lock_key(subject_hash)},
    )
