from enum import StrEnum
from typing import Literal

from pydantic import Field, field_validator

from maki.common.models import ApiModel


class AgeBand(StrEnum):
    AGE_18_24 = "18-24"
    AGE_25_34 = "25-34"
    AGE_35_44 = "35-44"
    AGE_45_54 = "45-54"
    AGE_55_PLUS = "55+"


class HouseholdBand(StrEnum):
    ONE = "1"
    TWO = "2"
    THREE_PLUS = "3+"


class CohortKey(ApiModel):
    age_band: AgeBand
    household_band: HouseholdBand

    @field_validator("age_band", mode="before")
    @classmethod
    def parse_age_band(cls, value: object) -> AgeBand:
        return value if isinstance(value, AgeBand) else AgeBand(str(value))

    @field_validator("household_band", mode="before")
    @classmethod
    def parse_household_band(cls, value: object) -> HouseholdBand:
        return value if isinstance(value, HouseholdBand) else HouseholdBand(str(value))


class PercentileStatus(StrEnum):
    AVAILABLE = "available"
    INSUFFICIENT_COHORT = "insufficient_cohort"


CohortSizeBucket = Literal["0-49", "50-99", "100-249", "250+"]


class CohortPercentile(ApiModel):
    status: PercentileStatus
    percentile_bucket: int | None = Field(
        default=None,
        ge=0,
        le=100,
        multiple_of=5,
    )
    cohort_size_bucket: CohortSizeBucket
