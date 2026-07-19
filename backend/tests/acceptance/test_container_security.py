from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[3]
DOCKERFILE = ROOT / "backend" / "Dockerfile"
COMPOSE = ROOT / "infra" / "compose" / "compose.yaml"
PROCESS_SERVICES = {
    "api",
    "dispatcher",
    "worker-coach",
    "worker-data",
    "worker-forecast",
    "worker-ocr",
}


def test_process_images_are_separate_non_root_and_health_checked() -> None:
    dockerfile = DOCKERFILE.read_text(encoding="utf-8")

    assert "--all-extras" not in dockerfile
    for target in PROCESS_SERVICES:
        block = _target_block(dockerfile, target)
        assert "USER 10001:10001" in block
        assert "HEALTHCHECK" in block


def test_compose_processes_have_runtime_hardening_and_limits() -> None:
    services = _compose_services()

    assert services.keys() >= PROCESS_SERVICES
    for name in PROCESS_SERVICES:
        service = services[name]
        assert service["read_only"] is True
        assert service["tmpfs"]
        assert "ALL" in service["cap_drop"]
        assert "no-new-privileges:true" in service["security_opt"]
        assert service["stop_grace_period"]
        assert service["healthcheck"]
        assert service["deploy"]["resources"]["limits"]["memory"]


def test_stateful_dependencies_are_not_exposed_to_host_network() -> None:
    services = _compose_services()

    assert "ports" not in services["postgres"]
    assert "ports" not in services["redis"]
    assert services["postgres"]["networks"] == ["backend"]
    assert services["redis"]["networks"] == ["backend"]


def _target_block(dockerfile: str, target: str) -> str:
    marker = f" AS {target}\n"
    assert marker in dockerfile
    block = dockerfile.split(marker, maxsplit=1)[1]
    return block.split("\nFROM ", maxsplit=1)[0]


def _compose_services() -> dict[str, dict[str, object]]:
    document = yaml.safe_load(COMPOSE.read_text(encoding="utf-8"))
    assert isinstance(document, dict)
    services = document.get("services")
    assert isinstance(services, dict)
    return services
