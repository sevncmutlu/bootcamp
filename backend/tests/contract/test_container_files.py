from pathlib import Path

import yaml

_ROOT = Path("..")


def test_dockerfile_is_pinned_and_non_root() -> None:
    dockerfile = (_ROOT / "backend" / "Dockerfile").read_text(encoding="utf-8")

    assert "python:3.12.13-slim-bookworm" in dockerfile
    assert "USER 10001:10001" in dockerfile
    assert "HEALTHCHECK" in dockerfile
    assert ":latest" not in dockerfile


def test_compose_keeps_datastores_on_internal_network() -> None:
    compose = yaml.safe_load(
        (_ROOT / "infra" / "compose" / "compose.yaml").read_text(encoding="utf-8")
    )

    assert compose["networks"]["backend"]["internal"] is True
    assert compose["services"]["api"]["read_only"] is True
    assert "ports" not in compose["services"]["postgres"]
    assert "ports" not in compose["services"]["redis"]
    assert compose["services"]["api"]["security_opt"] == ["no-new-privileges:true"]
