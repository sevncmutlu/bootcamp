import re
from pathlib import Path

import yaml

KOK = Path(__file__).parents[2]
TAM_SHA = re.compile(r"^[0-9a-f]{40}$")


def _is_akislari(path: Path) -> list[dict[str, object]]:
    belge = yaml.safe_load(path.read_text(encoding="utf-8"))
    return [
        adim
        for is_tanimi in belge["jobs"].values()
        for adim in is_tanimi.get("steps", [])
        if "uses" in adim
    ]


def test_ci_aksiyonlari_degismez_sha_ile_sabitlenir() -> None:
    dosyalar = [
        KOK / ".github/workflows/ci.yaml",
        KOK / ".github/workflows/release-candidate.yaml",
    ]

    aksiyonlar = [adim["uses"] for dosya in dosyalar for adim in _is_akislari(dosya)]

    assert aksiyonlar
    for aksiyon in aksiyonlar:
        _, ayirici, surum = str(aksiyon).partition("@")
        assert ayirici == "@"
        assert TAM_SHA.fullmatch(surum)


def test_ci_uretim_guvenlik_kapilarini_calistirir() -> None:
    icerik = (KOK / ".github/workflows/ci.yaml").read_text(encoding="utf-8")

    assert "check_frontend_boundary.ps1" in icerik
    assert "cyclonedx-py environment" in icerik
    assert "pip-audit" in icerik
    assert "trivy-action" in icerik
    assert "--cov-branch" in icerik
    assert "docker build" in icerik


def test_surum_adayi_imzasiz_yayimlanamaz() -> None:
    icerik = (KOK / ".github/workflows/release-candidate.yaml").read_text(encoding="utf-8")

    assert "environment: release-candidate" in icerik
    assert "COSIGN_PRIVATE_KEY" in icerik
    assert "exit 1" in icerik
    assert "--provenance=true" in icerik
    assert "--sbom=true" in icerik
    assert "cosign sign" in icerik
    assert "unsigned" not in icerik.lower()


def test_bagimlilik_guncellemeleri_gruplanir() -> None:
    belge = yaml.safe_load((KOK / ".github/dependabot.yml").read_text(encoding="utf-8"))

    ekosistemler = {guncelleme["package-ecosystem"] for guncelleme in belge["updates"]}
    assert {"github-actions", "pip", "pub"} <= ekosistemler
