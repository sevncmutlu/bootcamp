from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime

from cryptography import x509
from fastapi import FastAPI
from redis.asyncio import Redis

from maki import __version__
from maki.api.app import create_app
from maki.api.dependencies import Container, ReadinessProbe
from maki.billing.account_tokens import AppleAccountTokenIssuer
from maki.billing.app_store import AppStoreVerifier
from maki.billing.google_play import GooglePlayVerifier, GooglePublisherClient
from maki.billing.service import BillingService
from maki.billing.verification import BillingVerificationService
from maki.common.config import Settings
from maki.infrastructure.database import AsyncDatabase, DatabaseProbe, create_database
from maki.infrastructure.entitlement_repository import (
    SqlAlchemyEntitlementRepository,
)
from maki.infrastructure.job_repository import SqlAlchemyJobRepository
from maki.infrastructure.leaderboard_repository import (
    SqlAlchemyLeaderboardRepository,
)
from maki.infrastructure.privacy_repository import SqlAlchemyPrivacyRepository
from maki.infrastructure.redis_ephemeral_receipts import (
    RedisEphemeralReceiptStore,
)
from maki.infrastructure.redis_job_results import RedisJobResultRepository
from maki.infrastructure.redis_queue import RedisProbe
from maki.jobs.models import JobKind
from maki.jobs.query import JobQueryService
from maki.jobs.service import JobService
from maki.leaderboard.service import LeaderboardService
from maki.observability.logging import configure_logging
from maki.observability.telemetry import Telemetry, configure_telemetry
from maki.privacy.deletion import DeletionService
from maki.privacy.export import DataExporter
from maki.security.tokens import TokenVerifier


def create_runtime_app() -> FastAPI:
    settings = Settings()
    configure_logging(development=settings.environment.is_development)
    telemetry = configure_telemetry(
        settings=settings.telemetry,
        environment=settings.environment,
        process_type="api",
        service_version=__version__,
    )
    database = _database(settings)
    redis = _redis(settings)
    probes: list[ReadinessProbe] = []
    if database is not None:
        probes.append(DatabaseProbe(database.engine))
    if redis is not None:
        probes.append(RedisProbe(redis))
    container = _container(
        settings=settings,
        database=database,
        redis=redis,
        probes=tuple(probes),
        telemetry=telemetry,
    )

    @asynccontextmanager
    async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
        try:
            yield
        finally:
            await _shutdown(database, redis, telemetry)

    return create_app(settings=settings, container=container, lifespan=lifespan)


def _database(settings: Settings) -> AsyncDatabase | None:
    if settings.database.dsn is None:
        return None
    return create_database(
        str(settings.database.dsn),
        pool_size=settings.database.pool_size,
        max_overflow=settings.database.max_overflow,
        pool_timeout_seconds=settings.database.pool_timeout_seconds,
    )


def _redis(settings: Settings) -> Redis | None:
    if settings.redis.dsn is None:
        return None
    return Redis.from_url(
        str(settings.redis.dsn),
        decode_responses=False,
        socket_timeout=settings.redis.socket_timeout_seconds,
        max_connections=settings.redis.max_connections,
    )


def _container(
    *,
    settings: Settings,
    database: AsyncDatabase | None,
    redis: Redis | None,
    probes: tuple[ReadinessProbe, ...],
    telemetry: Telemetry,
) -> Container:
    token_verifier = _token_verifier(settings)
    billing_verification = _billing_verification(settings, database)
    data_exporter, deletion_service = _privacy_services(database)
    if database is None or redis is None:
        return Container(
            readiness_probes=probes,
            telemetry=telemetry,
            enabled_job_kinds=_enabled_job_kinds(settings),
            token_verifier=token_verifier,
            billing_verification=billing_verification,
            data_exporter=data_exporter,
            deletion_service=deletion_service,
            leaderboard=(
                LeaderboardService(
                    repository=SqlAlchemyLeaderboardRepository(database.session_factory),
                    clock=_utc_now,
                )
                if database is not None
                else None
            ),
        )
    repository = SqlAlchemyJobRepository(database.session_factory)
    results = RedisJobResultRepository(redis)
    return Container(
        readiness_probes=probes,
        telemetry=telemetry,
        enabled_job_kinds=_enabled_job_kinds(settings),
        job_service=JobService(
            repository=repository,
            clock=_utc_now,
        ),
        token_verifier=token_verifier,
        billing_verification=billing_verification,
        data_exporter=data_exporter,
        deletion_service=deletion_service,
        receipt_ingress=RedisEphemeralReceiptStore(redis),
        job_query=JobQueryService(
            jobs=repository,
            results=results,
        ),
        leaderboard=LeaderboardService(
            repository=SqlAlchemyLeaderboardRepository(
                database.session_factory,
            ),
            clock=_utc_now,
        ),
    )


def _enabled_job_kinds(settings: Settings) -> frozenset[JobKind]:
    enabled = {JobKind.FORECAST}
    if settings.anthropic_api_key is not None:
        enabled.add(JobKind.COACH)
    if (
        settings.ocr.detection_model_dir is not None
        and settings.ocr.recognition_model_dir is not None
    ):
        enabled.add(JobKind.RECEIPT)
    return frozenset(enabled)


def _privacy_services(
    database: AsyncDatabase | None,
) -> tuple[DataExporter | None, DeletionService | None]:
    if database is None:
        return None, None
    repository = SqlAlchemyPrivacyRepository(database.session_factory)
    return (
        DataExporter(repository=repository, clock=_utc_now),
        DeletionService(repository=repository),
    )


def _billing_verification(
    settings: Settings,
    database: AsyncDatabase | None,
) -> BillingVerificationService | None:
    if database is None:
        return None
    billing = BillingService(repository=SqlAlchemyEntitlementRepository(database.session_factory))
    google = None
    service_account = settings.billing.google_service_account_json
    if service_account is not None:
        google = GooglePlayVerifier(
            publisher=GooglePublisherClient.from_service_account_json(
                service_account.get_secret_value()
            ),
            package_name=settings.billing.google_package_name,
            allowed_products=frozenset(settings.billing.allowed_products),
            clock=_utc_now,
        )

    apple = None
    apple_account_tokens = None
    trusted_root = settings.billing.apple_trusted_root_pem
    account_secret = settings.billing.apple_account_token_secret
    if trusted_root is not None and account_secret is not None:
        apple = AppStoreVerifier(
            trusted_root=x509.load_pem_x509_certificate(trusted_root.get_secret_value().encode()),
            bundle_id=settings.billing.apple_bundle_id,
            allowed_products=frozenset(settings.billing.allowed_products),
            environment=settings.billing.apple_environment,
            clock=_utc_now,
        )
        apple_account_tokens = AppleAccountTokenIssuer(
            secret=account_secret.get_secret_value().encode()
        )
    return BillingVerificationService(
        billing=billing,
        google=google,
        apple=apple,
        apple_account_tokens=apple_account_tokens,
    )


def _token_verifier(settings: Settings) -> TokenVerifier | None:
    public_key = settings.security.jwt_public_key
    if public_key is None:
        return None
    return TokenVerifier(
        public_keys={settings.security.jwt_key_id: public_key},
        issuer=settings.security.jwt_issuer,
        audience=settings.security.jwt_audience,
        clock=_utc_now,
    )


def _utc_now() -> datetime:
    return datetime.now(UTC)


async def _shutdown(
    database: AsyncDatabase | None,
    redis: Redis | None,
    telemetry: Telemetry,
) -> None:
    if redis is not None:
        await redis.aclose()
    if database is not None:
        await database.engine.dispose()
    telemetry.shutdown()
