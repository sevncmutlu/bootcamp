from collections.abc import Sequence

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import Response
from starlette.exceptions import HTTPException
from starlette.types import Scope

from maki.api.dependencies import ServiceNotReadyError
from maki.billing.google_play import (
    StoreProviderUnavailableError,
    StoreVerificationError,
)
from maki.billing.verification import ProviderNotConfigured
from maki.common.errors import ErrorCode, Problem
from maki.common.ids import new_ulid
from maki.infrastructure.redis_ephemeral_receipts import (
    ReceiptStoreUnavailableError,
)
from maki.infrastructure.redis_job_results import ResultStoreUnavailableError
from maki.jobs.errors import (
    IdempotencyConflictError,
    JobNotFoundError,
    UnsafeJobPayloadError,
)
from maki.security.tokens import AuthenticationError

_HTTP_ERROR_MAP = {
    404: (ErrorCode.NOT_FOUND, "İstenen kaynak bulunamadı."),
    405: (ErrorCode.METHOD_NOT_ALLOWED, "Bu yönteme izin verilmiyor."),
}


def request_id_from_scope(scope: Scope) -> str:
    state = scope.get("state")
    if isinstance(state, dict):
        request_id = state.get("request_id")
        if isinstance(request_id, str):
            return request_id
    return new_ulid()


def problem_response(
    *,
    status_code: int,
    code: ErrorCode,
    message: str,
    request_id: str,
    retryable: bool = False,
    details: Sequence[dict[str, str]] = (),
) -> Response:
    problem = Problem(
        kod=code,
        mesaj=message,
        istek_kimligi=request_id,
        tekrar_denenebilir=retryable,
        ayrintilar=tuple(details),
    )
    return Response(
        status_code=status_code,
        content=problem.model_dump_json(),
        media_type="application/problem+json",
    )


def register_handlers(app: FastAPI) -> None:
    _register_billing_handlers(app)
    _register_domain_handlers(app)
    _register_framework_handlers(app)


def _register_billing_handlers(app: FastAPI) -> None:
    @app.exception_handler(ProviderNotConfigured)
    async def billing_not_ready_handler(
        request: Request,
        _error: ProviderNotConfigured,
    ) -> Response:
        return problem_response(
            status_code=503,
            code=ErrorCode.BILLING_NOT_READY,
            message="Ödeme doğrulama servisi hazır değil.",
            request_id=request_id_from_scope(request.scope),
            retryable=True,
        )

    @app.exception_handler(StoreVerificationError)
    async def billing_verification_error_handler(
        request: Request,
        _error: StoreVerificationError,
    ) -> Response:
        return problem_response(
            status_code=422,
            code=ErrorCode.BILLING_VERIFICATION_FAILED,
            message="Mağaza işlemi doğrulanamadı.",
            request_id=request_id_from_scope(request.scope),
        )

    @app.exception_handler(StoreProviderUnavailableError)
    async def billing_provider_error_handler(
        request: Request,
        _error: StoreProviderUnavailableError,
    ) -> Response:
        return problem_response(
            status_code=503,
            code=ErrorCode.BILLING_NOT_READY,
            message="Mağaza servisine geçici olarak ulaşılamıyor.",
            request_id=request_id_from_scope(request.scope),
            retryable=True,
        )


def _register_domain_handlers(app: FastAPI) -> None:
    @app.exception_handler(AuthenticationError)
    async def authentication_error_handler(
        request: Request,
        _error: AuthenticationError,
    ) -> Response:
        return problem_response(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            message="Oturum doğrulanamadı.",
            request_id=request_id_from_scope(request.scope),
        )

    @app.exception_handler(ServiceNotReadyError)
    async def service_not_ready_handler(
        request: Request,
        _error: ServiceNotReadyError,
    ) -> Response:
        return problem_response(
            status_code=503,
            code=ErrorCode.NOT_READY,
            message="İstenen servis hazır değil.",
            request_id=request_id_from_scope(request.scope),
            retryable=True,
        )

    @app.exception_handler(JobNotFoundError)
    async def job_not_found_handler(
        request: Request,
        _error: JobNotFoundError,
    ) -> Response:
        return problem_response(
            status_code=404,
            code=ErrorCode.NOT_FOUND,
            message="İş bulunamadı.",
            request_id=request_id_from_scope(request.scope),
        )

    @app.exception_handler(IdempotencyConflictError)
    async def idempotency_conflict_handler(
        request: Request,
        _error: IdempotencyConflictError,
    ) -> Response:
        return problem_response(
            status_code=409,
            code=ErrorCode.IDEMPOTENCY_CONFLICT,
            message="Tekrarlama anahtarı farklı bir istek için kullanılmış.",
            request_id=request_id_from_scope(request.scope),
        )

    @app.exception_handler(UnsafeJobPayloadError)
    async def unsafe_job_payload_handler(
        request: Request,
        _error: UnsafeJobPayloadError,
    ) -> Response:
        return problem_response(
            status_code=422,
            code=ErrorCode.PRIVACY_FIELD_REJECTED,
            message="İstek kişisel finans alanı içeriyor.",
            request_id=request_id_from_scope(request.scope),
        )

    @app.exception_handler(ReceiptStoreUnavailableError)
    @app.exception_handler(ResultStoreUnavailableError)
    async def temporary_store_error_handler(
        request: Request,
        _error: Exception,
    ) -> Response:
        return problem_response(
            status_code=503,
            code=ErrorCode.NOT_READY,
            message="Geçici sonuç servisi hazır değil.",
            request_id=request_id_from_scope(request.scope),
            retryable=True,
        )


def _register_framework_handlers(app: FastAPI) -> None:
    @app.exception_handler(RequestValidationError)
    async def validation_error_handler(
        request: Request,
        error: RequestValidationError,
    ) -> Response:
        details = tuple(
            {
                "alan": ".".join(str(part) for part in item["loc"]),
                "neden": "Geçersiz değer.",
            }
            for item in error.errors()
        )
        return problem_response(
            status_code=422,
            code=ErrorCode.VALIDATION_FAILED,
            message="İstek alanları doğrulanamadı.",
            request_id=request_id_from_scope(request.scope),
            details=details,
        )

    @app.exception_handler(HTTPException)
    async def http_error_handler(request: Request, error: HTTPException) -> Response:
        code, message = _HTTP_ERROR_MAP.get(
            error.status_code,
            (ErrorCode.VALIDATION_FAILED, "İstek işlenemedi."),
        )
        return problem_response(
            status_code=error.status_code,
            code=code,
            message=message,
            request_id=request_id_from_scope(request.scope),
        )

    @app.exception_handler(Exception)
    async def unexpected_error_handler(request: Request, _error: Exception) -> Response:
        return problem_response(
            status_code=500,
            code=ErrorCode.INTERNAL,
            message="Beklenmeyen bir hata oluştu.",
            request_id=request_id_from_scope(request.scope),
        )
