from unittest.mock import AsyncMock

from maki.infrastructure.redis_job_results import RedisJobResultRepository
from maki.jobs.models import JobKind
from maki.jobs.results import CoachJobResult, ReceiptJobResult


async def test_coach_result_uses_seven_day_ttl_and_is_reusable() -> None:
    redis = AsyncMock()
    result = _coach_result()
    redis.get.return_value = result.model_dump_json().encode()
    repository = RedisJobResultRepository(redis)

    await repository.put("01K00000000000000000000000", result)
    loaded = await repository.get(
        "01K00000000000000000000000",
        JobKind.COACH,
    )

    redis.set.assert_awaited_once()
    assert redis.set.await_args.kwargs["ex"] == 7 * 24 * 60 * 60
    redis.get.assert_awaited_once()
    redis.getdel.assert_not_awaited()
    assert loaded == result


async def test_receipt_result_expires_quickly_and_is_consumed_once() -> None:
    redis = AsyncMock()
    result = _receipt_result()
    redis.getdel.return_value = result.model_dump_json().encode()
    repository = RedisJobResultRepository(redis)

    await repository.put("01K00000000000000000000000", result)
    loaded = await repository.get(
        "01K00000000000000000000000",
        JobKind.RECEIPT,
    )

    assert redis.set.await_args.kwargs["ex"] == 600
    redis.getdel.assert_awaited_once()
    assert loaded == result


def _coach_result() -> CoachJobResult:
    return CoachJobResult.model_validate_json(
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


def _receipt_result() -> ReceiptJobResult:
    return ReceiptJobResult.model_validate_json(
        """
        {
          "kind": "receipt",
          "schema_version": 1,
          "receipt": {
            "merchant_name": null,
            "items": [],
            "subtotal_minor": null,
            "tax_minor": 0,
            "discount_minor": 0,
            "total_minor": null,
            "field_confidences": [],
            "requires_review": true
          }
        }
        """
    )
