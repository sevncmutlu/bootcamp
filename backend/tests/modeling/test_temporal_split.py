from datetime import UTC, datetime, timedelta

from maki.modeling.dataset import TrainingObservation
from maki.modeling.training import temporal_split


def test_temporal_split_keeps_equal_periods_together_and_orders_holdout() -> None:
    start = datetime(2026, 1, 1, tzinfo=UTC)
    rows = tuple(
        TrainingObservation(
            observed_at=start + timedelta(days=day // 2),
            label_at=start + timedelta(days=day // 2 + 30),
            values=(float(day),),
            label=day % 2,
        )
        for day in range(30)
    )

    split = temporal_split(
        rows,
        validation_fraction=0.2,
        holdout_fraction=0.2,
    )

    assert max(row.observed_at for row in split.training) < min(
        row.observed_at for row in split.validation
    )
    assert max(row.observed_at for row in split.validation) < min(
        row.observed_at for row in split.holdout
    )
    assert len(split.training) + len(split.validation) + len(split.holdout) == 30
