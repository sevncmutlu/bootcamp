# Maki mobil

Maki'nin Flutter tabanlı Android ve iOS uygulamasıdır. Web hedefi Sprint 2'de
kaldırılmıştır.

## Ürün ilkeleri

- Kullanıcı metinleri, doğrulamalar ve hata mesajları Türkçedir.
- Finans verileri varsayılan olarak cihazda kalır.
- Para hesapları finans çekirdeğindeki deterministik modellerle yapılır.
- Release yapısı HTTPS ve dışarıdan sağlanan backend adresi gerektirir.
- Ekranlar küçük cihaz, koyu tema ve azaltılmış hareket tercihleriyle uyumludur.
- Görsel kurallar [MakiKoç mobil tasarım sisteminde](../design-system/makiko/TASARIM-SISTEMI.md)
  tanımlanır.

## Yerel doğrulama

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
dart run build_runner build
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter build apk --debug
```

Yerel backend'e bağlı debug APK:

```powershell
flutter build apk --debug --dart-define=BACKEND_URL=http://127.0.0.1:8000
```

Fiziksel Android cihazında:

```powershell
adb reverse tcp:8000 tcp:8000
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

## Sürüm sınırları

Android üretim imzası, gerçek paket/mağaza kaydı, canlı satın alma sağlayıcısı,
iOS imzası ve App Store profilleri Sprint 3/MVP kapsamındadır. Depoya imzalama
anahtarı veya canlı erişim belirteci eklenmez.
