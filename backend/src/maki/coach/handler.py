from pydantic import JsonValue

from maki.coach.models import CoachQuery
from maki.coach.service import CoachService


class CoachJobHandler:
    def __init__(self, service: CoachService) -> None:
        self._service = service

    async def __call__(
        self,
        payload: dict[str, JsonValue],
    ) -> dict[str, JsonValue]:
        query = CoachQuery.model_validate(payload)
        result = await self._service.answer(query)
        return result.model_dump(mode="json")
