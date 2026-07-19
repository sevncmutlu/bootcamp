from maki.coach.models import RetrievedContext, SourceCard, source_value_text
from maki.coach.source_repository import SourceCardRepository

_MINIMUM_CONTEXT_CHARACTERS = 100
_MAXIMUM_CONTEXT_CHARACTERS = 6000
_MAXIMUM_QUERY_CHARACTERS = 2000
_MAXIMUM_SOURCE_COUNT = 10


class OfficialSourceRetriever:
    def __init__(
        self,
        repository: SourceCardRepository,
        *,
        maximum_context_characters: int = _MAXIMUM_CONTEXT_CHARACTERS,
    ) -> None:
        if not (
            _MINIMUM_CONTEXT_CHARACTERS <= maximum_context_characters <= _MAXIMUM_CONTEXT_CHARACTERS
        ):
            msg = "Kaynak bağlam sınırı 100 ile 6000 arasında olmalıdır."
            raise ValueError(msg)
        self._repository = repository
        self._maximum_context_characters = maximum_context_characters

    async def retrieve(
        self,
        query: str,
        limit: int,
    ) -> RetrievedContext:
        normalized_query = query.strip()
        if not normalized_query or len(normalized_query) > _MAXIMUM_QUERY_CHARACTERS:
            msg = "Kaynak sorgusu 1 ile 2000 karakter arasında olmalıdır."
            raise ValueError(msg)
        if not 1 <= limit <= _MAXIMUM_SOURCE_COUNT:
            msg = "Kaynak sınırı 1 ile 10 arasında olmalıdır."
            raise ValueError(msg)

        candidates = await self._repository.search_published(
            normalized_query,
            limit,
        )
        cards: list[SourceCard] = []
        lines: list[str] = []
        character_count = 0
        for index, card in enumerate(candidates, start=1):
            line = _source_line(index, card)
            added = len(line) + (1 if lines else 0)
            if character_count + added > self._maximum_context_characters:
                break
            cards.append(card)
            lines.append(line)
            character_count += added

        return RetrievedContext(
            sources=tuple(cards),
            context_text="\n".join(lines),
            sources_available=bool(cards),
        )


def _source_line(index: int, card: SourceCard) -> str:
    return (
        f"[{index}] {card.institution} | {card.series_id} | "
        f"dönem {card.period.isoformat()} | "
        f"değer {source_value_text(card.value)} {card.unit} | "
        f"yayın {card.release_date.isoformat()} | "
        f"{card.source_url} | snapshot {card.snapshot_digest}"
    )
