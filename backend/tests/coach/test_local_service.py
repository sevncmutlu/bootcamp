from maki.coach.local_conversation import LocalConversationEngine
from maki.coach.local_service import LocalCoachService
from maki.coach.models import CoachQuery, CoachSafety


async def test_local_coach_answers_without_api_key_or_source_database() -> None:
    answer = await LocalCoachService().answer(
        CoachQuery(
            question="Kredi kartı borcumu nasıl azaltırım?",
            session_id="01J00000000000000000000000",
        )
    )

    assert answer.safety is CoachSafety.LOCAL_GUIDANCE
    assert "faiz" in (answer.answer or "").casefold()
    assert answer.sources == ()


async def test_local_coach_does_not_echo_personal_information() -> None:
    answer = await LocalCoachService().answer(
        CoachQuery(
            question="Kartım 4111 1111 1111 1111, bütçemi toparlamak istiyorum",
            session_id="01J00000000000000000000000",
        )
    )

    assert "4111" not in (answer.answer or "")


async def test_local_coach_handles_social_conversation_without_disclaimer() -> None:
    service = LocalCoachService()
    greeting = await service.answer(
        CoachQuery(
            question="Selam Maki",
            session_id="01J00000000000000000000000",
        )
    )
    thanks = await service.answer(
        CoachQuery(
            question="Teşekkür ederim",
            session_id="01J00000000000000000000000",
        )
    )

    assert "Merhaba" in (greeting.answer or "")
    assert "eğitim amaçlıdır" not in (greeting.answer or "")
    assert "Rica ederim" in (thanks.answer or "")


async def test_local_coach_remembers_only_the_last_topic_per_session() -> None:
    service = LocalCoachService()
    session = "01J00000000000000000000000"
    other_session = "01J00000000000000000000001"
    await service.answer(CoachQuery(question="Borçlarımı kapatmak istiyorum", session_id=session))

    follow_up = await service.answer(
        CoachQuery(question="Hangisi benim için daha iyi?", session_id=session)
    )
    isolated = await service.answer(
        CoachQuery(question="Hangisi benim için daha iyi?", session_id=other_session)
    )

    assert "Çığ" in (follow_up.answer or "")
    assert "Kar Topu" in (follow_up.answer or "")
    assert "Çığ" not in (isolated.answer or "")


async def test_local_coach_expires_topic_memory() -> None:
    now = 10.0

    def clock() -> float:
        return now

    engine = LocalConversationEngine(memory_ttl_seconds=5, clock=clock)
    service = LocalCoachService(conversation=engine)
    session = "01J00000000000000000000000"
    await service.answer(CoachQuery(question="Borcum var", session_id=session))
    now = 20.0

    expired_follow_up = await service.answer(CoachQuery(question="Hangisi?", session_id=session))

    assert "Çığ" not in (expired_follow_up.answer or "")


async def test_local_coach_is_deterministic_for_the_same_input() -> None:
    first = await LocalCoachService().answer(
        CoachQuery(
            question="PDF raporumu nasıl indiririm?",
            session_id="01J00000000000000000000000",
        )
    )
    second = await LocalCoachService().answer(
        CoachQuery(
            question="PDF raporumu nasıl indiririm?",
            session_id="01J00000000000000000000001",
        )
    )

    assert first.answer == second.answer


async def test_explicit_user_question_wins_over_route_context() -> None:
    answer = await LocalCoachService().answer(
        CoachQuery(
            question=(
                "Ana finans rotası: Hedef Rotası. Öncelik: hedef katkısı.\n"
                "Kullanıcının sorusu: Bütçeme uygun bir tasarruf önerisi ver."
            ),
            session_id="01J00000000000000000000000",
        )
    )

    assert "Birikimi ay sonunda kalana bırakma" in (answer.answer or "")
    assert "Hedef Rotası kartına dokunup" not in (answer.answer or "")
