import os
import socket
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime

from redis.asyncio import Redis

from maki import __version__
from maki.common.config import Settings
from maki.infrastructure.database import AsyncDatabase, create_database
from maki.infrastructure.job_repository import SqlAlchemyJobRepository
from maki.infrastructure.redis_ephemeral_receipts import RedisEphemeralReceiptStore
from maki.infrastructure.redis_job_results import RedisJobResultRepository
from maki.infrastructure.redis_queue import RedisJobQueue
from maki.jobs.models import JobKind
from maki.observability.logging import configure_logging
from maki.observability.telemetry import Telemetry, configure_telemetry
from maki.workers.looping import install_stop_event
from maki.workers.runtime import JobHandler, WorkerRuntime

_CONSUMER_LENGTH_LIMIT = 96


class ProcessNotConfiguredError(RuntimeError):
    pass


@dataclass(frozen=True, slots=True)
class WorkerResources:
    settings: Settings
    database: AsyncDatabase
    redis: Redis
    results: RedisJobResultRepository
    receipts: RedisEphemeralReceiptStore


type HandlerFactory = Callable[[WorkerResources], JobHandler]


async def run_specialized_worker(
    *,
    kind: JobKind,
    handler_factory: HandlerFactory,
) -> int:
    settings = Settings()
    configure_logging(development=settings.environment.is_development)
    if settings.database.dsn is None or settings.redis.dsn is None:
        return 2
    telemetry = configure_telemetry(
        settings=settings.telemetry,
        environment=settings.environment,
        process_type=f"worker-{kind.value}",
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
    resources = WorkerResources(
        settings=settings,
        database=database,
        redis=redis,
        results=RedisJobResultRepository(redis),
        receipts=RedisEphemeralReceiptStore(redis),
    )
    try:
        handler = handler_factory(resources)
    except ProcessNotConfiguredError:
        await _shutdown(database, redis, telemetry)
        return 3
    runtime = WorkerRuntime(
        queue=RedisJobQueue(
            redis,
            stream=f"maki:jobs:{kind.value}",
            consumer=_consumer_name(kind),
        ),
        repository=SqlAlchemyJobRepository(database.session_factory),
        handlers={kind: handler},
        clock=_utc_now,
        telemetry=telemetry,
    )
    stop = install_stop_event()
    try:
        while not stop.is_set():
            await runtime.run_once()
    finally:
        await _shutdown(database, redis, telemetry)
    return 0


def _consumer_name(kind: JobKind) -> str:
    value = f"{kind.value}-{socket.gethostname()}-{os.getpid()}"
    return value[:_CONSUMER_LENGTH_LIMIT]


def _utc_now() -> datetime:
    return datetime.now(UTC)


async def _shutdown(
    database: AsyncDatabase,
    redis: Redis,
    telemetry: Telemetry,
) -> None:
    await redis.aclose()
    await database.engine.dispose()
    telemetry.shutdown()
