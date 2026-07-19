from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings

from .job_fakes import (
    FakeJobService,
    FakeTokenVerifier,
    authorization_headers,
)


async def test_coach_route_only_accepts_strict_single_question() -> None:
    jobs = FakeJobService()
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(job_service=jobs, token_verifier=FakeTokenVerifier()),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        invalid = await client.post(
            "/api/v1/coach/queries",
            headers=authorization_headers(),
            json={
                "question": "Enflasyon nedir?",
                "locale": "tr-TR",
                "session_id": "01K00000000000000000000000",
                "amount": 5_000,
            },
        )
        accepted = await client.post(
            "/api/v1/coach/queries",
            headers=authorization_headers(),
            json={
                "question": "Enflasyon nedir? eposta: kisi@example.com",
                "locale": "tr-TR",
                "session_id": "01K00000000000000000000000",
            },
        )

    assert invalid.status_code == 422
    assert accepted.status_code == 202
    assert accepted.json()["status_url"].startswith("/api/v1/jobs/")
    assert jobs.calls[0][0].value == "coach"
    assert jobs.calls[0][1]["question"] == "Enflasyon nedir? eposta: [EPOSTA]"
