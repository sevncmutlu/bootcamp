from maki.infrastructure.subject_lock import subject_lock_key


def test_subject_lock_key_is_stable_distinct_and_signed_64_bit() -> None:
    first = subject_lock_key("a" * 64)
    repeated = subject_lock_key("a" * 64)
    other = subject_lock_key("b" * 64)

    assert first == repeated
    assert first != other
    assert -(2**63) <= first < 2**63
