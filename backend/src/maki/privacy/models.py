from pydantic import Field

from maki.common.models import ApiModel


class PrivacyViolation(ApiModel):
    path: str = Field(pattern=r"^\$")
    key: str = Field(min_length=1, max_length=128)


class ScrubResult(ApiModel):
    text: str
    replacements: int = Field(ge=0)
