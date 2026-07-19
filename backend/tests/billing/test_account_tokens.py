import pytest

from maki.billing.account_tokens import AppleAccountTokenIssuer


def test_apple_account_token_is_stable_pseudonymous_and_subject_bound() -> None:
    issuer = AppleAccountTokenIssuer(secret=b"x" * 32)

    first = issuer.for_subject("cihaz-1")
    repeated = issuer.for_subject("cihaz-1")
    other = issuer.for_subject("cihaz-2")

    assert first == repeated
    assert first != other
    assert "cihaz" not in first


def test_short_apple_account_token_secret_is_rejected() -> None:
    with pytest.raises(ValueError, match="32 bayt"):
        AppleAccountTokenIssuer(secret=b"kisa")
