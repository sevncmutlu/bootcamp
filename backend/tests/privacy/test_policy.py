from maki.privacy.policy import PrivacyPolicy


def test_policy_finds_forbidden_keys_at_any_depth() -> None:
    value = {"series": [{"day": 1, "index": 1.0}], "meta": {"debt_balance": 5_000}}

    violations = PrivacyPolicy().inspect_json(value)

    assert [(item.path, item.key) for item in violations] == [
        ("$.meta.debt_balance", "debt_balance"),
    ]


def test_policy_is_case_insensitive_and_sorts_paths() -> None:
    value = {
        "z": {"Merchant_Name": "örnek"},
        "a": [{"CARD_NUMBER": "4111111111111111"}],
    }

    violations = PrivacyPolicy().inspect_json(value)

    assert [item.path for item in violations] == [
        "$.a[0].CARD_NUMBER",
        "$.z.Merchant_Name",
    ]


def test_policy_fails_closed_after_depth_limit() -> None:
    value: dict[str, object] = {}
    cursor = value
    for _ in range(21):
        child: dict[str, object] = {}
        cursor["nested"] = child
        cursor = child

    violations = PrivacyPolicy(max_depth=20).inspect_json(value)

    assert violations
    assert violations[0].key == "$derinlik"
