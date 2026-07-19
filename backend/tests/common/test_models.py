import re

import pytest
from pydantic import ValidationError

from maki.common.errors import ErrorCode, Problem
from maki.common.ids import new_ulid
from maki.common.models import ApiModel


class Sample(ApiModel):
    count: int


def test_api_model_rejects_coercion_and_unknown_fields() -> None:
    with pytest.raises(ValidationError):
        Sample.model_validate({"count": "1"})

    with pytest.raises(ValidationError):
        Sample.model_validate({"count": 1, "unknown": True})


def test_api_model_is_immutable() -> None:
    sample = Sample(count=1)

    with pytest.raises(ValidationError):
        sample.count = 2


def test_problem_uses_stable_turkish_contract() -> None:
    problem = Problem(
        kod=ErrorCode.VALIDATION_FAILED,
        mesaj="İstek doğrulanamadı.",
        istek_kimligi=new_ulid(),
        tekrar_denenebilir=False,
    )

    assert problem.model_dump(mode="json")["kod"] == "DOGRULAMA_BASARISIZ"
    assert re.fullmatch(r"[0-9A-HJKMNP-TV-Z]{26}", problem.istek_kimligi)


def test_new_ulid_is_unique() -> None:
    identifiers = {new_ulid() for _ in range(1_000)}

    assert len(identifiers) == 1_000
