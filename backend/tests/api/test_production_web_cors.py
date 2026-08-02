import pytest
from httpx import ASGITransport, AsyncClient
from pydantic import ValidationError

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings


async def test_configured_web_origin_can_reach_api() -> None:
    app = create_app(
        settings=Settings(
            environment=Environment.TEST,
            web_origins=("https://app.maki.example",),
        ),
        container=Container(),
    )
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="https://maki.test") as client:
        response = await client.options(
            "/health/live",
            headers={
                "Origin": "https://app.maki.example",
                "Access-Control-Request-Method": "GET",
                "Access-Control-Request-Headers": "authorization",
            },
        )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "https://app.maki.example"
    assert response.headers.get("access-control-allow-credentials") is None


async def test_unlisted_web_origin_is_rejected() -> None:
    app = create_app(
        settings=Settings(
            environment=Environment.TEST,
            web_origins=("https://app.maki.example",),
        ),
        container=Container(),
    )
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="https://maki.test") as client:
        response = await client.options(
            "/health/live",
            headers={
                "Origin": "https://attacker.example",
                "Access-Control-Request-Method": "GET",
            },
        )

    assert response.status_code == 400
    assert "access-control-allow-origin" not in response.headers


@pytest.mark.parametrize(
    "origin",
    [
        "*",
        "http://app.maki.example",
        "https://app.maki.example/path",
        "https://user:secret@app.maki.example",
        "https://app.maki.example/",
    ],
)
def test_unsafe_web_origins_are_rejected(origin: str) -> None:
    with pytest.raises(ValidationError):
        Settings(environment=Environment.TEST, web_origins=(origin,))
