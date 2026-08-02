import asyncio

from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container, ReadinessProbe
from maki.common.config import Environment, Settings
from maki.jobs.models import JobKind


class FailingProbe:
    name = "postgresql"

    async def is_ready(self) -> bool:
        return False


class SlowProbe:
    name = "redis"

    async def is_ready(self) -> bool:
        await asyncio.sleep(1)
        return True


async def test_liveness_has_no_external_dependency(client: AsyncClient) -> None:
    response = await client.get("/health/live")

    assert response.status_code == 200
    assert response.json() == {"durum": "canli"}


async def test_capabilities_use_plain_turkish_feature_states() -> None:
    app = create_app(
        settings=Settings(environment=Environment.TEST),
        container=Container(enabled_job_kinds=frozenset({JobKind.COACH, JobKind.RECEIPT})),
    )
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/health/capabilities")

    assert response.status_code == 200
    assert response.json() == {
        "fis_tarama": True,
        "maki_koc": True,
        "koc_modu": "resmi_veri",
    }


async def test_readiness_hides_dependency_exception_details() -> None:
    probes: tuple[ReadinessProbe, ...] = (FailingProbe(), SlowProbe())
    app = create_app(
        settings=Settings(environment=Environment.TEST),
        container=Container(readiness_probes=probes),
    )

    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/health/ready")

    assert response.status_code == 503
    assert response.json() == {
        "durum": "hazir_degil",
        "bagimliliklar": [
            {"ad": "postgresql", "durum": "hazir_degil"},
            {"ad": "redis", "durum": "zaman_asimi"},
        ],
    }


async def test_api_documentation_is_closed_outside_development() -> None:
    app = create_app(
        settings=Settings(environment=Environment.TEST),
        container=Container(),
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        assert (await client.get("/docs")).status_code == 404
        assert (await client.get("/openapi.json")).status_code == 404
