from __future__ import annotations

import base64
import hashlib
from datetime import UTC, datetime
from typing import TYPE_CHECKING, Any, Protocol

import orjson
from pydantic import Field

from maki.common.models import ApiModel
from maki.modeling.calibration import CalibrationModel  # noqa: TC001

if TYPE_CHECKING:
    from cryptography.hazmat.primitives.asymmetric.ed25519 import (
        Ed25519PrivateKey,
    )


class ProductionSigningKeyRequired(RuntimeError):  # noqa: N818
    pass


class Booster(Protocol):
    def dump_model(self) -> dict[str, Any]: ...


class ExportedModel(ApiModel):
    model_bytes: bytes
    manifest_bytes: bytes
    production: bool


class RuntimeManifestBody(ApiModel):
    schema_version: int = Field(alias="schemaVersion")
    model_version: str = Field(alias="modelVersion", min_length=1, max_length=128)
    feature_names: tuple[str, ...] = Field(
        alias="featureNames",
        min_length=1,
        max_length=10_000,
    )
    trained_until: str = Field(alias="trainedUntil")
    model_sha256: str = Field(alias="modelSha256", pattern=r"^[0-9a-f]{64}$")
    dataset_sha256: str = Field(alias="datasetSha256", pattern=r"^[0-9a-f]{64}$")
    objective: str
    calibration: CalibrationModel
    decision_threshold: float = Field(alias="decisionThreshold", ge=0, le=1)


class ModelExportSettings(ApiModel):
    feature_names: tuple[str, ...] = Field(min_length=1, max_length=10_000)
    model_version: str = Field(min_length=1, max_length=128)
    trained_until: datetime
    dataset_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    calibration: CalibrationModel
    decision_threshold: float = Field(ge=0, le=1)
    production: bool


def canonical_json(value: object) -> bytes:
    return orjson.dumps(value, option=orjson.OPT_SORT_KEYS)


class ModelExporter:
    def export(
        self,
        *,
        booster: Booster,
        settings: ModelExportSettings,
        signing_key: Ed25519PrivateKey | None,
    ) -> ExportedModel:
        _validate_training_time(settings.trained_until)
        if settings.production and signing_key is None:
            msg = "Üretim modelini imzalamak için dış anahtar gereklidir."
            raise ProductionSigningKeyRequired(msg)

        model_bytes = canonical_json(booster.dump_model())
        body = RuntimeManifestBody(
            schemaVersion=2,
            modelVersion=settings.model_version,
            featureNames=settings.feature_names,
            trainedUntil=_utc_text(settings.trained_until),
            modelSha256=hashlib.sha256(model_bytes).hexdigest(),
            datasetSha256=settings.dataset_sha256,
            objective="binary",
            calibration=settings.calibration,
            decisionThreshold=settings.decision_threshold,
        )
        body_value = body.model_dump(mode="json", by_alias=True)
        signature = (
            base64.b64encode(signing_key.sign(canonical_json(body_value))).decode()
            if signing_key is not None
            else "test-only"
        )
        manifest_bytes = canonical_json({**body_value, "signature": signature})
        return ExportedModel(
            model_bytes=model_bytes,
            manifest_bytes=manifest_bytes,
            production=settings.production,
        )


def _validate_training_time(value: datetime) -> None:
    if value.tzinfo is None or value.utcoffset() != UTC.utcoffset(value):
        msg = "Model eğitim zamanı UTC olmalıdır."
        raise ValueError(msg)


def _utc_text(value: datetime) -> str:
    return (
        value.astimezone(UTC)
        .isoformat(timespec="milliseconds")
        .replace(
            "+00:00",
            "Z",
        )
    )
