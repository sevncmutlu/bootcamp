from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings


async def test_local_web_frontend_can_reach_development_api() -> None:
    app = create_app(
        settings=Settings(environment=Environment.DEVELOPMENT),
        container=Container(),
    )
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://maki.test") as client:
        response = await client.options(
            "/health/live",
            headers={
                "Origin": "http://127.0.0.1:4180",
                "Access-Control-Request-Method": "GET",
                "Access-Control-Request-Headers": "authorization",
            },
        )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://127.0.0.1:4180"


async def test_development_cors_rejects_non_local_origin() -> None:
    app = create_app(
        settings=Settings(environment=Environment.DEVELOPMENT),
        container=Container(),
    )
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://maki.test") as client:
        response = await client.options(
            "/health/live",
            headers={
                "Origin": "https://example.com",
                "Access-Control-Request-Method": "GET",
            },
        )

    assert response.status_code == 400
    assert "access-control-allow-origin" not in response.headers
