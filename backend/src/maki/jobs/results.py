from typing import Annotated, Literal

from pydantic import Field

from maki.coach.models import CoachAnswer
from maki.common.models import ApiModel
from maki.forecast.service import ForecastResult
from maki.ocr.models import ReceiptResult


class CoachJobResult(ApiModel):
    kind: Literal["coach"]
    schema_version: Literal[1]
    answer: CoachAnswer


class ReceiptJobResult(ApiModel):
    kind: Literal["receipt"]
    schema_version: Literal[1]
    receipt: ReceiptResult


class ForecastJobResult(ApiModel):
    kind: Literal["forecast"]
    schema_version: Literal[1]
    forecast: ForecastResult


JobResult = Annotated[
    CoachJobResult | ReceiptJobResult | ForecastJobResult,
    Field(discriminator="kind"),
]
