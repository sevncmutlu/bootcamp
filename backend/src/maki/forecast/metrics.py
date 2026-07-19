import math
from collections.abc import Sequence


def mae(actual: Sequence[float], predicted: Sequence[float]) -> float:
    _validate_pair(actual, predicted)
    return sum(
        abs(actual_value - predicted_value)
        for actual_value, predicted_value in zip(
            actual,
            predicted,
            strict=True,
        )
    ) / len(actual)


def wape(
    actual: Sequence[float],
    predicted: Sequence[float],
) -> float | None:
    _validate_pair(actual, predicted)
    denominator = sum(abs(value) for value in actual)
    if denominator == 0:
        return None
    return (
        sum(
            abs(actual_value - predicted_value)
            for actual_value, predicted_value in zip(
                actual,
                predicted,
                strict=True,
            )
        )
        / denominator
    )


def mase(
    actual: Sequence[float],
    predicted: Sequence[float],
    *,
    training: Sequence[float],
    seasonality: int,
) -> float | None:
    _validate_pair(actual, predicted)
    _validate_values(training)
    if seasonality <= 0 or len(training) <= seasonality:
        msg = "MASE mevsimselliği eğitim uzunluğundan küçük olmalıdır."
        raise ValueError(msg)
    errors = [
        abs(training[index] - training[index - seasonality])
        for index in range(seasonality, len(training))
    ]
    denominator = sum(errors) / len(errors)
    if denominator == 0:
        return None
    return mae(actual, predicted) / denominator


def interval_coverage(
    *,
    actual: Sequence[float],
    lower: Sequence[float],
    upper: Sequence[float],
) -> float:
    _validate_pair(actual, lower)
    _validate_pair(actual, upper)
    if any(low > high for low, high in zip(lower, upper, strict=True)):
        msg = "Alt tahmin aralığı üst sınırı aşamaz."
        raise ValueError(msg)
    covered = sum(
        low <= value <= high for value, low, high in zip(actual, lower, upper, strict=True)
    )
    return covered / len(actual)


def _validate_pair(
    left: Sequence[float],
    right: Sequence[float],
) -> None:
    if not left or len(left) != len(right):
        msg = "Ölçüm vektörleri boş olamaz ve aynı boyutta olmalıdır."
        raise ValueError(msg)
    _validate_values(left)
    _validate_values(right)


def _validate_values(values: Sequence[float]) -> None:
    if not values or any(not math.isfinite(value) for value in values):
        msg = "Ölçüm vektörü sonlu değerler taşımalıdır."
        raise ValueError(msg)
