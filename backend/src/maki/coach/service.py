from maki.coach.models import (
    CoachAnswer,
    CoachQuery,
    CoachSafety,
    RetrievedContext,
    SourceCard,
)
from maki.coach.ports import CoachProvider, SourceRetriever
from maki.coach.prompt import build_coach_prompt
from maki.privacy.scrubber import TextScrubber

_SOURCE_LIMIT = 5


class ProviderAnswerError(Exception):
    def __init__(self) -> None:
        super().__init__("Sağlayıcı geçersiz kaynak numarası döndürdü.")


class CoachService:
    def __init__(
        self,
        scrubber: TextScrubber,
        retriever: SourceRetriever,
        provider: CoachProvider,
    ) -> None:
        self._scrubber = scrubber
        self._retriever = retriever
        self._provider = provider

    async def answer(self, query: CoachQuery) -> CoachAnswer:
        scrubbed = self._scrubber.scrub(query.question)
        context = await self._retriever.retrieve(
            scrubbed.text,
            _SOURCE_LIMIT,
        )
        if not context.sources_available:
            return CoachAnswer(
                answer=None,
                safety=CoachSafety.INSUFFICIENT_SOURCES,
                sources=(),
            )

        prompt = build_coach_prompt(scrubbed.text, context)
        provider_answer = await self._provider.answer(
            system_prompt=prompt.system_prompt,
            user_prompt=prompt.user_prompt,
        )
        sources = _cited_sources(
            context,
            provider_answer.cited_source_numbers,
        )
        return CoachAnswer(
            answer=provider_answer.answer,
            safety=CoachSafety.ANSWERED,
            sources=sources,
        )


def _cited_sources(
    context: RetrievedContext,
    citations: tuple[int, ...],
) -> tuple[SourceCard, ...]:
    if any(number > len(context.sources) for number in citations):
        raise ProviderAnswerError
    return tuple(context.sources[number - 1] for number in citations)
