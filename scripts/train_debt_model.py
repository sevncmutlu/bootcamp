"""Onaylı veriyle borç risk modelini çevrim dışında eğitir."""

from __future__ import annotations

import argparse
import base64
import os
from pathlib import Path

from cryptography.hazmat.primitives.asymmetric.ed25519 import (
    Ed25519PrivateKey,
)

from maki.modeling.dataset import TrainingDataset
from maki.modeling.model_card import CostMatrix
from maki.modeling.pipeline import (
    ModelTrainingPipeline,
    TrainingArtifacts,
    TrainingPipelineSettings,
)
from maki.modeling.training import LightGbmTrainingConfig

_SIGNING_KEY_VARIABLE = "MAKI_MODEL_SIGNING_KEY"


def main() -> None:
    args = _arguments()
    dataset = TrainingDataset.model_validate_json(args.dataset.read_bytes())
    settings = TrainingPipelineSettings(
        model_version=args.model_version,
        production=not args.test_only,
        training=LightGbmTrainingConfig(
            seed=args.seed,
            num_boost_round=args.rounds,
            num_leaves=args.leaves,
            minimum_leaf_rows=args.minimum_leaf_rows,
        ),
        costs=CostMatrix(
            false_positive=args.false_positive_cost,
            false_negative=args.false_negative_cost,
        ),
        limitations=(
            "Yeni kullanıcılar ve davranış değişimleri için güven düşebilir.",
            "Sonuç tek başına finansal karar değildir.",
        ),
    )
    artifacts = ModelTrainingPipeline().run(
        dataset=dataset,
        source_content=args.source_content.read_bytes(),
        settings=settings,
        signing_key=_signing_key(required=not args.test_only),
    )
    _write_outputs(args.output, artifacts)


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Borç risk modelini eğitir ve imzalı çıktıları üretir.",
    )
    parser.add_argument("--dataset", type=Path, required=True)
    parser.add_argument("--source-content", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--model-version", required=True)
    parser.add_argument("--test-only", action="store_true")
    parser.add_argument("--seed", type=int, default=20_260_719)
    parser.add_argument("--rounds", type=int, default=200)
    parser.add_argument("--leaves", type=int, default=15)
    parser.add_argument("--minimum-leaf-rows", type=int, default=30)
    parser.add_argument("--false-positive-cost", type=float, default=1.0)
    parser.add_argument("--false-negative-cost", type=float, default=4.0)
    return parser.parse_args()


def _signing_key(*, required: bool) -> Ed25519PrivateKey | None:
    encoded = os.environ.get(_SIGNING_KEY_VARIABLE)
    if encoded is None:
        if required:
            msg = f"{_SIGNING_KEY_VARIABLE} üretim eğitimi için zorunludur."
            raise RuntimeError(msg)
        return None
    try:
        key_bytes = base64.b64decode(encoded, validate=True)
        return Ed25519PrivateKey.from_private_bytes(key_bytes)
    except (TypeError, ValueError) as error:
        msg = f"{_SIGNING_KEY_VARIABLE} geçerli Ed25519 anahtarı değil."
        raise RuntimeError(msg) from error


def _write_outputs(output: Path, artifacts: TrainingArtifacts) -> None:
    output.mkdir(parents=True, exist_ok=True)
    _atomic_write(output / "model.json", artifacts.model.model_bytes)
    _atomic_write(output / "manifest.json", artifacts.model.manifest_bytes)
    _atomic_write(
        output / "model-card.md",
        artifacts.card_markdown.encode("utf-8"),
    )


def _atomic_write(path: Path, content: bytes) -> None:
    temporary = path.with_suffix(f"{path.suffix}.tmp")
    temporary.write_bytes(content)
    temporary.replace(path)


if __name__ == "__main__":
    main()
