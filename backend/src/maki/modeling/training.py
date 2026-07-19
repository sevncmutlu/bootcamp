from __future__ import annotations

from dataclasses import dataclass
from importlib import import_module
from typing import TYPE_CHECKING, Annotated, Any, Protocol

import numpy as np
from pydantic import BeforeValidator, Field

from maki.common.models import ApiModel
from maki.modeling.calibration import (
    CalibrationModel,
    apply_calibration,
    select_calibration,
)
from maki.modeling.dataset import TrainingObservation
from maki.modeling.model_card import ModelMetrics, evaluate_binary_model

if TYPE_CHECKING:
    from datetime import datetime

_MINIMUM_SPLIT_PERIODS = 3
_MINIMUM_CALIBRATION_PERIODS = 2


def _tuple_from_list(value: object) -> object:
    if isinstance(value, list):
        return tuple(value)
    return value


ObservationGroup = Annotated[
    tuple[TrainingObservation, ...],
    BeforeValidator(_tuple_from_list),
    Field(min_length=1),
]


class TemporalSplit(ApiModel):
    training: ObservationGroup
    validation: ObservationGroup
    holdout: ObservationGroup


class LightGbmTrainingConfig(ApiModel):
    seed: int = Field(ge=0, le=2_147_483_647)
    num_boost_round: int = Field(ge=1, le=10_000)
    num_leaves: int = Field(ge=2, le=256)
    minimum_leaf_rows: int = Field(ge=2, le=100_000)
    learning_rate: float = Field(default=0.05, gt=0, le=1)


class TrainedBooster(Protocol):
    def dump_model(self) -> dict[str, Any]: ...

    def predict(
        self,
        data: np.ndarray[Any, np.dtype[np.float64]],
        *,
        raw_score: bool = False,
    ) -> object: ...


@dataclass(frozen=True)
class LightGbmTrainingRun:
    booster: TrainedBooster
    calibration: CalibrationModel
    validation_metrics: ModelMetrics
    holdout_metrics: ModelMetrics
    trained_until: datetime


def temporal_split(
    observations: tuple[TrainingObservation, ...],
    *,
    validation_fraction: float = 0.2,
    holdout_fraction: float = 0.2,
) -> TemporalSplit:
    if (
        not 0 < validation_fraction < 1
        or not 0 < holdout_fraction < 1
        or validation_fraction + holdout_fraction >= 1
    ):
        msg = "Doğrulama ve holdout oranları geçersiz."
        raise ValueError(msg)
    periods = sorted({row.observed_at for row in observations})
    if len(periods) < _MINIMUM_SPLIT_PERIODS:
        msg = "Zamansal bölme için en az üç ayrı dönem gerekir."
        raise ValueError(msg)

    holdout_periods = max(1, round(len(periods) * holdout_fraction))
    validation_periods = max(1, round(len(periods) * validation_fraction))
    training_periods = len(periods) - holdout_periods - validation_periods
    if training_periods < 1:
        msg = "Zamansal bölmede eğitim dönemi kalmadı."
        raise ValueError(msg)

    training_end = periods[training_periods - 1]
    validation_end = periods[training_periods + validation_periods - 1]
    ordered = sorted(observations, key=lambda row: row.observed_at)
    return TemporalSplit(
        training=tuple(row for row in ordered if row.observed_at <= training_end),
        validation=tuple(
            row for row in ordered if training_end < row.observed_at <= validation_end
        ),
        holdout=tuple(row for row in ordered if row.observed_at > validation_end),
    )


def train_lightgbm(
    *,
    observations: tuple[TrainingObservation, ...],
    feature_names: tuple[str, ...],
    config: LightGbmTrainingConfig,
) -> LightGbmTrainingRun:
    if not feature_names or any(len(row.values) != len(feature_names) for row in observations):
        msg = "LightGBM özellik şeması eğitim verisiyle uyuşmuyor."
        raise ValueError(msg)
    split = temporal_split(observations)
    calibration_fit, calibration_evaluation = _split_validation(split.validation)
    booster = _fit_booster(split.training, feature_names, config)
    fit_scores = _raw_scores(booster, calibration_fit)
    evaluation_scores = _raw_scores(booster, calibration_evaluation)
    calibration = select_calibration(
        fit_scores=fit_scores,
        fit_labels=_labels(calibration_fit),
        evaluation_scores=evaluation_scores,
        evaluation_labels=_labels(calibration_evaluation),
    )
    validation_probabilities = apply_calibration(calibration, evaluation_scores)
    holdout_scores = _raw_scores(booster, split.holdout)
    holdout_probabilities = apply_calibration(calibration, holdout_scores)
    return LightGbmTrainingRun(
        booster=booster,
        calibration=calibration,
        validation_metrics=_evaluate(
            calibration_evaluation,
            validation_probabilities,
        ),
        holdout_metrics=_evaluate(split.holdout, holdout_probabilities),
        trained_until=max(row.observed_at for row in split.training),
    )


def _fit_booster(
    observations: tuple[TrainingObservation, ...],
    feature_names: tuple[str, ...],
    config: LightGbmTrainingConfig,
) -> TrainedBooster:
    lightgbm: Any = import_module("lightgbm")
    dataset = lightgbm.Dataset(
        _matrix(observations),
        label=np.asarray(_labels(observations), dtype=np.int8),
        feature_name=list(feature_names),
        free_raw_data=True,
    )
    parameters = {
        "objective": "binary",
        "metric": "binary_logloss",
        "verbosity": -1,
        "seed": config.seed,
        "data_random_seed": config.seed,
        "feature_fraction_seed": config.seed,
        "bagging_seed": config.seed,
        "drop_seed": config.seed,
        "deterministic": True,
        "force_col_wise": True,
        "num_threads": 1,
        "num_leaves": config.num_leaves,
        "min_data_in_leaf": config.minimum_leaf_rows,
        "learning_rate": config.learning_rate,
    }
    booster: TrainedBooster = lightgbm.train(
        parameters,
        dataset,
        num_boost_round=config.num_boost_round,
    )
    return booster


def _split_validation(
    observations: tuple[TrainingObservation, ...],
) -> tuple[
    tuple[TrainingObservation, ...],
    tuple[TrainingObservation, ...],
]:
    periods = sorted({row.observed_at for row in observations})
    if len(periods) < _MINIMUM_CALIBRATION_PERIODS:
        msg = "Kalibrasyon için en az iki doğrulama dönemi gerekir."
        raise ValueError(msg)
    boundary = periods[len(periods) // 2 - 1]
    fit = tuple(row for row in observations if row.observed_at <= boundary)
    evaluation = tuple(row for row in observations if row.observed_at > boundary)
    return fit, evaluation


def _matrix(
    observations: tuple[TrainingObservation, ...],
) -> np.ndarray[Any, np.dtype[np.float64]]:
    return np.asarray(
        [row.values for row in observations],
        dtype=np.float64,
    )


def _labels(
    observations: tuple[TrainingObservation, ...],
) -> tuple[int, ...]:
    return tuple(row.label for row in observations)


def _raw_scores(
    booster: TrainedBooster,
    observations: tuple[TrainingObservation, ...],
) -> tuple[float, ...]:
    values = np.asarray(
        booster.predict(_matrix(observations), raw_score=True),
        dtype=np.float64,
    )
    return tuple(float(value) for value in values)


def _evaluate(
    observations: tuple[TrainingObservation, ...],
    probabilities: tuple[float, ...],
) -> ModelMetrics:
    return evaluate_binary_model(
        labels=_labels(observations),
        probabilities=probabilities,
        periods=tuple(row.observed_at for row in observations),
    )
