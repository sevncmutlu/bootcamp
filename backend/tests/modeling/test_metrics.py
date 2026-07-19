from datetime import UTC, datetime

from maki.modeling.model_card import (
    ModelMetrics,
    PromotionDecision,
    PromotionGate,
    evaluate_binary_model,
)


def test_binary_metrics_include_discrimination_calibration_and_stability() -> None:
    metrics = evaluate_binary_model(
        labels=(0, 0, 1, 1),
        probabilities=(0.1, 0.4, 0.35, 0.8),
        periods=(
            datetime(2026, 1, 1, tzinfo=UTC),
            datetime(2026, 1, 2, tzinfo=UTC),
            datetime(2026, 2, 1, tzinfo=UTC),
            datetime(2026, 2, 2, tzinfo=UTC),
        ),
    )

    assert metrics.roc_auc == 0.75
    assert abs(metrics.brier - 0.158125) < 1e-12
    assert metrics.base_rate == 0.5
    assert metrics.temporal_stability >= 0


def test_auc_alone_cannot_pass_promotion_gate() -> None:
    bad_calibration = ModelMetrics(
        roc_auc=0.9,
        brier=0.3,
        log_loss=0.9,
        calibration_slope=0.2,
        base_rate=0.2,
        temporal_stability=0.02,
        sample_count=100,
    )

    assessment = PromotionGate().assess(
        validation=bad_calibration,
        holdout=bad_calibration,
    )

    assert assessment.decision is PromotionDecision.REJECTED
    assert any("Brier" in reason for reason in assessment.reasons)
    assert any("kalibrasyon" in reason for reason in assessment.reasons)
