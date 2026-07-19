import asyncio
from datetime import UTC, datetime, timedelta

from maki import __version__
from maki.common.config import Settings
from maki.infrastructure.database import create_database
from maki.infrastructure.privacy_repository import SqlAlchemyRetentionBackend
from maki.observability.logging import configure_logging
from maki.observability.telemetry import Telemetry, configure_telemetry
from maki.privacy.retention import RetentionDataClass, RetentionPolicy
from maki.workers.retention import RetentionWorker

_DATABASE_CLASSES = (
    RetentionDataClass.IDEMPOTENCY,
    RetentionDataClass.JOB_METADATA,
)


def main() -> None:
    raise SystemExit(asyncio.run(_run()))


async def _run() -> int:
    settings = Settings()
    configure_logging(development=settings.environment.is_development)
    dsn = settings.database.dsn
    if dsn is None:
        return 2
    telemetry = configure_telemetry(
        settings=settings.telemetry,
        environment=settings.environment,
        process_type="retention",
        service_version=__version__,
    )
    database = create_database(
        str(dsn),
        pool_size=settings.database.pool_size,
        max_overflow=settings.database.max_overflow,
        pool_timeout_seconds=settings.database.pool_timeout_seconds,
    )
    policy = RetentionPolicy(
        idempotency_ttl=timedelta(hours=settings.retention.idempotency_hours),
        job_metadata_ttl=timedelta(days=settings.retention.job_metadata_days),
        ocr_result_ttl=timedelta(minutes=settings.retention.ocr_result_minutes),
        telemetry_ttl=timedelta(days=settings.retention.telemetry_days),
    )
    worker = RetentionWorker(
        backend=SqlAlchemyRetentionBackend(database.session_factory),
        policy=policy,
        clock=lambda: datetime.now(UTC),
        batch_size=settings.retention.batch_size,
        data_classes=_DATABASE_CLASSES,
        on_purge=lambda data_class, count: _record_deletion(
            telemetry,
            data_class,
            count,
        ),
    )
    try:
        await worker.run()
    finally:
        await database.engine.dispose()
        telemetry.shutdown()
    return 0


def _record_deletion(
    telemetry: Telemetry,
    data_class: RetentionDataClass,
    count: int,
) -> None:
    telemetry.increment(
        "maki.retention.deleted",
        {"retention.class": data_class.value},
        amount=count,
    )
