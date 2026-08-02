# Production kapanış kanıtı — 1 Ağustos 2026

## Platform kararı

- Android production hedefidir; teslimde imzasız debug test APK'sı bulunur.
- Web yalnız sentetik, oturumluk veri kullanan preview'dır.
- iOS kaynak-hazırdır; imza ve fiziksel kabul testi Mac gerektirir.

## Çalıştırılan kapılar

| Kapı | Sonuç |
|---|---|
| Flutter/Dart fatal analiz (`frontend/lib`, `frontend/test`) | 0 sorun |
| Flutter test | 178 / 178 başarılı |
| Backend Ruff format/lint ve mypy | 0 sorun |
| Backend pytest | 224 başarılı, Docker yokluğu nedeniyle 9 entegrasyon testi atlandı |
| Finans çekirdeği fatal analiz | 0 sorun |
| Finans çekirdeği test | 56 / 56 başarılı |
| Semgrep özel SAST | 447 dosya, 8 kural, 0 bulgu |
| Frontend kaynak sınırı | 180 dosya, SHA-256 `43AFDB3256E558A444681318D01465A1DC92A84991978EC3DF112C07C6316F94` |
| Mega-widget yapısal kapısı | Başarılı |
| Web preview release build | Başarılı |
| Chromium web açılış testi | Başarılı; sentetik veri bandı görünür, konsol hatası yok |
| Android debug APK | Başarılı; `com.team120.maki.maki_app.debug`, minSdk 24, targetSdk 36 |
| Production release doğrulayıcısı | Eksik ayarda beklenen şekilde exit 1 ile kapalı kaldı |

Android test APK SHA-256: `B4CB7D32765C96F245EAB59ED70ADE3333329D65AD42C2CB2754B9820C6235AE`
Boyut: `238150006` bayt.

## Bilinen ve dürüst sınırlar

- Docker bulunmadığından PostgreSQL/Redis kullanan dokuz entegrasyon testi bu makinede
  çalışmadı; birim ve sözleşme testleri geçti.
- Web build mevcut JavaScript/CanvasKit hedefinde başarılıdır. `public_file_saver` içindeki
  `dart:html` kullanımı nedeniyle gelecekteki `dart2wasm` hedefi ayrıca çalışma ister.
- İmzalı Android AAB; gerçek keystore, HTTPS backend, OIDC, yasal URL ve mağaza ürün
  kimliği sağlanmadan bilinçli olarak üretilmez.
- Resmî enflasyon karşılaştırması yalnız yayınlanmış ve kaynak URL'si doğrulanmış backend
  snapshot'ı varsa gösterilir; cihaz içi kişisel sepet hesabı ağ olmadan çalışır.
