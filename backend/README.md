# Maki backend

Maki mobil uygulamasının veri minimizasyonu odaklı üretim servisleri.

## Geliştirme

Python 3.12 ve `uv` gerekir.

```powershell
uv sync --all-extras --group dev
uv run ruff check .
uv run mypy src
uv run pytest
```

Gerçek anahtarları kaynak koda veya `.env` dosyasına eklemeyin. Yerel değişken adları için
`.env.example` dosyasını kullanın.

## Borç risk modeli

Eğitim çevrim dışında, onaylı veri manifestiyle çalışır. Üretim terfisinde Ed25519 özel anahtarı
yalnızca süreç ortamından okunur:

```powershell
$env:MAKI_MODEL_SIGNING_KEY="<Base64 Ed25519 özel anahtarı>"
uv run --project backend python scripts/train_debt_model.py `
  --dataset data/training-dataset.json `
  --source-content data/approved-source.bin `
  --output artifacts/debt-model `
  --model-version debt-2026-07
```

`--test-only` çıktısı imzalı üretim modeli sayılmaz. Sentetik veri, gelecek bilgisi kullanan özellik,
bozuk içerik özeti veya kabul kapısını geçemeyen ölçümler üretime çıkarılmaz.
