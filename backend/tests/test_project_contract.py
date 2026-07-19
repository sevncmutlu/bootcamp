import tomllib
from pathlib import Path


def test_python_and_lint_contract() -> None:
    pyproject = tomllib.loads(Path("pyproject.toml").read_text(encoding="utf-8"))

    assert pyproject["project"]["requires-python"] == ">=3.12,<3.13"
    assert pyproject["tool"]["ruff"]["line-length"] == 100
    assert pyproject["tool"]["ruff"]["lint"]["mccabe"]["max-complexity"] == 8
    assert pyproject["tool"]["mypy"]["strict"] is True
    assert "pydantic.mypy" in pyproject["tool"]["mypy"]["plugins"]
