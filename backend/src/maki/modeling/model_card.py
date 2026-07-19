import math
from collections import defaultdict
from collections.abc import Sequence
from datetime import date, datetime
from enum import StrEnum
from typing import Annotated

from pydantic import BeforeValidator, Field, model_validator

from maki.common.models import ApiModel
from maki.modeling.calibration import fit_platt_calibration


def _tuple_from_list(value: object) -> object:
    if isinstance(value, list):
        return tuple(value)
    return value


class PromotionDecision(StrEnum):
    APPROVED = "approved"
    REJECTED = "rejected"
    TEST_ONLY = "test_only"


class ModelMetrics(ApiModel):
    roc_auc: float = Field(ge=0, le=1)
    brier: float = Field(ge=0, le=1)
    log_loss: float = Field(ge=0)
    calibration_slope: float
    base_rate: float = Field(ge=0, le=1)
    temporal_stability: float = Field(ge=0, le=1)
    sample_count: int = Field(ge=1)

    @model_validator(mode="after")
    def values_must_be_finite(self) -> "ModelMetrics":
        values = (
            self.roc_auc,
            self.brier,
            self.log_loss,
            self.calibration_slope,
            self.base_rate,
            self.temporal_stability,
        )
        if any(not math.isfinite(value) for value in values):
            msg = "Model ölçümleri sonlu olmalıdır."
            raise ValueError(msg)
        return self


class CostMatrix(ApiModel):
    false_positive: float = Field(gt=0)
    false_negative: float = Field(gt=0)

    @property
    def decision_threshold(self) -> float:
        return self.false_positive / (self.false_positive + self.false_negative)


Limitations = Annotated[
    tuple[str, ...],
    BeforeValidator(_tuple_from_list),
    Field(min_length=1, max_length=20),
]


class ModelCard(ApiModel):
    model_version: str = Field(min_length=1, max_length=128)
    created_at: datetime
    training_period_start: date
    training_period_end: date
    dataset_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    feature_version: str = Field(min_length=1, max_length=64)
    validation: ModelMetrics
    holdout: ModelMetrics
    cost_matrix: CostMatrix
    decision_threshold: float = Field(ge=0, le=1)
    promotion: PromotionDecision
    limitations: Limitations


Reasons = Annotated[
    tuple[str, ...],
    BeforeValidator(_tuple_from_list),
    Field(max_length=20),
]


class PromotionAssessment(ApiModel):
    decision: PromotionDecision
    reasons: Reasons


class PromotionGate:
    def __init__(
        self,
        *,
        minimum_auc: float = 0.65,
        minimum_calibration_slope: float = 0.5,
        maximum_calibration_slope: float = 1.5,
        maximum_temporal_stability: float = 0.15,
        minimum_samples: int = 30,
    ) -> None:
        self._minimum_auc = minimum_auc
        self._minimum_slope = minimum_calibration_slope
        self._maximum_slope = maximum_calibration_slope
        self._maximum_stability = maximum_temporal_stability
        self._minimum_samples = minimum_samples

    def assess(
        self,
        *,
        validation: ModelMetrics,
        holdout: ModelMetrics,
    ) -> PromotionAssessment:
        reasons: list[str] = []
        for name, metrics in (("Doğrulama", validation), ("Holdout", holdout)):
            reasons.extend(self._metric_rejections(name, metrics))
        return PromotionAssessment(
            decision=(PromotionDecision.REJECTED if reasons else PromotionDecision.APPROVED),
            reasons=tuple(reasons),
        )

    def _metric_rejections(
        self,
        name: str,
        metrics: ModelMetrics,
    ) -> list[str]:
        reasons: list[str] = []
        baseline_brier = metrics.base_rate * (1 - metrics.base_rate)
        baseline_log_loss = _binary_entropy(metrics.base_rate)
        if metrics.roc_auc < self._minimum_auc:
            reasons.append(f"{name} ROC-AUC alt sınırı geçemedi.")
        if metrics.brier >= baseline_brier:
            reasons.append(f"{name} Brier skoru taban modeli geçemedi.")
        if metrics.log_loss >= baseline_log_loss:
            reasons.append(f"{name} log loss taban modeli geçemedi.")
        if not self._minimum_slope <= metrics.calibration_slope <= self._maximum_slope:
            reasons.append(f"{name} kalibrasyon eğimi kabul aralığında değil.")
        if metrics.temporal_stability > self._maximum_stability:
            reasons.append(f"{name} dönemsel kararlılık sınırını aştı.")
        if metrics.sample_count < self._minimum_samples:
            reasons.append(f"{name} örnek sayısı yetersiz.")
        return reasons


def _binary_entropy(probability: float) -> float:
    if probability in {0.0, 1.0}:
        return 0.0
    return -probability * math.log(probability) - (1 - probability) * math.log(1 - probability)


def evaluate_binary_model(
    *,
    labels: tuple[int, ...],
    probabilities: tuple[float, ...],
    periods: tuple[datetime, ...],
) -> ModelMetrics:
    _validate_evaluation_vectors(labels, probabilities, periods)
    clipped = tuple(min(max(value, 1e-15), 1 - 1e-15) for value in probabilities)
    logits = tuple(math.log(value / (1 - value)) for value in clipped)
    calibration = fit_platt_calibration(logits, labels)
    return ModelMetrics(
        roc_auc=_roc_auc(labels, probabilities),
        brier=sum(
            (probability - label) ** 2
            for probability, label in zip(probabilities, labels, strict=True)
        )
        / len(labels),
        log_loss=-sum(
            label * math.log(probability) + (1 - label) * math.log(1 - probability)
            for label, probability in zip(labels, clipped, strict=True)
        )
        / len(labels),
        calibration_slope=calibration.parameters[0],
        base_rate=sum(labels) / len(labels),
        temporal_stability=_temporal_stability(labels, probabilities, periods),
        sample_count=len(labels),
    )


def _roc_auc(
    labels: tuple[int, ...],
    probabilities: tuple[float, ...],
) -> float:
    positive_count = sum(labels)
    negative_count = len(labels) - positive_count
    if positive_count == 0 or negative_count == 0:
        msg = "ROC-AUC için iki etiket sınıfı da bulunmalıdır."
        raise ValueError(msg)
    ranked = sorted(zip(probabilities, labels, strict=True))
    rank_sum = 0.0
    index = 0
    while index < len(ranked):
        end = index + 1
        while end < len(ranked) and ranked[end][0] == ranked[index][0]:
            end += 1
        average_rank = (index + 1 + end) / 2
        rank_sum += average_rank * sum(label for _, label in ranked[index:end])
        index = end
    return (rank_sum - positive_count * (positive_count + 1) / 2) / (
        positive_count * negative_count
    )


def _temporal_stability(
    labels: tuple[int, ...],
    probabilities: tuple[float, ...],
    periods: tuple[datetime, ...],
) -> float:
    buckets: defaultdict[tuple[int, int], list[float]] = defaultdict(list)
    for label, probability, period in zip(
        labels,
        probabilities,
        periods,
        strict=True,
    ):
        buckets[(period.year, period.month)].append((probability - label) ** 2)
    scores = [sum(values) / len(values) for values in buckets.values()]
    return max(scores) - min(scores) if len(scores) > 1 else 0.0


def _validate_evaluation_vectors(
    labels: Sequence[int],
    probabilities: Sequence[float],
    periods: Sequence[datetime],
) -> None:
    if not labels or not (len(labels) == len(probabilities) == len(periods)):
        msg = "Model ölçüm vektörleri boş olamaz ve aynı boyutta olmalıdır."
        raise ValueError(msg)
    if any(label not in {0, 1} for label in labels):
        msg = "Model ölçüm etiketleri ikili olmalıdır."
        raise ValueError(msg)
    if any(not math.isfinite(value) or not 0 <= value <= 1 for value in probabilities):
        msg = "Model olasılıkları sonlu ve sıfır ile bir arasında olmalıdır."
        raise ValueError(msg)


def render_model_card(card: ModelCard) -> str:
    return "\n".join(
        (
            "# Model Kartı",
            "",
            f"- Model sürümü: {card.model_version}",
            f"- Özellik sürümü: {card.feature_version}",
            f"- Eğitim dönemi: {card.training_period_start} / {card.training_period_end}",
            f"- Veri özeti: `{card.dataset_sha256}`",
            f"- Terfi kararı: {card.promotion.value}",
            f"- Karar eşiği: {card.decision_threshold:.4f}",
            "",
            "## Doğrulama",
            "",
            _metrics_line(card.validation),
            "",
            "## Holdout",
            "",
            _metrics_line(card.holdout),
            "",
            "ROC-AUC tek başına kabul ölçütü değildir.",
            "",
            "## Sınırlamalar",
            "",
            *(f"- {item}" for item in card.limitations),
            "",
        )
    )


def _metrics_line(metrics: ModelMetrics) -> str:
    return (
        f"ROC-AUC {metrics.roc_auc:.4f}; Brier {metrics.brier:.4f}; "
        f"log loss {metrics.log_loss:.4f}; kalibrasyon eğimi "
        f"{metrics.calibration_slope:.4f}; taban oranı "
        f"{metrics.base_rate:.4f}; dönemsel oynaklık "
        f"{metrics.temporal_stability:.4f}; örnek {metrics.sample_count}."
    )
