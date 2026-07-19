import base64
import hashlib
from datetime import UTC, datetime

import orjson
import pytest
from cryptography.hazmat.primitives.asymmetric.ed25519 import (
    Ed25519PrivateKey,
)

from maki.modeling.calibration import CalibrationMethod, CalibrationModel
from maki.modeling.export import (
    ModelExporter,
    ModelExportSettings,
    ProductionSigningKeyRequired,
    canonical_json,
)


class FakeBooster:
    def dump_model(self) -> dict[str, object]:
        return {
            "feature_names": ["borc_orani"],
            "objective": "binary sigmoid:1",
            "tree_info": [],
        }


def test_production_export_is_signed_and_digest_matches_exact_model_bytes() -> None:
    private_key = Ed25519PrivateKey.from_private_bytes(bytes(range(1, 33)))
    artifact = ModelExporter().export(
        booster=FakeBooster(),
        settings=ModelExportSettings(
            feature_names=("borc_orani",),
            model_version="debt-2026-01",
            trained_until=datetime(2026, 1, 31, tzinfo=UTC),
            dataset_sha256="a" * 64,
            calibration=CalibrationModel(
                method=CalibrationMethod.PLATT,
                parameters=(1.2, -0.1),
            ),
            decision_threshold=0.35,
            production=True,
        ),
        signing_key=private_key,
    )
    manifest = orjson.loads(artifact.manifest_bytes)
    signature = base64.b64decode(manifest.pop("signature"))

    assert hashlib.sha256(artifact.model_bytes).hexdigest() == manifest["modelSha256"]
    private_key.public_key().verify(signature, canonical_json(manifest))
    assert manifest["calibration"]["method"] == "platt"
    assert manifest["objective"] == "binary"


def test_production_export_requires_external_signing_key() -> None:
    with pytest.raises(ProductionSigningKeyRequired):
        ModelExporter().export(
            booster=FakeBooster(),
            settings=ModelExportSettings(
                feature_names=("borc_orani",),
                model_version="debt-2026-01",
                trained_until=datetime(2026, 1, 31, tzinfo=UTC),
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


def test_test_only_export_cannot_be_mistaken_for_production() -> None:
    artifact = ModelExporter().export(
        booster=FakeBooster(),
        settings=ModelExportSettings(
            feature_names=("borc_orani",),
            model_version="test-only",
            trained_until=datetime(2026, 1, 31, tzinfo=UTC),
            dataset_sha256="a" * 64,
            calibration=CalibrationModel(
                method=CalibrationMethod.NONE,
                parameters=(),
            ),
            decision_threshold=0.5,
            production=False,
        ),
        signing_key=None,
    )

    assert artifact.production is False
    assert orjson.loads(artifact.manifest_bytes)["signature"] == "test-only"
