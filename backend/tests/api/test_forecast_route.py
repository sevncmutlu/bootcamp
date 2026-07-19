from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings

from .job_fakes import (
    FakeJobService,
    FakeTokenVerifier,
    authorization_headers,
)


async def test_forecast_route_rejects_amount_and_requires_idempotency() -> None:
    jobs = FakeJobService()
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(job_service=jobs, token_verifier=FakeTokenVerifier()),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    payload = {
        "series": {"points": [{"day": day, "index": 1.0 + day / 100} for day in range(56)]},
        "horizon": 7,
    }
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        missing_key = await client.post(
            "/api/v1/forecasts/jobs",
            headers={"Authorization": authorization_headers()["Authorization"]},
            json=payload,
        )
        forbidden = await client.post(
            "/api/v1/forecasts/jobs",
            headers=authorization_headers(),
            json={**payload, "amount": 5_000},
        )
        accepted = await client.post(
            "/api/v1/forecasts/jobs",
            headers=authorization_headers(),
            json=payload,
        )

    assert missing_key.status_code == 422
    assert forbidden.status_code == 422
    assert accepted.status_code == 202
    assert jobs.calls[0][1]["horizon"] == 7
