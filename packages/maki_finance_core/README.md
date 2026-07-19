# Maki finans çekirdeği

Para, borç, kişisel enflasyon ve cihaz içi model kararlarını saf Dart ile hesaplar. Flutter,
veritabanı veya ağ bağımlılığı taşımaz.

- Para hesapları alt para birimi ve açık yuvarlama kullanır.
- Borç motoru nakit ve bakiye değişmezlerini denetler.
- Laspeyres endeksi eşleşme kapsamasını ayrıca raporlar.
- LightGBM modeli SHA-256 ve Ed25519 doğrulanmadan çalışmaz.
- Sürüm 2 modellerde Platt veya isotonic kalibrasyon cihazda uygulanır.
- LinTS politikası ters matris almadan Cholesky çözümü kullanır.

## Kalite kapısı

```powershell
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos --fatal-warnings
dart test
```

Entegrasyon örnekleri ve hata sınırları
[`docs/integration/finance-core.md`](../../docs/integration/finance-core.md) dosyasındadır.
