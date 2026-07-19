import asyncio
from datetime import UTC, datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from maki import __version__
from maki.common.config import Settings
from maki.infrastructure.database import create_database
from maki.infrastructure.privacy_repository import SqlAlchemyRetentionBackend
from maki.observability.logging import configure_logging
from maki.observability.telemetry import Telemetry, configure_telemetry
from maki.privacy.retention import RetentionDataClass, RetentionPolicy
from maki.workers.looping import install_stop_event, wait_or_stop
from maki.workers.retention import RetentionWorker

_RUN_INTERVAL_SECONDS = 60 * 60
_DATABASE_CLASSES = (
    RetentionDataClass.IDEMPOTENCY,
    RetentionDataClass.JOB_METADATA,
)


def main() -> None:
    raise SystemExit(asyncio.run(_run()))


async def _run() -> int:
    settings = Settings()
    configure_logging(development=settings.environment.is_development)
    if settings.database.dsn is None:
        return 2
    telemetry = configure_telemetry(
        settings=settings.telemetry,
        environment=settings.environment,
        process_type="worker-data",
        service_version=__version__,
    )
    database = create_database(
        str(settings.database.dsn),
        pool_size=settings.database.pool_size,
        max_overflow=settings.database.max_overflow,
        pool_timeout_seconds=settings.database.pool_timeout_seconds,
    )
    worker = _worker(settings, database.session_factory, telemetry)
    stop = install_stop_event()
    try:
        while not stop.is_set():
            await worker.run()
            await wait_or_stop(stop, _RUN_INTERVAL_SECONDS)
    finally:
        await database.engine.dispose()
        telemetry.shutdown()
    return 0


def _worker(
    settings: Settings,
    session_factory: async_sessionmaker[AsyncSession],
    telemetry: Telemetry,
) -> RetentionWorker:
    policy = RetentionPolicy(
        idempotency_ttl=timedelta(hours=settings.retention.idempotency_hours),
        job_metadata_ttl=timedelta(days=settings.retention.job_metadata_days),
        ocr_result_ttl=timedelta(minutes=settings.retention.ocr_result_minutes),
        telemetry_ttl=timedelta(days=settings.retention.telemetry_days),
    )
    return RetentionWorker(
        backend=SqlAlchemyRetentionBackend(session_factory),
        policy=policy,
        clock=lambda: datetime.now(UTC),
        batch_size=settings.retention.batch_size,
        data_classes=_DATABASE_CLASSES,
        on_purge=lambda data_class, count: telemetry.increment(
            "maki.retention.deleted",
            {"retention.class": data_class.value},
            amount=count,
        ),
    )


if __name__ == "__main__":
    main()
