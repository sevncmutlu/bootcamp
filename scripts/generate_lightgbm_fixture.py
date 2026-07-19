"""LightGBM ve Dart eşitlik verisini üretir."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import lightgbm as lgb
import numpy as np
from pydantic import BaseModel, ConfigDict, Field

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "contracts" / "models" / "lightgbm" / "parity-fixture.json"
FEATURE_NAMES = ("gelir_norm", "borc_orani", "harcama_oynakligi")
SEED = 20_260_719


class ParityVector(BaseModel):
    """Tek bir Python referans skoru."""

    model_config = ConfigDict(strict=True, extra="forbid", populate_by_name=True)

    features: tuple[float, ...]
    raw_score: float = Field(alias="rawScore")
    probability: float


class ParityFixture(BaseModel):
    """Sürümlü Python-Dart eşitlik sözleşmesi."""

    model_config = ConfigDict(strict=True, extra="forbid", populate_by_name=True)

    schema_version: int = Field(alias="schemaVersion")
    lightgbm_version: str = Field(alias="lightgbmVersion")
    feature_names: tuple[str, ...] = Field(alias="featureNames")
    model: dict[str, Any]
    vectors: tuple[ParityVector, ...]


def _train_model() -> lgb.Booster:
    rng = np.random.default_rng(SEED)
    features = rng.normal(size=(512, len(FEATURE_NAMES)))
    noise = rng.normal(scale=0.2, size=features.shape[0])
    target = (features[:, 0] - (0.7 * features[:, 1]) + (0.25 * features[:, 2]) + noise > 0).astype(
        np.int8
    )
    dataset = lgb.Dataset(
        features,
        label=target,
        feature_name=list(FEATURE_NAMES),
        free_raw_data=True,
    )
    return lgb.train(
        {
            "objective": "binary",
            "metric": "binary_logloss",
            "verbosity": -1,
            "seed": SEED,
            "data_random_seed": SEED,
            "feature_fraction_seed": SEED,
            "bagging_seed": SEED,
            "drop_seed": SEED,
            "deterministic": True,
            "force_col_wise": True,
            "num_threads": 1,
            "num_leaves": 7,
            "min_data_in_leaf": 12,
            "learning_rate": 0.15,
        },
        dataset,
        num_boost_round=9,
    )


def build_fixture() -> ParityFixture:
    """Sabit tohumlu modeli ve 100 doğrulama vektörünü döndürür."""
    booster = _train_model()
    rng = np.random.default_rng(SEED + 1)
    features = rng.normal(size=(100, len(FEATURE_NAMES)))
    raw_scores = np.asarray(booster.predict(features, raw_score=True))
    probabilities = np.asarray(booster.predict(features))
    vectors = tuple(
        ParityVector(
            features=tuple(float(value) for value in row),
            rawScore=float(raw_score),
            probability=float(probability),
        )
        for row, raw_score, probability in zip(
            features,
            raw_scores,
            probabilities,
            strict=True,
        )
    )
    return ParityFixture(
        schemaVersion=1,
        lightgbmVersion=lgb.__version__,
        featureNames=FEATURE_NAMES,
        model=booster.dump_model(),
        vectors=vectors,
    )


def main() -> None:
    """Fixture dosyasını atomik olarak yeniler."""
    fixture = build_fixture()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    temporary = OUTPUT.with_suffix(".json.tmp")
    temporary.write_text(
        json.dumps(
            fixture.model_dump(by_alias=True, mode="json"),
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    temporary.replace(OUTPUT)


if __name__ == "__main__":
    main()
