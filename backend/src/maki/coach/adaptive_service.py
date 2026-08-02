from __future__ import annotations

from maki.coach.gemini_adapter import GeminiAdapter
from maki.coach.local_service import LocalCoachService
from maki.coach.models import CoachAnswer, CoachQuery, CoachSafety
from maki.coach.ports import CoachProviderError
from maki.privacy.scrubber import TextScrubber


class AdaptiveCoachService:
    def __init__(
        self,
        *,
        model_name: str,
        server_api_key: str | None = None,
        scrubber: TextScrubber | None = None,
    ) -> None:
        self._model_name = model_name
        self._server_api_key = server_api_key
        self._scrubber = scrubber or TextScrubber()
        self._local = LocalCoachService(self._scrubber)

    async def answer(
        self,
        query: CoachQuery,
        *,
        request_api_key: str | None = None,
    ) -> CoachAnswer:
        api_key = (request_api_key or self._server_api_key or "").strip()
        if not api_key:
            return await self._local.answer(query)
        cleaned = self._scrubber.scrub(query.question).text
        adapter: GeminiAdapter | None = None
        try:
            adapter = GeminiAdapter(
                api_key=api_key,
                model_name=self._model_name,
            )
            answer = await adapter.answer(question=cleaned)
        except (CoachProviderError, ValueError):
            return await self._local.answer(query)
        finally:
            if adapter is not None:
                await adapter.close()
        return CoachAnswer(
            answer=answer,
            safety=CoachSafety.GEMINI_GUIDANCE,
            sources=(),
        )
