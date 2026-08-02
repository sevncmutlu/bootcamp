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
