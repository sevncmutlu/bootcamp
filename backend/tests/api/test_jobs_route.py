from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings
from maki.jobs.errors import JobNotFoundError
from maki.jobs.query import JobStatusView, ResultState

from .job_fakes import FakeTokenVerifier, authorization_headers


class FakeJobQuery:
    async def get(self, *, job_id: str, owner_id: str) -> JobStatusView:
        if owner_id != "cihaz-1":
            raise JobNotFoundError
        return JobStatusView.model_validate_json(
            f"""
            {{
              "job_id": "{job_id}",
              "kind": "forecast",
              "status": "running",
              "result_state": "pending",
              "result": null,
              "failure_code": null,
              "updated_at": "2026-07-19T12:00:00Z"
            }}
            """
        )


async def test_job_route_returns_owner_scoped_status() -> None:
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(
            token_verifier=FakeTokenVerifier(),
            job_query=FakeJobQuery(),
        ),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/jobs/01K00000000000000000000000",
            headers={"Authorization": authorization_headers()["Authorization"]},
        )

    assert response.status_code == 200
    assert response.json()["result_state"] == ResultState.PENDING.value
