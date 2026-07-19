from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Annotated, Protocol

from fastapi import Header, Request

from maki.billing.verification import ProviderNotConfigured
from maki.jobs.models import JobKind
from maki.security.tokens import AuthenticationError

if TYPE_CHECKING:
    from pydantic import JsonValue

    from maki.billing.models import Entitlement
    from maki.jobs.models import JobRecord
    from maki.jobs.query import JobStatusView
    from maki.leaderboard.models import CohortKey, CohortPercentile
    from maki.observability.telemetry import Telemetry
    from maki.privacy.deletion import DeletionCounts
    from maki.privacy.export import DataExport
    from maki.security.tokens import TokenClaims

_AUTHENTICATION_CODE = "OTURUM_GECERSIZ"
_AUTHENTICATION_MESSAGE = "Geçerli oturum belirteci gereklidir."


class ReadinessProbe(Protocol):
    name: str

    async def is_ready(self) -> bool: ...


class JobAcceptor(Protocol):
    async def accept(
        self,
        kind: JobKind,
        payload: dict[str, JsonValue],
        owner_id: str,
        idempotency_key: str,
    ) -> JobRecord: ...


class SessionTokenVerifier(Protocol):
    def verify(self, token: str) -> TokenClaims: ...


class ReceiptIngress(Protocol):
    async def put(
        self,
        *,
        owner_id: str,
        content: bytes,
        media_type: str,
    ) -> str: ...


class JobQuery(Protocol):
    async def get(
        self,
        *,
        job_id: str,
        owner_id: str,
    ) -> JobStatusView: ...


class LeaderboardPort(Protocol):
    async def percentile(
        self,
        *,
        cohort: CohortKey,
        score_basis_points: int,
        subject_id: str,
    ) -> CohortPercentile: ...


class BillingVerificationPort(Protocol):
    async def verify_google(
        self,
        *,
        package_name: str,
        purchase_token: str,
        subject_id: str,
    ) -> Entitlement: ...

    async def verify_apple(
        self,
        *,
        signed_transaction: str,
        subject_id: str,
    ) -> Entitlement: ...

    async def entitlements(
        self,
        *,
        subject_id: str,
    ) -> tuple[Entitlement, ...]: ...


class DataExporterPort(Protocol):
    async def export(self, *, subject_id: str) -> DataExport: ...


class DeletionServicePort(Protocol):
    async def delete(self, *, subject_id: str) -> DeletionCounts: ...


class ServiceNotReadyError(RuntimeError):
    pass


@dataclass(frozen=True, slots=True)
class Container:
    readiness_probes: tuple[ReadinessProbe, ...] = ()
    telemetry: Telemetry | None = None
    job_service: JobAcceptor | None = None
    token_verifier: SessionTokenVerifier | None = None
    receipt_ingress: ReceiptIngress | None = None
    job_query: JobQuery | None = None
    leaderboard: LeaderboardPort | None = None
    billing_verification: BillingVerificationPort | None = None
    data_exporter: DataExporterPort | None = None
    deletion_service: DeletionServicePort | None = None
    enabled_job_kinds: frozenset[JobKind] | None = None


AuthorizationHeader = Annotated[
    str | None,
    Header(alias="Authorization"),
]
IdempotencyHeader = Annotated[
    str,
    Header(
        alias="Idempotency-Key",
        min_length=8,
        max_length=128,
    ),
]


def container_from_request(request: Request) -> Container:
    container: Container = request.app.state.container
    return container


def authenticated_subject(
    request: Request,
    authorization: AuthorizationHeader = None,
) -> str:
    container = container_from_request(request)
    if container.token_verifier is None:
        msg = "Oturum doğrulama servisi hazır değil."
        raise ServiceNotReadyError(msg)
    if authorization is None or not authorization.startswith("Bearer "):
        raise AuthenticationError(
            _AUTHENTICATION_CODE,
            _AUTHENTICATION_MESSAGE,
        )
    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise AuthenticationError(
            _AUTHENTICATION_CODE,
            _AUTHENTICATION_MESSAGE,
        )
    return container.token_verifier.verify(token).sub


def job_acceptor(request: Request) -> JobAcceptor:
    service = container_from_request(request).job_service
    if service is None:
        msg = "İş kabul servisi hazır değil."
        raise ServiceNotReadyError(msg)
    return service


def coach_job_acceptor(request: Request) -> JobAcceptor:
    return _job_acceptor_for(request, JobKind.COACH)


def receipt_job_acceptor(request: Request) -> JobAcceptor:
    return _job_acceptor_for(request, JobKind.RECEIPT)


def _job_acceptor_for(request: Request, kind: JobKind) -> JobAcceptor:
    container = container_from_request(request)
    enabled = container.enabled_job_kinds
    if enabled is not None and kind not in enabled:
        msg = "İş türü için zorunlu üretim yeteneği hazır değil."
        raise ServiceNotReadyError(msg)
    return job_acceptor(request)


def receipt_ingress(request: Request) -> ReceiptIngress:
    ingress = container_from_request(request).receipt_ingress
    if ingress is None:
        msg = "Fiş kabul servisi hazır değil."
        raise ServiceNotReadyError(msg)
    return ingress


def job_query(request: Request) -> JobQuery:
    query = container_from_request(request).job_query
    if query is None:
        msg = "İş sorgulama servisi hazır değil."
        raise ServiceNotReadyError(msg)
    return query


def leaderboard(request: Request) -> LeaderboardPort:
    service = container_from_request(request).leaderboard
    if service is None:
        msg = "Liderlik servisi hazır değil."
        raise ServiceNotReadyError(msg)
    return service


def billing_verification(request: Request) -> BillingVerificationPort:
    service = container_from_request(request).billing_verification
    if service is None:
        raise ProviderNotConfigured
    return service


def data_exporter(request: Request) -> DataExporterPort:
    service = container_from_request(request).data_exporter
    if service is None:
        msg = "Veri dışa aktarma servisi hazır değil."
        raise ServiceNotReadyError(msg)
    return service


def deletion_service(request: Request) -> DeletionServicePort:
    service = container_from_request(request).deletion_service
    if service is None:
        msg = "Veri silme servisi hazır değil."
        raise ServiceNotReadyError(msg)
    return service
