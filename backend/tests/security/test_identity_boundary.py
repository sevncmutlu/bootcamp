from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings


async def test_legacy_password_identity_surface_is_not_exposed() -> None:
    app = create_app(
        settings=Settings(environment=Environment.TEST),
        container=Container(),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)

    async with AsyncClient(transport=transport, base_url="https://maki.test") as client:
        for method, path in (
            ("POST", "/v1/auth/register"),
            ("POST", "/v1/auth/login"),
            ("POST", "/v1/auth/reset-password"),
            ("GET", "/v1/auth/users"),
        ):
            response = await client.request(method, path, json={})
            assert response.status_code == 404


async def test_native_api_does_not_emit_wildcard_cors_headers() -> None:
    app = create_app(
        settings=Settings(environment=Environment.TEST),
        container=Container(),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)

    async with AsyncClient(transport=transport, base_url="https://maki.test") as client:
        response = await client.options(
            "/api/v1/jobs/example",
            headers={
                "Origin": "https://attacker.example",
                "Access-Control-Request-Method": "GET",
            },
        )

    assert "access-control-allow-origin" not in response.headers
    assert "access-control-allow-credentials" not in response.headers
