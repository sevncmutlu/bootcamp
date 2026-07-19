from pathlib import Path

import yaml

ROOT = Path(__file__).parents[3]


def test_k6_smoke_enforces_latency_and_error_budget() -> None:
    content = (ROOT / "tests/load/k6-smoke.js").read_text(encoding="utf-8")

    assert "duration: '5m'" in content
    assert "vus: 20" in content
    assert "'p(95)<100'" in content
    assert "'p(95)<300'" in content
    assert "'rate<0.01'" in content
    assert "Idempotency-Key" in content


def test_alerts_cover_required_failure_modes() -> None:
    document = yaml.safe_load((ROOT / "infra/otel/alerts.yaml").read_text(encoding="utf-8"))
    rules = [rule for group in document["groups"] for rule in group["rules"]]
    names = {rule["alert"] for rule in rules}

    assert {
        "MakiHigh5xxRate",
        "MakiQueueAgeHigh",
        "MakiFailedJobs",
        "MakiProviderTimeouts",
        "MakiPrivacyRejectionsRising",
        "MakiReadinessDown",
    } <= names
    for rule in rules:
        assert rule["labels"]["severity"] in {"warning", "critical"}
        assert rule["annotations"]["runbook"].startswith("docs/operations/alarms.md#")
