from collections.abc import AsyncIterator

import pytest
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings
from maki.common.models import ApiModel


class StrictPayload(ApiModel):
    count: int


@pytest.fixture
def app() -> FastAPI:
    application = create_app(
        settings=Settings(environment=Environment.TEST),
        container=Container(),
    )

    @application.post(
        "/api/v1/test/strict",
        operation_id="test_strict_payload",
        description="Katı istek doğrulamasını sınar.",
    )
    async def strict_payload(payload: StrictPayload) -> StrictPayload:
        return payload

    @application.get(
        "/api/v1/test/error",
        operation_id="test_internal_error",
        description="Güvenli hata yanıtını sınar.",
    )
    async def internal_error() -> None:
        msg = "özel-veri-123"
        raise RuntimeError(msg)

    return application


@pytest.fixture
async def client(app: FastAPI) -> AsyncIterator[AsyncClient]:
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as test_client:
        yield test_client
