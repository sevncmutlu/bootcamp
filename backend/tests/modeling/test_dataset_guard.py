import hashlib
from datetime import UTC, date, datetime

import pytest

from maki.modeling.dataset import (
    DatasetManifest,
    DatasetNotEligible,
    DatasetPurpose,
    TrainingDataset,
    TrainingObservation,
)
from maki.modeling.features import FeatureDefinition

_CONTENT = b"onayli-egitim-verisi"


def test_synthetic_or_test_dataset_cannot_be_promoted() -> None:
    for purpose, synthetic in (
        (DatasetPurpose.TEST, False),
        (DatasetPurpose.TRAINING, True),
    ):
        dataset = _dataset(purpose=purpose, synthetic=synthetic)

        with pytest.raises(DatasetNotEligible):
            dataset.verify(content=_CONTENT, for_production=True)


def test_dataset_digest_and_future_feature_window_are_rejected() -> None:
    bad_digest = _dataset().model_copy(
        update={
            "manifest": _manifest().model_copy(
                update={"content_sha256": "0" * 64},
            )
        }
    )
    future_feature = _dataset().model_copy(
        update={
            "features": (
                FeatureDefinition(
                    name="gelecek_gecikme",
                    window_start_days=-7,
                    window_end_days=1,
                ),
            )
        }
    )

    with pytest.raises(DatasetNotEligible, match="özeti"):
        bad_digest.verify(content=_CONTENT, for_production=False)
    with pytest.raises(DatasetNotEligible, match="gelecek"):
        future_feature.verify(content=_CONTENT, for_production=False)


def _dataset(
    *,
    purpose: DatasetPurpose = DatasetPurpose.TRAINING,
    synthetic: bool = False,
) -> TrainingDataset:
    return TrainingDataset(
        manifest=_manifest(purpose=purpose, synthetic=synthetic),
        features=(
            FeatureDefinition(
                name="borc_orani",
                window_start_days=-30,
                window_end_days=0,
            ),
        ),
        observations=(
            TrainingObservation(
                observed_at=datetime(2026, 1, 1, tzinfo=UTC),
                label_at=datetime(2026, 2, 1, tzinfo=UTC),
                values=(0.4,),
                label=0,
            ),
            TrainingObservation(
                observed_at=datetime(2026, 1, 2, tzinfo=UTC),
                label_at=datetime(2026, 2, 2, tzinfo=UTC),
                values=(0.8,),
                label=1,
            ),
            TrainingObservation(
                observed_at=datetime(2026, 1, 3, tzinfo=UTC),
                label_at=datetime(2026, 2, 3, tzinfo=UTC),
                values=(0.2,),
                label=0,
            ),
        ),
    )


def _manifest(
    *,
    purpose: DatasetPurpose = DatasetPurpose.TRAINING,
    synthetic: bool = False,
) -> DatasetManifest:
    return DatasetManifest(
        owner="Maki risk ekibi",
        period_start=date(2026, 1, 1),
        period_end=date(2026, 1, 3),
        row_count=3,
        feature_version="debt-v1",
        label_definition="30 gün içinde gecikme",
        license="Kurum içi kullanım",
        content_sha256=hashlib.sha256(_CONTENT).hexdigest(),
        purpose=purpose,
        synthetic=synthetic,
        source_versions=("tahsilat-2026-01",),
    )
