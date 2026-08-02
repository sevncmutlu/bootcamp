# Maki Finans Koçu — Teslim Notu

**Teslim tarihi:** 1 Ağustos 2026

**Teslim alacak kişi:** Sevinç Mutlu
**Paket türü:** GitHub'a pushlanabilir, kaynak kod odaklı monorepo

## Teslim kapsamı

- Flutter Android production hedefi, sentetik veriyle sınırlı web preview ve iOS kaynakları
- FastAPI backend, PaddleOCR entegrasyonu ve işçi süreçleri
- Ortak finans çekirdeği ve OpenAPI sözleşmeleri
- CI, güvenlik politikaları, altyapı ve işletim belgeleri
- Tasarım sistemi, ürün şartnameleri ve Sprint 1–3 kayıtları
- Güncel README, Product Backlog ve CHANGELOG

## Son kalite özeti

Ayrıntılı komut/sonuç özeti: [production kapanış kanıtı](./docs/evidence/production-close-2026-08-01.md).

| Kapı | Sonuç |
|---|---|
| Dart statik analiz (`lib`, `test`) | Hatasız |
| Flutter testleri | 178 / 178 başarılı |
| Backend Ruff / mypy | Hatasız |
| Backend testleri | 224 başarılı, Docker'a bağlı 9 entegrasyon testi atlandı |
| Finans çekirdeği | Fatal analiz temiz; 56 / 56 test başarılı |
| Flutter web preview release | Chromium'da sentetik in-memory veriyle başarılı |
| Android debug APK | Başarılı |
| PDF Android kayıt testi | 3 / 3 başarılı |
| Semgrep | 447 dosya, 8 özel kural, 0 bulgu |
| Frontend yapısal kapı | 180 dosyalık sınır ve mega-widget eşikleri geçti |
| Kaynak sır taraması | Gerçek `.env`, anahtar ve imza dosyası paketlenmez |

## Android PDF düzeltmesi

Android'de PDF kaydı artık geniş depolama izni istemez. Kullanıcı “Farklı kaydet”
dediğinde işletim sisteminin Storage Access Framework ekranı açılır ve dosyanın konumu
kullanıcı tarafından seçilir. Kullanıcı ekranı kapatırsa işlem iptal olarak gösterilir;
başarı mesajı verilmez. Web'de tarayıcının doğrudan indirme akışı korunur.

## Pakete bilinçli olarak alınmayanlar

- `.env`, erişim belirteçleri, API anahtarları ve servis hesapları
- `key.properties`, keystore/JKS ve mağaza imza dosyaları
- Yerel SQLite/Drift verileri ve kullanıcı dosyaları
- `build/`, `.dart_tool/`, `.gradle/`, Pods ve diğer üretilen klasörler
- Log, cache, test geçici dosyaları, APK/AAB/IPA ve konteyner çıktıları

Gradle wrapper ve bağımlılık lock dosyaları tekrar üretilebilir derleme için kaynak
paketinde tutulur.

## Hızlı doğrulama

```powershell
cd frontend
flutter pub get --enforce-lockfile
dart analyze lib test
flutter test --no-pub
flutter build web --release --dart-define=MAKI_ENV=preview --dart-define=WEB_DEMO_MODE=true
flutter build apk --debug --no-pub
```

Backend için:

```powershell
cd backend
uv sync --all-extras --group dev
uv run ruff check .
uv run mypy src
uv run pytest
```

## Canlı yayından önce dışarıdan sağlanacaklar

- Android release keystore ve Play Console ürünü
- Apple signing/provisioning ve macOS cihaz doğrulaması
- Canlı OIDC issuer/client/audience bilgileri
- HTTPS backend, gizlilik ve kullanım şartları URL'leri
- Kullanılacaksa Gemini, Sentry, EVDS ve mağaza doğrulama bilgileri

Bu değerler bilinçli olarak kaynak pakete gömülmemiştir. Kaynak kod teslimi bunlar
olmadan incelenebilir ve geliştirme/test modunda çalıştırılabilir; mağaza yayını için
`docs/operations/frontend-release.md` izlenmelidir.

## Platform kararı

- **Android:** production hedefidir. Kaynak, test APK'sı ve fail-closed release betikleri hazırdır;
  imzalı AAB yalnız gerçek keystore/OIDC/HTTPS/yasal URL/store kimliğiyle üretilir.
- **Web:** demo/preview'dır. `WEB_DEMO_MODE=true` ister, gerçek finans verisi kabul etmez,
  yalnız sentetik in-memory SQLite kullanır ve sekme kapanınca kayıtlar silinir.
- **iOS:** kaynak-hazırdır. İmza, provisioning ve fiziksel kabul testi Mac gerektirir.

## Sevinç için kontrol listesi

- [ ] ZIP'i aç ve kökte `README.md`, `Product-Backlog.md`, `Sprint-3.md` dosyalarını gör.
- [ ] GitHub deposuna dosyaları kök yapıyı bozmadan yükle.
- [ ] GitHub Actions kalite iş akışlarının başlamasını kontrol et.
- [ ] Canlı servis değerlerini yalnız GitHub/hosting secret alanlarında tanımla.
- [ ] Release imzası gelene kadar debug APK'yı mağaza paketi olarak kullanma.
