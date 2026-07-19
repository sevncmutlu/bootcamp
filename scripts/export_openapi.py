import argparse
import sys
from pathlib import Path

import yaml

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings

_ROOT = Path(__file__).resolve().parents[1]
_CONTRACT_PATH = _ROOT / "contracts" / "openapi.yaml"


def _schema() -> dict[str, object]:
    app = create_app(
        settings=Settings(environment=Environment.DEVELOPMENT),
        container=Container(),
    )
    return app.openapi()


def _render() -> str:
    return yaml.safe_dump(
        _schema(),
        allow_unicode=True,
        sort_keys=True,
        width=120,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="OpenAPI sözleşmesini üretir.")
    parser.add_argument(
        "--check",
        action="store_true",
        help="Dosyayı değiştirmeden güncelliğini denetler.",
    )
    args = parser.parse_args()
    rendered = _render()
    if args.check:
        if not _CONTRACT_PATH.exists() or _CONTRACT_PATH.read_text(encoding="utf-8") != rendered:
            sys.stderr.write("OpenAPI sözleşmesi güncel değil.\n")
            return 1
        return 0

    _CONTRACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    _CONTRACT_PATH.write_text(rendered, encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
