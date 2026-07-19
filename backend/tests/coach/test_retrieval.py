from datetime import UTC, date, datetime

from maki.coach.models import SourceCard
from maki.coach.retrieval import OfficialSourceRetriever

_NOW = datetime(2026, 7, 3, 12, tzinfo=UTC)


class InMemorySourceRepository:
    def __init__(
        self,
        *,
        staged: tuple[SourceCard, ...] = (),
        published: tuple[SourceCard, ...] = (),
    ) -> None:
        self.staged = staged
        self.published = published

    async def search_published(
        self,
        query: str,
        limit: int,
    ) -> tuple[SourceCard, ...]:
        del query
        return self.published[:limit]


async def test_retriever_returns_only_published_version() -> None:
    staged = _card("01ARZ3NDEKTSV4RRFFQ69G5FAV", "a" * 64)
    published = _card("01ARZ3NDEKTSV4RRFFQ69G5FAW", "b" * 64)
    repository = InMemorySourceRepository(
        staged=(staged,),
        published=(published,),
    )

    context = await OfficialSourceRetriever(repository).retrieve(
        query="güncel tüketici fiyat endeksi",
        limit=3,
    )

    assert {card.snapshot_id for card in context.sources} == {published.snapshot_id}
    assert staged.snapshot_id not in context.context_text
    assert context.sources_available is True


async def test_retriever_returns_explicit_empty_context() -> None:
    context = await OfficialSourceRetriever(InMemorySourceRepository()).retrieve(
        query="politika faizi", limit=3
    )

    assert context.sources == ()
    assert context.context_text == ""
    assert context.sources_available is False


async def test_retrieved_context_is_bounded() -> None:
    cards = tuple(
        _card(
            f"01{index:024d}",
            f"{index:064x}"[-64:],
            series_id=f"TUFE_{index:02d}",
        )
        for index in range(10)
    )
    context = await OfficialSourceRetriever(
        InMemorySourceRepository(published=cards),
        maximum_context_characters=300,
    ).retrieve(query="tüketici fiyat endeksi", limit=10)

    assert len(context.context_text) <= 300
    assert len(context.sources) < len(cards)


def _card(
    snapshot_id: str,
    digest: str,
    *,
    series_id: str = "TUFE_GENEL",
) -> SourceCard:
    return SourceCard(
        snapshot_id=snapshot_id,
        snapshot_digest=digest,
        institution="TÜİK",
        series_id=series_id,
        period=date(2026, 6, 1),
        value="123.45",
        unit="index",
        release_date=date(2026, 7, 3),
        source_url="https://data.tuik.gov.tr/",
        retrieved_at=_NOW,
    )
