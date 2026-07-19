from __future__ import annotations

import hashlib
import math
from datetime import UTC, date, datetime
from enum import StrEnum
from typing import Annotated, Self

from pydantic import BeforeValidator, Field, field_validator, model_validator

from maki.common.models import ApiModel
from maki.modeling.features import FeatureDefinition


def _tuple_from_list(value: object) -> object:
    if isinstance(value, list):
        return tuple(value)
    return value


class DatasetNotEligible(ValueError):  # noqa: N818
    pass


class DatasetPurpose(StrEnum):
    TRAINING = "training"
    TEST = "test"


SourceVersions = Annotated[
    tuple[str, ...],
    BeforeValidator(_tuple_from_list),
    Field(min_length=1, max_length=100),
]


class DatasetManifest(ApiModel):
    owner: str = Field(min_length=2, max_length=128)
    period_start: date
    period_end: date
    row_count: int = Field(ge=1, le=100_000_000)
    feature_version: str = Field(min_length=1, max_length=64)
    label_definition: str = Field(min_length=3, max_length=500)
    license: str = Field(min_length=2, max_length=200)
    content_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    purpose: DatasetPurpose
    synthetic: bool
    source_versions: SourceVersions

    @model_validator(mode="after")
    def period_must_be_ordered(self) -> Self:
        if self.period_start > self.period_end:
            msg = "Veri dönemi başlangıcı bitişini aşamaz."
            raise ValueError(msg)
        return self


FeatureValues = Annotated[
    tuple[float, ...],
    BeforeValidator(_tuple_from_list),
    Field(min_length=1, max_length=10_000),
]


class TrainingObservation(ApiModel):
    observed_at: datetime
    label_at: datetime
    values: FeatureValues
    label: int = Field(ge=0, le=1)

    @field_validator("observed_at", "label_at")
    @classmethod
    def timestamps_must_be_utc(cls, value: datetime) -> datetime:
        if value.tzinfo is None or value.utcoffset() != UTC.utcoffset(value):
            msg = "Eğitim zamanları UTC olmalıdır."
            raise ValueError(msg)
        return value

    @field_validator("values")
    @classmethod
    def values_must_be_finite(
        cls,
        values: tuple[float, ...],
    ) -> tuple[float, ...]:
        if any(not math.isfinite(value) for value in values):
            msg = "Model özellikleri sonlu olmalıdır."
            raise ValueError(msg)
        return values

    @model_validator(mode="after")
    def label_must_follow_observation(self) -> Self:
        if self.label_at <= self.observed_at:
            msg = "Etiket zamanı gözlem zamanından sonra olmalıdır."
            raise ValueError(msg)
        return self


FeatureSchema = Annotated[
    tuple[FeatureDefinition, ...],
    BeforeValidator(_tuple_from_list),
    Field(min_length=1, max_length=10_000),
]
Observations = Annotated[
    tuple[TrainingObservation, ...],
    BeforeValidator(_tuple_from_list),
    Field(min_length=3, max_length=100_000_000),
]


class TrainingDataset(ApiModel):
    manifest: DatasetManifest
    features: FeatureSchema
    observations: Observations

    @model_validator(mode="after")
    def schema_must_be_consistent(self) -> Self:
        names = [feature.name for feature in self.features]
        if len(names) != len(set(names)):
            msg = "Model özellik adları benzersiz olmalıdır."
            raise ValueError(msg)
        if any(len(row.values) != len(self.features) for row in self.observations):
            msg = "Her eğitim satırı özellik şemasıyla aynı boyutta olmalıdır."
            raise ValueError(msg)
        return self

    def verify(self, *, content: bytes, for_production: bool) -> None:
        self._verify_manifest(content)
        self._verify_features()
        self._verify_period()
        if for_production and (
            self.manifest.synthetic or self.manifest.purpose is not DatasetPurpose.TRAINING
        ):
            msg = "Sentetik veya test verisi üretime çıkarılamaz."
            raise DatasetNotEligible(msg)

    def _verify_manifest(self, content: bytes) -> None:
        digest = hashlib.sha256(content).hexdigest()
        if digest != self.manifest.content_sha256:
            msg = "Eğitim verisi özeti manifestle eşleşmiyor."
            raise DatasetNotEligible(msg)
        if len(self.observations) != self.manifest.row_count:
            msg = "Eğitim satır sayısı manifestle eşleşmiyor."
            raise DatasetNotEligible(msg)

    def _verify_features(self) -> None:
        leaking = [feature.name for feature in self.features if feature.leaks_future]
        if leaking:
            msg = f"Gelecek bilgisi kullanan özellikler var: {', '.join(leaking)}."
            raise DatasetNotEligible(msg)

    def _verify_period(self) -> None:
        observed_dates = [row.observed_at.date() for row in self.observations]
        if (
            min(observed_dates) != self.manifest.period_start
            or max(observed_dates) != self.manifest.period_end
        ):
            msg = "Eğitim veri dönemi manifestle eşleşmiyor."
            raise DatasetNotEligible(msg)
