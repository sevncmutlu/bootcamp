# Güvenlik ve yeniden yapılandırma kanıtı — 30 Temmuz 2026

## Sonuç

MakiKoç mobil bilgi mimarisi 14 sayfalık tasarımla eşleştirildi; eski parola tabanlı
backend yüzeyi ve ona bağlı mobil akış kaldırıldı. Son kaynak durumunda çalıştırılan
statik analiz, bağımlılık, secret, IaC, sözleşme ve test kapıları bloklayıcı bulgu
üretmedi.

## Kimlik sınırı düzeltmeleri

- `/v1/auth/register`, `/v1/auth/login`, `/v1/auth/reset-password`,
  `/v1/auth/change-password` ve `/v1/auth/users` yüzeyi kaldırıldı.
- Kaynak içindeki sabit JWT sırrı, HS256 oturum üretimi, statik salt, MD5 kullanıcı
  kimliği ve `users_store.json` kaldırıldı.
- Wildcard credential CORS kaldırıldı; native API CORS başlığı yayınlamıyor.
- Korumalı API uçları `EdDSA`, `ES256` veya `RS256` ile imzalı; issuer, audience,
  key ID ve zaman claim'leri doğrulanan kısa ömürlü erişim belirtecini kabul ediyor.
- Mobil tarafta parola hesabı yerine yalnız cihazda saklanan profil kullanılıyor.
  Kaynağa gömülü varsayılan debug token bulunmuyor.

## Mobil ürün kapsamı

- Alt menü: Gelir/Gider, Borç, Karşılaştır, Analiz, Lider.
- Orman yan menüde; MakiKoç her ekrandan ayrı aksiyonla erişilebilir.
- Net durum, gelir/gider kaydırma görünümü ve yerel dönem karşılaştırması.
- Kar topu ve çığ borç stratejileri.
- Kişisel enflasyon, gider/gelir tahmini ve k-anonim liderlik görünümü.
- Tohum, Fidan, Çalı, Ağaç, Koruluk aşamaları ve beş yerel flora hedefi.
- Profil, bildirim, tema, dil, premium ve veri silme akışları.

## Doğrulama matrisi

| Kapı | Sonuç |
|---|---:|
| Semgrep özel politika | 8 kural, 373 hedef, 0 bulgu |
| Semgrep geniş Registry paketleri | 325 kural, 551 hedef, 0 bulgu |
| Trivy kaynak/secret/IaC | 0 HIGH/CRITICAL açık, 0 secret, 0 misconfiguration |
| pip-audit | 131 kilitli Python bağımlılığı, 0 bilinen açık |
| Ruff | biçim ve lint temiz |
| mypy | 132 kaynak dosyası, 0 hata |
| Backend pytest | 196 geçti, 9 Docker testi atlandı |
| Backend dal kapsamı | %73,26; eşik %70 |
| Flutter analyze | 0 sorun |
| Flutter test | 98 geçti |
| Finans çekirdeği | analiz temiz, 45 test geçti |
| OpenAPI | sözleşme güncel |
| SBOM | CycloneDX JSON üretildi |
| Frontend kaynak sınırı | 117 dosya, SHA-256 ağaç özeti doğrulandı |

## Yerel ortamda çalışmayan kapılar

Docker kurulu olmadığı için PostgreSQL/Redis kullanan dokuz entegrasyon testi,
container build ve image taraması yerelde çalışmadı. Android SDK bulunmadığı için
yeni APK üretilemedi. Bu kapılar CI iş akışında zorunlu olarak korunuyor.

## Canlıya geçiş öncesi dış bağımlılıklar

- Gerçek OIDC/PKCE kimlik sağlayıcısı, anahtar rotasyonu ve token teslim akışı.
- Mağaza satın alma kimlikleri ve üretim imzaları.
- Gerçek PostgreSQL, Redis, telemetry ve sır yönetimi üzerinde CI/RC çalıştırması.
- Android/iOS imzalı dağıtım ve fiziksel cihaz kabul testi.
