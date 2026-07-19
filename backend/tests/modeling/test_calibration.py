import pytest

from maki.modeling.calibration import (
    CalibrationMethod,
    apply_calibration,
    brier_score,
    select_calibration,
)


def test_calibration_is_selected_on_separate_evaluation_period() -> None:
    fit_scores = (-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0)
    fit_labels = (0, 0, 0, 0, 0, 0, 1, 1)
    evaluation_scores = (-2.5, -1.5, 0.5, 1.5, 2.5, 3.5)
    evaluation_labels = (0, 0, 0, 0, 1, 1)

    selected = select_calibration(
        fit_scores=fit_scores,
        fit_labels=fit_labels,
        evaluation_scores=evaluation_scores,
        evaluation_labels=evaluation_labels,
    )
    probabilities = apply_calibration(selected, evaluation_scores)
    identity = apply_calibration(
        selected.model_copy(
            update={
                "method": CalibrationMethod.NONE,
                "parameters": (),
            }
        ),
        evaluation_scores,
    )

    assert all(0 <= value <= 1 for value in probabilities)
    assert brier_score(evaluation_labels, probabilities) <= brier_score(
        evaluation_labels,
        identity,
    )


def test_calibration_rejects_non_binary_or_mismatched_vectors() -> None:
    with pytest.raises(ValueError, match="ikili"):
        select_calibration(
            fit_scores=(1.0,),
            fit_labels=(2,),
            evaluation_scores=(1.0,),
            evaluation_labels=(1,),
        )
