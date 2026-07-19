import asyncio
from datetime import UTC, datetime

from redis.asyncio import Redis

from maki import __version__
from maki.common.config import Settings
from maki.infrastructure.database import create_database
from maki.infrastructure.job_repository import SqlAlchemyJobRepository
from maki.infrastructure.redis_queue import RedisJobPublisher
from maki.observability.logging import configure_logging
from maki.observability.telemetry import configure_telemetry
from maki.workers.dispatcher import OutboxDispatcher
from maki.workers.looping import install_stop_event, wait_or_stop

_IDLE_SECONDS = 0.25


def main() -> None:
    raise SystemExit(asyncio.run(_run()))


async def _run() -> int:
    settings = Settings()
    configure_logging(development=settings.environment.is_development)
    if settings.database.dsn is None or settings.redis.dsn is None:
        return 2
    telemetry = configure_telemetry(
        settings=settings.telemetry,
        environment=settings.environment,
        process_type="dispatcher",
        service_version=__version__,
    )
    database = create_database(
        str(settings.database.dsn),
        pool_size=settings.database.pool_size,
        max_overflow=settings.database.max_overflow,
        pool_timeout_seconds=settings.database.pool_timeout_seconds,
    )
    redis = Redis.from_url(
        str(settings.redis.dsn),
        decode_responses=False,
        socket_timeout=settings.redis.socket_timeout_seconds,
        max_connections=settings.redis.max_connections,
    )
    dispatcher = OutboxDispatcher(
        repository=SqlAlchemyJobRepository(database.session_factory),
        queue=RedisJobPublisher(redis),
        clock=lambda: datetime.now(UTC),
        telemetry=telemetry,
    )
    stop = install_stop_event()
    try:
        while not stop.is_set():
            published = await dispatcher.run_once()
            if not published:
                await wait_or_stop(stop, _IDLE_SECONDS)
    finally:
        await redis.aclose()
        await database.engine.dispose()
        telemetry.shutdown()
    return 0


if __name__ == "__main__":
    main()
