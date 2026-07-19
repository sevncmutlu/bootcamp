from datetime import UTC, date, datetime

from maki.modeling.model_card import (
    CostMatrix,
    ModelCard,
    ModelMetrics,
    PromotionDecision,
    render_model_card,
)


def test_cost_matrix_sets_threshold_and_card_is_turkish() -> None:
    costs = CostMatrix(false_positive=1.0, false_negative=4.0)
    card = ModelCard(
        model_version="debt-2026-01",
        created_at=datetime(2026, 2, 1, tzinfo=UTC),
        training_period_start=date(2025, 1, 1),
        training_period_end=date(2025, 12, 31),
        dataset_sha256="a" * 64,
        feature_version="debt-v1",
        validation=_metrics(),
        holdout=_metrics(),
        cost_matrix=costs,
        decision_threshold=costs.decision_threshold,
        promotion=PromotionDecision.APPROVED,
        limitations=("Yeni kullanıcılar için veri az olabilir.",),
    )

    text = render_model_card(card)

    assert costs.decision_threshold == 0.2
    assert "# Model Kartı" in text
    assert "Sınırlamalar" in text
    assert "ROC-AUC tek başına kabul ölçütü değildir." in text
    assert "0.2000" in text


def _metrics() -> ModelMetrics:
    return ModelMetrics(
        roc_auc=0.81,
        brier=0.12,
        log_loss=0.38,
        calibration_slope=0.97,
        base_rate=0.22,
        temporal_stability=0.04,
        sample_count=100,
    )
