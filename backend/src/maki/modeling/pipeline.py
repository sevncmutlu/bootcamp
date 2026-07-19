from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from typing import TYPE_CHECKING

from pydantic import Field

from maki.common.models import ApiModel
from maki.modeling.export import (
    ExportedModel,
    ModelExporter,
    ModelExportSettings,
)
from maki.modeling.model_card import (
    CostMatrix,
    Limitations,
    ModelCard,
    PromotionDecision,
    PromotionGate,
    render_model_card,
)
from maki.modeling.training import (
    LightGbmTrainingConfig,
    train_lightgbm,
)

if TYPE_CHECKING:
    from collections.abc import Callable

    from cryptography.hazmat.primitives.asymmetric.ed25519 import (
        Ed25519PrivateKey,
    )

    from maki.modeling.dataset import TrainingDataset


class ModelPromotionRejected(RuntimeError):  # noqa: N818
    pass


class TrainingPipelineSettings(ApiModel):
    model_version: str = Field(min_length=1, max_length=128)
    production: bool
    training: LightGbmTrainingConfig
    costs: CostMatrix
    limitations: Limitations


@dataclass(frozen=True)
class TrainingArtifacts:
    model: ExportedModel
    card: ModelCard
    card_markdown: str


class ModelTrainingPipeline:
    def __init__(
        self,
        *,
        clock: Callable[[], datetime] | None = None,
        gate: PromotionGate | None = None,
        exporter: ModelExporter | None = None,
    ) -> None:
        self._clock = clock or (lambda: datetime.now(UTC))
        self._gate = gate or PromotionGate()
        self._exporter = exporter or ModelExporter()

    def run(
        self,
        *,
        dataset: TrainingDataset,
        source_content: bytes,
        settings: TrainingPipelineSettings,
        signing_key: Ed25519PrivateKey | None,
    ) -> TrainingArtifacts:
        dataset.verify(
            content=source_content,
            for_production=settings.production,
        )
        training_run = train_lightgbm(
            observations=dataset.observations,
            feature_names=tuple(feature.name for feature in dataset.features),
            config=settings.training,
        )
        assessment = self._gate.assess(
            validation=training_run.validation_metrics,
            holdout=training_run.holdout_metrics,
        )
        if settings.production and assessment.decision is PromotionDecision.REJECTED:
            details = " ".join(assessment.reasons)
            msg = f"Model üretim kabul kapısını geçemedi. {details}"
            raise ModelPromotionRejected(msg)
        promotion = assessment.decision if settings.production else PromotionDecision.TEST_ONLY
        threshold = settings.costs.decision_threshold
        card = ModelCard(
            model_version=settings.model_version,
            created_at=self._clock(),
            training_period_start=dataset.manifest.period_start,
            training_period_end=dataset.manifest.period_end,
            dataset_sha256=dataset.manifest.content_sha256,
            feature_version=dataset.manifest.feature_version,
            validation=training_run.validation_metrics,
            holdout=training_run.holdout_metrics,
            cost_matrix=settings.costs,
            decision_threshold=threshold,
            promotion=promotion,
            limitations=settings.limitations,
        )
        model = self._exporter.export(
            booster=training_run.booster,
            settings=ModelExportSettings(
                feature_names=tuple(feature.name for feature in dataset.features),
                model_version=settings.model_version,
                trained_until=training_run.trained_until,
                dataset_sha256=dataset.manifest.content_sha256,
                calibration=training_run.calibration,
                decision_threshold=threshold,
                production=settings.production,
            ),
            signing_key=signing_key,
        )
        return TrainingArtifacts(
            model=model,
            card=card,
            card_markdown=render_model_card(card),
        )
