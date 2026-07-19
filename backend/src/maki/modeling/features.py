from pydantic import Field

from maki.common.models import ApiModel


class FeatureDefinition(ApiModel):
    name: str = Field(
        min_length=1,
        max_length=128,
        pattern=r"^[a-z][a-z0-9_]*$",
    )
    window_start_days: int = Field(ge=-3_650, le=3_650)
    window_end_days: int = Field(ge=-3_650, le=3_650)

    @property
    def leaks_future(self) -> bool:
        return self.window_start_days > self.window_end_days or self.window_end_days > 0
