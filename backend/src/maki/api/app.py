from collections.abc import Callable
from contextlib import AbstractAsyncContextManager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from maki.api.dependencies import Container
from maki.api.handlers import register_handlers
from maki.api.middleware.body_limit import BodyLimitMiddleware
from maki.api.middleware.observability import ObservabilityMiddleware
from maki.api.middleware.privacy import PrivacyMiddleware
from maki.api.middleware.request_context import RequestContextMiddleware
from maki.api.routes.billing import router as billing_router
from maki.api.routes.coach import router as coach_router
from maki.api.routes.forecasts import router as forecast_router
from maki.api.routes.health import router as health_router
from maki.api.routes.jobs import router as jobs_router
from maki.api.routes.leaderboard import router as leaderboard_router
from maki.api.routes.official_data import router as official_data_router
from maki.api.routes.privacy import router as privacy_router
from maki.api.routes.receipts import router as receipt_router
from maki.common.config import Settings

type AppLifespan = Callable[[FastAPI], AbstractAsyncContextManager[None]]


def create_app(
    settings: Settings,
    container: Container,
    *,
    lifespan: AppLifespan | None = None,
) -> FastAPI:
    docs_url = "/docs" if settings.environment.is_development else None
    app = FastAPI(
        title="Maki API",
        version="1.0.0",
        description="Maki mobil finans uygulamasının güvenli servis sınırı.",
        docs_url=docs_url,
        redoc_url=None,
        openapi_url="/openapi.json" if docs_url else None,
        lifespan=lifespan,
    )
    app.state.container = container
    app.state.settings = settings
    register_handlers(app)
    app.include_router(health_router)
    app.include_router(billing_router)
    app.include_router(coach_router)
    app.include_router(forecast_router)
    app.include_router(receipt_router)
    app.include_router(jobs_router)
    app.include_router(leaderboard_router)
    app.include_router(privacy_router)
    app.include_router(official_data_router)
    app.add_middleware(PrivacyMiddleware, telemetry=container.telemetry)
    app.add_middleware(BodyLimitMiddleware)
    if container.telemetry is not None:
        app.add_middleware(ObservabilityMiddleware, telemetry=container.telemetry)
    app.add_middleware(RequestContextMiddleware)
    if settings.environment.is_development:
        app.add_middleware(
            CORSMiddleware,
            allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
            allow_credentials=False,
            allow_methods=["GET", "POST", "OPTIONS"],
            allow_headers=[
                "Authorization",
                "Content-Type",
                "Idempotency-Key",
                "X-Maki-Gemini-Key",
                "X-Request-ID",
            ],
            expose_headers=["Retry-After", "X-Request-ID"],
        )
    elif settings.web_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=list(settings.web_origins),
            allow_credentials=False,
            allow_methods=["GET", "POST", "OPTIONS"],
            allow_headers=[
                "Authorization",
                "Content-Type",
                "Idempotency-Key",
                "X-Maki-Gemini-Key",
                "X-Request-ID",
            ],
            expose_headers=["Retry-After", "X-Request-ID"],
        )
    return app
