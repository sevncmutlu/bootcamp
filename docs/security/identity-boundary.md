# Kimlik güvenlik sınırı

## Karar

Maki backend'i kullanıcı parolası, parola özeti veya parola sıfırlama belirteci
saklamaz. `/v1/auth/register`, `/v1/auth/login`, `/v1/auth/reset-password`,
`/v1/auth/change-password` ve `/v1/auth/users` yüzeyi bilinçli olarak yoktur.

Korumalı API uçları, güvenilen dış kimlik sağlayıcısından gelen erişim belirtecini
`Authorization: Bearer …` başlığıyla kabul eder. Backend yalnız imzayı ve zorunlu
claim'leri doğrular; uygulama oturumu üretmez.

## Doğrulama kuralları

- Asimetrik imza izin listesi: `EdDSA`, `ES256`, `RS256`.
- Anahtar seçimi için zorunlu `kid`.
- Zorunlu claim'ler: `sub`, `jti`, `iss`, `aud`, `iat`, `nbf`, `exp`.
- Issuer ve audience yapılandırmadaki sabit değerlerle eşleşir.
- Erişim belirteci ömrü 30–3.600 saniyedir.
- Algoritma başlıktan okunup serbestçe güvenilmez; izin listesiyle kesişmeyen değer
  doğrulama başlamadan reddedilir.
- Doğrulama anahtarı yalnız ortam/sır yönetiminden gelir. Özel anahtar backend'e
  verilmez.

## Mobil istemci

Ad, avatar ve isteğe bağlı e-posta yalnız cihaz profili olarak
`FlutterSecureStorage` içinde tutulur. Bu profil sunucu kimliği değildir. Dış kimlik
akışı tamamlandığında erişim belirteci güvenli depoya yazılabilir. Kaynağa gömülü
varsayılan veya anonim debug token yoktur.

## CORS

Native istemciler ve web istemcisi aynı Bearer belirteci sınırını kullanır;
cookie tabanlı oturum yoktur. Geliştirmede yalnız loopback adresleri kabul edilir.
Diğer ortamlarda `MAKI_WEB_ORIGINS` tam HTTPS kökenlerinden oluşan JSON listesi
olarak verilir. Wildcard, credential CORS, yol içeren adres, kullanıcı bilgisi ve
HTTP kökeni ayar doğrulamasında reddedilir. Listede olmayan kökenlere CORS başlığı
verilmez.

## Otomatik güvenlik kapıları

- `backend/tests/security/test_identity_boundary.py` kaldırılan uçların 404
  verdiğini ve wildcard CORS başlığı olmadığını doğrular.
- `security/semgrep.yml` legacy parola yüzeyini, hard-coded JWT sırrını, wildcard CORS'u,
  eski mobil auth yollarını ve gömülü debug token'ı engeller.
- CI; Semgrep SAST, Trivy kaynak/secret/IaC taraması, `pip-audit`, Ruff, mypy,
  pytest ve container Trivy taramasını birlikte çalıştırır.
