from datetime import UTC, datetime

import pytest
from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings
from maki.modeling.calibration import CalibrationMethod, CalibrationModel
from maki.modeling.export import (
    ModelExporter,
    ModelExportSettings,
    ProductionSigningKeyRequired,
)
from tests.api.job_fakes import (
    FakeJobService,
    FakeTokenVerifier,
    authorization_headers,
)


class MemoryReceiptIngress:
    async def put(
        self,
        *,
        owner_id: str,
        content: bytes,
        media_type: str,
    ) -> str:
        del owner_id, content, media_type
        return "01K0A1B2C3D4E5F6G7H8J9K0MN"


class FakeBooster:
    def dump_model(self) -> dict[str, object]:
        return {"feature_names": ["borc_orani"], "tree_info": []}


@pytest.mark.parametrize(
    ("path", "request_kwargs"),
    [
        (
            "/api/v1/coach/queries",
            {
                "json": {
                    "question": "Bütçemi nasıl planlarım?",
                    "locale": "tr-TR",
                    "session_id": "01K0A1B2C3D4E5F6G7H8J9K0MN",
                }
            },
        ),
        (
            "/api/v1/receipts/jobs",
            {"files": {"file": ("fis.png", b"png", "image/png")}},
        ),
    ],
)
async def test_missing_worker_capability_rejects_job_at_api_boundary(
    path: str,
    request_kwargs: dict[str, object],
) -> None:
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(
            token_verifier=FakeTokenVerifier(),
            job_service=FakeJobService(),
            receipt_ingress=MemoryReceiptIngress(),
            enabled_job_kinds=frozenset(),
        ),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            path,
            headers=authorization_headers(),
            **request_kwargs,
        )

    assert response.status_code == 503
    assert response.json()["kod"] == "SERVIS_HAZIR_DEGIL"
    assert response.json()["mesaj"] == "İstenen servis hazır değil."
    assert response.json()["tekrar_denenebilir"] is True


async def test_missing_store_credentials_never_grant_entitlement() -> None:
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(token_verifier=FakeTokenVerifier()),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/billing/verifications",
            headers=authorization_headers(),
            json={
                "store": "google_play",
                "package_name": "com.team120.maki.maki_app",
                "purchase_token": "canli-olmayan-token",
            },
        )

    assert response.status_code == 503
    assert response.json()["kod"] == "ODEME_DOGRULAMA_HAZIR_DEGIL"
    assert response.json()["tekrar_denenebilir"] is True
    assert "active" not in response.text


def test_missing_signing_key_never_exports_production_model() -> None:
    with pytest.raises(ProductionSigningKeyRequired):
        ModelExporter().export(
            booster=FakeBooster(),
            settings=ModelExportSettings(
                feature_names=("borc_orani",),
                model_version="debt-acceptance",
                trained_until=datetime(2026, 7, 19, tzinfo=UTC),
                dataset_sha256="a" * 64,
                calibration=CalibrationModel(
                    method=CalibrationMethod.NONE,
                    parameters=(),
                ),
                decision_threshold=0.5,
                production=True,
            ),
            signing_key=None,
        )
