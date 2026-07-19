from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings
from maki.leaderboard.models import (
    CohortPercentile,
    PercentileStatus,
)

from .job_fakes import FakeTokenVerifier, authorization_headers


class FakeLeaderboard:
    async def percentile(self, **_kwargs: object) -> CohortPercentile:
        return CohortPercentile(
            status=PercentileStatus.INSUFFICIENT_COHORT,
            cohort_size_bucket="0-49",
        )


async def test_leaderboard_route_rejects_city_and_returns_no_exact_size() -> None:
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(
            token_verifier=FakeTokenVerifier(),
            leaderboard=FakeLeaderboard(),
        ),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    payload = {
        "cohort": {
            "age_band": "25-34",
            "household_band": "1",
        },
        "score_basis_points": 2_500,
    }
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        invalid = await client.post(
            "/api/v1/leaderboard/percentiles",
            headers=authorization_headers(),
            json={
                **payload,
                "cohort": {**payload["cohort"], "city": "İstanbul"},
            },
        )
        response = await client.post(
            "/api/v1/leaderboard/percentiles",
            headers=authorization_headers(),
            json=payload,
        )

    assert invalid.status_code == 422
    assert response.status_code == 200
    assert response.json() == {
        "status": "insufficient_cohort",
        "percentile_bucket": None,
        "cohort_size_bucket": "0-49",
    }
