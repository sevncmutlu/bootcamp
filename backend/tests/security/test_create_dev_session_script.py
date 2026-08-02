from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path
from typing import TYPE_CHECKING

import jwt
import pytest

if TYPE_CHECKING:
    from types import ModuleType

PROJECT_ROOT = Path(__file__).resolve().parents[3]
SCRIPT = PROJECT_ROOT / "scripts" / "create_dev_session.py"


def _load_script() -> ModuleType:
    spec = importlib.util.spec_from_file_location("create_dev_session", SCRIPT)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_cli_uses_requested_bounded_ttl(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture[str],
) -> None:
    module = _load_script()
    monkeypatch.setattr(
        sys,
        "argv",
        [
            str(SCRIPT),
            "--key-dir",
            str(tmp_path),
            "--ttl-seconds",
            "604800",
        ],
    )

    assert module.main() == 0
    payload = json.loads(capsys.readouterr().out)
    claims = jwt.decode(payload["token"], options={"verify_signature": False})

    assert claims["exp"] - claims["iat"] == 604800


def test_cli_rejects_ttl_above_seven_days(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture[str],
) -> None:
    module = _load_script()
    monkeypatch.setattr(
        sys,
        "argv",
        [
            str(SCRIPT),
            "--key-dir",
            str(tmp_path),
            "--ttl-seconds",
            "604801",
        ],
    )

    with pytest.raises(SystemExit):
        module.main()
    assert "300 ile 604800" in capsys.readouterr().err
