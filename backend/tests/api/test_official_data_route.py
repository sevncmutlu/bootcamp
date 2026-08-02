from datetime import UTC, date, datetime

from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings
from maki.official_data.models import PublicationState, SeriesPoint, SourceSnapshot

_NOW = datetime(2026, 8, 1, tzinfo=UTC)


class FakeOfficialDataRepository:
    def __init__(self, snapshot: SourceSnapshot | None) -> None:
        self.snapshot = snapshot

    async def latest_published(self, source_name: str) -> SourceSnapshot | None:
        assert source_name == "tuik"
        return self.snapshot


async def test_latest_inflation_uses_two_real_published_points() -> None:
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(official_data=FakeOfficialDataRepository(_snapshot())),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/official-data/inflation/latest")

    assert response.status_code == 200
    assert response.json() == {
        "period": "2026-07",
        "previous_period": "2026-06",
        "rate_basis_points": 352,
        "source": "TÜİK",
        "source_url": "https://data.tuik.gov.tr/",
        "retrieved_at": "2026-08-01T00:00:00Z",
    }


async def test_latest_inflation_is_honestly_unavailable_without_snapshot() -> None:
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(official_data=FakeOfficialDataRepository(None)),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/official-data/inflation/latest")

    assert response.status_code == 503
    assert response.json()["kod"] == "SERVIS_HAZIR_DEGIL"


def _snapshot() -> SourceSnapshot:
    points = (
        SeriesPoint(
            series_id="TUFE_GENEL",
            period=date(2026, 6, 1),
            value="119.25",
            unit="index",
            release_date=date(2026, 7, 3),
            source_url="https://data.tuik.gov.tr/",
            retrieved_at=_NOW,
        ),
        SeriesPoint(
            series_id="TUFE_GENEL",
            period=date(2026, 7, 1),
            value="123.45",
            unit="index",
            release_date=date(2026, 8, 1),
            source_url="https://data.tuik.gov.tr/",
            retrieved_at=_NOW,
        ),
    )
    return SourceSnapshot(
        source_name="tuik",
        source_version="2026-08-01",
        schema_version=1,
        content_sha256="a" * 64,
        points=points,
        state=PublicationState.PUBLISHED,
        published_at=_NOW,
    )
