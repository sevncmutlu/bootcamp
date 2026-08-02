from __future__ import annotations

from maki.coach.local_conversation import LocalConversationEngine
from maki.coach.models import CoachAnswer, CoachQuery, CoachSafety
from maki.privacy.scrubber import TextScrubber


class LocalCoachService:
    def __init__(
        self,
        scrubber: TextScrubber | None = None,
        conversation: LocalConversationEngine | None = None,
    ) -> None:
        self._scrubber = scrubber or TextScrubber()
        self._conversation = conversation or LocalConversationEngine()

    async def answer(self, query: CoachQuery) -> CoachAnswer:
        question = self._scrubber.scrub(query.question).text
        answer = await self._conversation.respond(question, query.session_id)
        return CoachAnswer(
            answer=answer,
            safety=CoachSafety.LOCAL_GUIDANCE,
            sources=(),
        )
