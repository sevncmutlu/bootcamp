from pathlib import Path

import yaml
from fastapi import FastAPI

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings

_HTTP_METHODS = {"delete", "get", "patch", "post", "put"}


def test_all_api_operations_have_id_and_turkish_description() -> None:
    app = _app()
    schema = app.openapi()

    for path, path_item in schema["paths"].items():
        for method, operation in path_item.items():
            if method not in _HTTP_METHODS:
                continue
            assert operation["operationId"]
            assert operation["description"]
            assert path.startswith(("/api/v1", "/health"))


def test_contract_has_no_web_or_test_routes() -> None:
    paths = _app().openapi()["paths"]

    assert all("/test/" not in path for path in paths)
    assert set(paths) == {
        "/api/v1/billing/entitlements",
        "/api/v1/billing/verifications",
        "/api/v1/coach/queries",
        "/api/v1/forecasts/jobs",
        "/api/v1/jobs/{job_id}",
        "/api/v1/leaderboard/percentiles",
        "/api/v1/privacy/data",
        "/api/v1/privacy/exports",
        "/api/v1/receipts/jobs",
        "/health/live",
        "/health/ready",
    }


def test_openapi_schema_is_deterministic() -> None:
    first = _app().openapi()
    second = _app().openapi()

    assert first == second
    assert first["openapi"].startswith("3.1.")


def test_checked_in_contract_matches_application() -> None:
    contract_path = Path("../contracts/openapi.yaml")

    assert yaml.safe_load(contract_path.read_text(encoding="utf-8")) == _app().openapi()


def _app() -> FastAPI:
    return create_app(
        settings=Settings(environment=Environment.DEVELOPMENT),
        container=Container(),
    )
