import pytest
from pydantic import TypeAdapter, ValidationError

from maki.jobs.results import CoachJobResult, JobResult


def test_job_result_discriminator_rejects_fields_from_another_kind() -> None:
    adapter = TypeAdapter(JobResult)

    with pytest.raises(ValidationError):
        adapter.validate_python(
            {
                "kind": "coach",
                "schema_version": 1,
                "answer": {
                    "answer": None,
                    "safety": "insufficient_sources",
                    "sources": [],
                },
                "forecast": {"model_name": "prophet"},
            }
        )


def test_coach_result_round_trip_is_strict() -> None:
    result = CoachJobResult.model_validate_json(
        """
        {
          "kind": "coach",
          "schema_version": 1,
          "answer": {
            "answer": null,
            "safety": "insufficient_sources",
            "sources": []
          }
        }
        """
    )

    assert TypeAdapter(JobResult).validate_json(result.model_dump_json()) == result
