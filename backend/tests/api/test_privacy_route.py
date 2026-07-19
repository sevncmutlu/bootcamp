from datetime import UTC, datetime

from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings
from maki.privacy.deletion import DeletionCounts
from maki.privacy.export import DataExport

from .job_fakes import FakeTokenVerifier, authorization_headers

NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)


class FakeExporter:
    async def export(self, *, subject_id: str) -> DataExport:
        del subject_id
        return DataExport(
            generated_at=NOW,
            entitlements=(),
            jobs=(),
            billing_events=(),
        )


class FakeDeletion:
    async def delete(self, *, subject_id: str) -> DeletionCounts:
        del subject_id
        return DeletionCounts(jobs=1)


async def test_privacy_export_and_delete_require_owner_authentication() -> None:
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(
            token_verifier=FakeTokenVerifier(),
            data_exporter=FakeExporter(),
            deletion_service=FakeDeletion(),
        ),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        unauthorized = await client.get("/api/v1/privacy/exports")
        exported = await client.get(
            "/api/v1/privacy/exports",
            headers=authorization_headers(),
        )
        deleted = await client.delete(
            "/api/v1/privacy/data",
            headers=authorization_headers(),
        )

    assert unauthorized.status_code == 401
    assert exported.status_code == 200
    assert exported.json()["schema_version"] == "1.0"
    assert exported.headers["cache-control"] == "no-store"
    assert deleted.status_code == 200
    assert deleted.headers["cache-control"] == "no-store"
    assert deleted.json() == {
        "jobs": 1,
        "entitlements": 0,
        "billing_events_anonymized": 0,
        "leaderboard_contributions": 0,
    }


async def test_privacy_delete_requires_idempotency_key() -> None:
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(
            token_verifier=FakeTokenVerifier(),
            data_exporter=FakeExporter(),
            deletion_service=FakeDeletion(),
        ),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    headers = authorization_headers()
    headers.pop("Idempotency-Key")
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.delete(
            "/api/v1/privacy/data",
            headers=headers,
        )

    assert response.status_code == 422
