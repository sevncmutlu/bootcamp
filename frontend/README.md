# Maki Flutter uygulaması

Maki Finans Koçu'nun Android, iOS ve web hedeflerini paylaşan Flutter istemcisidir.
Responsive bilgi mimarisi, cihaz içi finans verisi, Yaşayan Finans Ormanı ve isteğe
bağlı backend özellikleri tek kod tabanında bulunur.

## Çalışan akışlar

- 13–100 yaş doğrulamalı, cihazda saklanan yerel kullanıcı profili
- Dört amaca göre kişiselleşen finans ekranı ve görev rotaları
- Gelir/gider kaydı, haftalık özet ve tam takvim
- Hedef oluşturma, 30 duraklı hedef haritası ve hedefe bağlı işlemler
- 325 görevlik günlük katalog, seri, XP, tohum ekonomisi ve orman mağazası
- Fiş seçme/kamera, PaddleOCR sonucu doğrulama ve gider kaydı
- Kişisel enflasyon, tahmin, borç stratejileri ve kimliksiz karşılaştırma
- Yerel rehber/Gemini destekli Maki Koç
- Günlük, haftalık ve aylık cihaz içi PDF raporları
- Sürüklenebilir ve konumunu hatırlayan Maki balonu
- Tema paleti, azaltılmış hareket, dar ekran ve ekran dönüşü desteği

## Yerel çalıştırma

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
dart run build_runner build
flutter run -d chrome --dart-define=MAKI_ENV=preview --dart-define=WEB_DEMO_MODE=true
```

Backend bağlantılı web akışı için depo kökünde:

```powershell
./scripts/start_maki_web.ps1
```

Android telefon için:

```powershell
adb reverse tcp:8000 tcp:8000
flutter run -d <cihaz-kimliği> `
  --dart-define=BACKEND_URL=http://127.0.0.1:8000 `
  --dart-define=MAKI_ACCESS_TOKEN=<geliştirme-belirteci>
```

## Doğrulama

```powershell
dart format --output=none --set-exit-if-changed lib test
dart analyze lib test
flutter test --no-pub
flutter build web --release --dart-define=MAKI_ENV=preview --dart-define=WEB_DEMO_MODE=true
flutter build apk --debug --no-pub
```

1 Ağustos 2026 tesliminde analiz hatasız ve **178 Flutter testi başarılıdır**.

## Veri ve ağ sınırı

Gelirler, giderler, hedefler, orman, görevler ve raporlar yerel Drift veritabanında
tutulur. PDF cihazda üretilir. OCR için yalnız kullanıcının seçtiği fiş, yapılandırılmış
backend'e gönderilir. Gemini anahtarı isteğe bağlıdır ve güvenli cihaz alanında saklanır.

## Derleme değerleri

- `MAKI_ENV`
- `BACKEND_URL`
- `MAKI_ACCESS_TOKEN` (yalnız geliştirme)
- `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_AUDIENCE`, `OIDC_REDIRECT_URI`
- `BILLING_PRODUCT_ID`, `ENABLE_STORE_BILLING`
- `PRIVACY_URL`, `TERMS_URL`, `SENTRY_DSN`

Üretim derlemesi HTTPS backend, canlı kimlik sağlayıcısı, yasal URL'ler ve platform
imzaları ister. Gerçek anahtarlar kaynak kodda tutulmaz.

## Platform durumu

- Android: fiziksel cihazda doğrulandı.
- Web: yalnız sentetik, oturumluk veri kullanan preview release Chromium'da doğrulandı.
- iOS: proje ve kod hazır; imza/fiziksel test macOS gerektirir.

Tasarım kuralları için [Maki tasarım sistemi](../design-system/makiko/TASARIM-SISTEMI.md),
yayın adımları için [frontend release rehberi](../docs/operations/frontend-release.md)
kullanılır.
