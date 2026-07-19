from datetime import UTC, datetime, timedelta

from maki.modeling.dataset import TrainingObservation
from maki.modeling.training import (
    LightGbmTrainingConfig,
    train_lightgbm,
)


def test_lightgbm_training_is_temporal_and_reproducible() -> None:
    start = datetime(2025, 1, 1, tzinfo=UTC)
    rows = tuple(
        TrainingObservation(
            observed_at=start + timedelta(days=day),
            label_at=start + timedelta(days=day + 30),
            values=(
                (day % 17) / 17,
                ((day * 7) % 19) / 19,
            ),
            label=int((day % 17) / 17 + ((day * 7) % 19) / 38 > 0.7),
        )
        for day in range(120)
    )
    config = LightGbmTrainingConfig(
        seed=42,
        num_boost_round=12,
        num_leaves=7,
        minimum_leaf_rows=5,
    )

    first = train_lightgbm(
        observations=rows,
        feature_names=("borc_orani", "oynaklik"),
        config=config,
    )
    second = train_lightgbm(
        observations=rows,
        feature_names=("borc_orani", "oynaklik"),
        config=config,
    )

    assert first.booster.dump_model() == second.booster.dump_model()
    assert first.calibration == second.calibration
    assert first.holdout_metrics.sample_count > 0
    assert first.holdout_metrics.roc_auc >= 0.5
