# Maki Android üretim, web preview ve iOS kaynak yayını

Bu reçete Android'i production hedefi, web'i açıkça demo/preview ve iOS'u Mac kabulüne
kadar kaynak-hazır olarak yönetir. Android üretim paketi OIDC oturumu, HTTPS backend,
yasal bağlantılar, mağaza kimliği ve imza eksikken **fail-closed** biçimde derlenmez.

| Platform | Statü | Veri sınırı |
|---|---|---|
| Android | Production hedefi | Yerel şifreli DB; ağ özellikleri açık kullanıcı eylemiyle |
| Web | Preview / demo | Yalnız sentetik in-memory SQLite; sekme kapanınca silinir |
| iOS | Kaynak-hazır | İmza ve fiziksel doğrulama Mac gerektirir |

Production web derlemesi bilinçli olarak reddedilir. Preview şu komutla üretilir:

```powershell
./scripts/commands/build_frontend_web_preview.bat
```

Üstteki kalıcı bant bu sürümün yalnız sentetik veri kullandığını açıkça belirtir.

## 1. GitHub ortamı

Android release için `production` adlı GitHub Environment oluşturun. Aşağıdaki **Variables** değerlerini
tanımlayın:

| Değişken | Örnek / açıklama |
| --- | --- |
| `MAKI_BACKEND_URL` | `https://api.maki.example.com` |
| `MAKI_WEB_ORIGIN` | `https://maki.example.com` — sonuna `/` koymayın |
| `MAKI_OIDC_ISSUER` | OIDC sağlayıcısının HTTPS issuer adresi |
| `MAKI_OIDC_CLIENT_ID` | Public istemci kimliği; uygulamaya client secret gömülmez |
| `MAKI_OIDC_AUDIENCE` | Backend JWT audience değeriyle aynı olmalı |
| `MAKI_BILLING_PRODUCT_ID` | Örneğin `maki_debt_pro` |
| `MAKI_PRIVACY_URL` | Yayındaki gizlilik sayfasının HTTPS adresi |
| `MAKI_TERMS_URL` | Yayındaki kullanım koşullarının HTTPS adresi |

Aşağıdaki **Secrets** değerlerini tanımlayın:

- `MAKI_SENTRY_DSN` — isteğe bağlı; olaylar PII ve istek gövdesi olmadan gönderilir.
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

Android anahtarını Base64 biçimine dönüştürürken çıktıyı depoya eklemeyin.
`frontend/android/key.properties` ve `*.jks` dosyaları Git tarafından yok sayılır.

## 2. OIDC sağlayıcısı

Authorization Code + PKCE kullanan iki public istemci kaydı açın:

- Android ve iOS dönüş adresi: `com.team120.maki:/oauth2redirect`
- Çıkış dönüş adreslerinde de aynı kayıtları izinli yapın.
- Backend için asimetrik imzalı erişim belirteci üretin; issuer ve audience değerleri
  `MAKI_SECURITY__JWT_ISSUER` ve `MAKI_SECURITY__JWT_AUDIENCE` ile birebir eşleşsin.

Mobil belirteçler işletim sisteminin güvenli deposunda tutulur. Finans kayıtları hesap
açılmadan cihazda çalışmaya devam eder. Web preview OIDC veya gerçek finans verisi kullanmaz.

## 3. Backend ve web kökeni

Backend üretim ortamında en az şu değerleri ister:

```dotenv
MAKI_ENVIRONMENT=production
MAKI_EXECUTION_MODE=queue
MAKI_WEB_ORIGINS=["https://maki.example.com"]
MAKI_SECURITY__JWT_ISSUER=https://kimlik.example.com/
MAKI_SECURITY__JWT_AUDIENCE=maki-mobile
```

`MAKI_WEB_ORIGINS` tam kökenlerden oluşur; wildcard, yol ve credential CORS kabul
edilmez. Web ve API HTTPS üzerinden sunulmalıdır.

## 4. Gerçek mağaza doğrulaması

Google Play için backend secret yöneticisine şunları verin:

```dotenv
MAKI_BILLING__GOOGLE_SERVICE_ACCOUNT_JSON={...}
MAKI_BILLING__GOOGLE_PACKAGE_NAME=com.team120.maki.maki_app
MAKI_BILLING__ALLOWED_PRODUCTS=["maki_debt_pro"]
```

Servis hesabını Google Play Console’da uygulamaya bağlayın ve yalnız gerekli
sipariş/abonelik okuma yetkilerini verin. Ürün kimliği GitHub değişkeniyle aynı
olmalıdır.

App Store için backend secret yöneticisine şunları verin:

```dotenv
MAKI_BILLING__APPLE_BUNDLE_ID=com.team120.maki.makiApp
MAKI_BILLING__APPLE_ENVIRONMENT=Production
MAKI_BILLING__APPLE_TRUSTED_ROOT_PEM=...
MAKI_BILLING__APPLE_ACCOUNT_TOKEN_SECRET=en-az-32-karakterlik-rastgele-secret
```

Apple hesap bağı sırrı son kullanıcıya gönderilmez. Backend kullanıcı kimliğinden
kararlı ve takma adlı hesap belirteci üretir; satın alma kanıtı bu bağ doğrulandıktan
sonra hak tanır. İstemci yalnız backend onayından sonra mağaza işlemini tamamlar.

## 5. Paket üretimi ve kabul kapıları

- Her push/PR: `.github/workflows/ci.yaml`
- `v*` etiketi veya elle yayın: `.github/workflows/frontend-release.yaml`
- Web preview çıktısı: `maki-web-preview-*` (production artefaktı değildir)
- İmzalı Android App Bundle: `maki-android-*`
- iOS kod doğrulama çıktısı: `maki-ios-unsigned-*`

iOS workflow’u kodun gerçek cihaz hedefinde derlendiğini doğrular. App Store imzası,
provisioning profili ve fiziksel cihaz kabul testi Apple geliştirici hesabı bulunan
bir Mac üzerinden tamamlanmalıdır.

Yayın kabulünde en az şunları doğrulayın:

1. Android'de OIDC giriş/dönüş ve oturum yenileme.
2. Android/iOS’ta fiş kamerası ve izin reddi akışı.
3. Gerçek mağaza sandbox satın alma, geri yükleme ve iptal akışı.
4. Hesap bağlantısı kesilince yerel gelir/gider kayıtlarının çalışmaya devam etmesi.
5. 360 px telefon, telefon yatay ve tablet düzenleri.
6. Web preview'da sentetik veri bandı, in-memory açılış ve sekme yenilemede temiz oturum.
