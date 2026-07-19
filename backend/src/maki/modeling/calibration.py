import math
from enum import StrEnum
from itertools import pairwise
from typing import Annotated, Self

from pydantic import BeforeValidator, Field, model_validator

from maki.common.models import ApiModel

_PLATT_PARAMETER_COUNT = 2
_MINIMUM_BLOCK_COUNT = 2


def _tuple_from_list(value: object) -> object:
    if isinstance(value, list):
        return tuple(value)
    return value


class CalibrationMethod(StrEnum):
    NONE = "none"
    PLATT = "platt"
    ISOTONIC = "isotonic"


CalibrationParameters = Annotated[
    tuple[float, ...],
    BeforeValidator(_tuple_from_list),
    Field(max_length=10_000),
]


class CalibrationModel(ApiModel):
    method: CalibrationMethod
    parameters: CalibrationParameters

    @model_validator(mode="after")
    def parameters_must_match_method(self) -> Self:
        if self.method is CalibrationMethod.NONE and self.parameters:
            msg = "Kalibrasyonsuz model parametre taşıyamaz."
            raise ValueError(msg)
        if (
            self.method is CalibrationMethod.PLATT
            and len(self.parameters) != _PLATT_PARAMETER_COUNT
        ):
            msg = "Platt kalibrasyonu eğim ve sabit terim taşımalıdır."
            raise ValueError(msg)
        if self.method is CalibrationMethod.ISOTONIC:
            _validate_isotonic_parameters(self.parameters)
        if any(not math.isfinite(value) for value in self.parameters):
            msg = "Kalibrasyon parametreleri sonlu olmalıdır."
            raise ValueError(msg)
        return self


def select_calibration(
    *,
    fit_scores: tuple[float, ...],
    fit_labels: tuple[int, ...],
    evaluation_scores: tuple[float, ...],
    evaluation_labels: tuple[int, ...],
) -> CalibrationModel:
    _validate_vectors(fit_scores, fit_labels)
    _validate_vectors(evaluation_scores, evaluation_labels)
    candidates = (
        CalibrationModel(method=CalibrationMethod.NONE, parameters=()),
        fit_platt_calibration(fit_scores, fit_labels),
        _fit_isotonic(fit_scores, fit_labels),
    )
    return min(
        candidates,
        key=lambda model: brier_score(
            evaluation_labels,
            apply_calibration(model, evaluation_scores),
        ),
    )


def apply_calibration(
    model: CalibrationModel,
    raw_scores: tuple[float, ...],
) -> tuple[float, ...]:
    if any(not math.isfinite(value) for value in raw_scores):
        msg = "Kalibrasyon skorları sonlu olmalıdır."
        raise ValueError(msg)
    if model.method is CalibrationMethod.NONE:
        return tuple(_sigmoid(value) for value in raw_scores)
    if model.method is CalibrationMethod.PLATT:
        slope, intercept = model.parameters
        return tuple(_sigmoid(slope * value + intercept) for value in raw_scores)
    pairs = tuple(
        (model.parameters[index], model.parameters[index + 1])
        for index in range(0, len(model.parameters), 2)
    )
    return tuple(_isotonic_probability(value, pairs) for value in raw_scores)


def brier_score(
    labels: tuple[int, ...],
    probabilities: tuple[float, ...],
) -> float:
    _validate_vectors(probabilities, labels)
    if any(not 0 <= value <= 1 for value in probabilities):
        msg = "Olasılıklar sıfır ile bir arasında olmalıdır."
        raise ValueError(msg)
    return sum(
        (probability - label) ** 2 for probability, label in zip(probabilities, labels, strict=True)
    ) / len(labels)


def fit_platt_calibration(
    scores: tuple[float, ...],
    labels: tuple[int, ...],
) -> CalibrationModel:
    _validate_vectors(scores, labels)
    slope = 1.0
    intercept = 0.0
    learning_rate = 0.05
    for _ in range(2_000):
        probabilities = tuple(_sigmoid(slope * score + intercept) for score in scores)
        slope_gradient = sum(
            (probability - label) * score
            for score, label, probability in zip(
                scores,
                labels,
                probabilities,
                strict=True,
            )
        ) / len(scores)
        intercept_gradient = sum(
            probability - label for label, probability in zip(labels, probabilities, strict=True)
        ) / len(scores)
        slope -= learning_rate * slope_gradient
        intercept -= learning_rate * intercept_gradient
    return CalibrationModel(
        method=CalibrationMethod.PLATT,
        parameters=(slope, intercept),
    )


def _fit_isotonic(
    scores: tuple[float, ...],
    labels: tuple[int, ...],
) -> CalibrationModel:
    ordered = sorted(zip(scores, labels, strict=True))
    blocks: list[list[float]] = []
    for score, label in ordered:
        if blocks and blocks[-1][0] == score:
            blocks[-1][1] += label
            blocks[-1][2] += 1
        else:
            blocks.append([score, float(label), 1.0])
        while len(blocks) >= _MINIMUM_BLOCK_COUNT and _block_mean(blocks[-2]) > _block_mean(
            blocks[-1]
        ):
            right = blocks.pop()
            left = blocks.pop()
            blocks.append(
                [
                    right[0],
                    left[1] + right[1],
                    left[2] + right[2],
                ]
            )
    parameters = tuple(value for block in blocks for value in (block[0], _block_mean(block)))
    return CalibrationModel(
        method=CalibrationMethod.ISOTONIC,
        parameters=parameters,
    )


def _block_mean(block: list[float]) -> float:
    return block[1] / block[2]


def _isotonic_probability(
    score: float,
    pairs: tuple[tuple[float, float], ...],
) -> float:
    for boundary, probability in pairs:
        if score <= boundary:
            return probability
    return pairs[-1][1]


def _sigmoid(value: float) -> float:
    if value >= 0:
        return 1 / (1 + math.exp(-min(value, 700)))
    exponential = math.exp(max(value, -700))
    return exponential / (1 + exponential)


def _validate_vectors(
    values: tuple[float, ...],
    labels: tuple[int, ...],
) -> None:
    if not values or len(values) != len(labels):
        msg = "Kalibrasyon vektörleri boş olamaz ve aynı boyutta olmalıdır."
        raise ValueError(msg)
    if any(not math.isfinite(value) for value in values):
        msg = "Kalibrasyon vektörü sonlu olmalıdır."
        raise ValueError(msg)
    if any(label not in {0, 1} for label in labels):
        msg = "Kalibrasyon etiketleri ikili olmalıdır."
        raise ValueError(msg)


def _validate_isotonic_parameters(parameters: tuple[float, ...]) -> None:
    if len(parameters) < _PLATT_PARAMETER_COUNT or len(parameters) % _PLATT_PARAMETER_COUNT != 0:
        msg = "Isotonic kalibrasyon sınır ve olasılık çiftleri taşımalıdır."
        raise ValueError(msg)
    boundaries = parameters[::2]
    probabilities = parameters[1::2]
    if any(left >= right for left, right in pairwise(boundaries)):
        msg = "Isotonic kalibrasyon sınırları artan olmalıdır."
        raise ValueError(msg)
    if any(not 0 <= value <= 1 for value in probabilities):
        msg = "Isotonic olasılıkları sıfır ile bir arasında olmalıdır."
        raise ValueError(msg)
