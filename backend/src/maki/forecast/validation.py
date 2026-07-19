from maki.forecast.models import (
    BacktestSplit,
    RelativeSeries,
)


def rolling_origin_splits(
    series: RelativeSeries,
    *,
    initial_training_days: int = 42,
    horizon: int = 7,
    step: int = 7,
) -> tuple[BacktestSplit, ...]:
    if initial_training_days <= 0 or horizon <= 0 or step <= 0:
        msg = "Backtest kesim değerleri sıfırdan büyük olmalıdır."
        raise ValueError(msg)
    splits: list[BacktestSplit] = []
    for origin in range(
        initial_training_days,
        len(series.points) - horizon + 1,
        step,
    ):
        training = series.window(0, origin)
        test = series.window(origin, origin + horizon)
        if training.points[-1].day >= test.points[0].day:
            msg = "Backtest eğitim ve test dönemleri çakışıyor."
            raise RuntimeError(msg)
        splits.append(
            BacktestSplit(
                training=training,
                test=test,
                origin_day=origin,
            )
        )
    return tuple(splits)
