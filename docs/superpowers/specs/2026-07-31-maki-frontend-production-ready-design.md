# Maki Android, iOS ve Web Production-Ready Frontend Tasarımı

Tarih: 31 Temmuz 2026

## 1. Amaç ve koruma ilkesi

Maki'nin çalışan finans, borç planı, takvim, orman, fiş tarama ve koç deneyimini
koruyarak Android, iOS ve web hedeflerini üretim dağıtımına hazırlamak.

Bu çalışma mevcut ekranları sıfırdan değiştirmez. Yeni üretim katmanı eklemeli ve
yapılandırmayla açılan bir yapıda ilerler. Geliştirme ortamında bugün çalışan cihaz
profili, yerel finans verisi, PaddleOCR ve yerel Maki Koç davranışı korunur. Veri
silme veya geri döndürülemez şema değişikliği yapılmaz.

Başarı ölçütleri:

- Android ve web release derlemeleri Windows ortamında başarıyla üretilir.
- iOS release derlemesi CI üzerinde `--no-codesign` ile doğrulanır.
- Eksik dış servis ayarı uygulamayı çökertmez veya bozuk eylem göstermez.
- Gerçek kimlik yapılandırıldığında OIDC Authorization Code + PKCE oturumu çalışır.
- Android ve iOS mağaza yapılandırıldığında satın alma, sunucu doğrulaması ve geri
  yükleme akışı çalışır.
- Web, Android ve iOS Maki markalı ad, açıklama, ikon ve platform izinlerine sahip olur.
- Mevcut Flutter testleri korunur; release yapılandırması, erişilebilirlik ve hata
  durumları için yeni testler eklenir.

## 2. Seçilen yaklaşım

Seçilen çözüm **tek kod tabanı ve yapılandırmayla açılan yetenekler** yaklaşımıdır.

`AppEnvironment`, derleme zamanında verilen değerleri tek yerde doğrular.
`CapabilityRegistry`, kimlik, çevrimiçi servisler ve mağaza özelliklerinin gerçekten
kullanılabilir olup olmadığını hesaplar. Arayüz doğrudan `kDebugMode` veya platform
kontrolü yapmak yerine bu kayıt defterini kullanır.

Üç davranış seviyesi bulunur:

1. **Yerel çekirdek:** Gelir, gider, borç, amaç, takvim ve orman her zaman çalışır.
2. **Bağlı özellikler:** OIDC oturumu ve HTTPS API varsa OCR, koç, tahmin,
   karşılaştırma ve sunucu gizlilik işlemleri açılır.
3. **Mağaza özellikleri:** Desteklenen mobil platform, ürün kimliği, oturum ve mağaza
   bağlantısı birlikte hazırsa Premium satın alma ve geri yükleme açılır.

## 3. Üretim ortamı sözleşmesi

Flutter release yapılandırması `--dart-define-from-file` ile aşağıdaki alanları alır:

- `MAKI_ENV`: `development`, `staging` veya `production`.
- `BACKEND_URL`: Production için zorunlu HTTPS API adresi.
- `OIDC_ISSUER`: Discovery belgesini yayınlayan güvenilir kimlik sağlayıcısı.
- `OIDC_CLIENT_ID`: Public mobil/web istemci kimliği.
- `OIDC_AUDIENCE`: Backend JWT audience değeri.
- `OIDC_REDIRECT_URI`: Platforma uygun kayıtlı dönüş adresi.
- `BILLING_PRODUCT_ID`: Google Play ve App Store'da kayıtlı Premium ürün kimliği.
- `ENABLE_STORE_BILLING`: Yalnız `true` olduğunda mobil mağaza bağlantısını açar.
- `PRIVACY_URL` ve `TERMS_URL`: Yayınlanmış hukuki metin adresleri.
- `SENTRY_DSN`: Varsa hassas verisi temizlenmiş crash reporting'i açar.

Kural seti:

- Production API adresi HTTPS değilse uygulama başlatılmaz.
- OIDC alanları hep birlikte yoksa yerel cihaz modu kullanılır; kısmi yapılandırma
  release derlemesini durdurur.
- Mağaza özelliği açıkken ürün kimliği veya OIDC eksikse release derlemesi durur.
- Secret, erişim belirteci, imza anahtarı ve servis hesabı Flutter define dosyasına
  yazılmaz.
- Örnek yapılandırma yalnız sahte değerler ve açıklamalar içerir; gerçek production
  dosyası git dışında tutulur.

## 4. Kimlik ve oturum

Mevcut cihaz profili `DeviceProfileRepository` olarak korunur. Yeni
`SessionRepository`, sunucu kimliğini ayrı yönetir. Kullanıcı adı, avatar ve yerel
finans verisi OIDC profiline taşınmaz.

Gerçek oturum, tüm hedefleri destekleyen `oidc` paketi üzerinden Authorization Code
+ PKCE kullanır:

- Android ve iOS sistem tarayıcısını ve kayıtlı uygulama dönüş bağlantısını kullanır.
- Web aynı akışı kayıtlı HTTPS dönüş adresiyle yürütür.
- Access ve refresh token mobilde güvenli depoya yazılır.
- Webde kalıcı refresh token saklanmaz; oturum tarayıcı sekmesiyle sınırlı tutulur.
- Süresi dolan belirteç yenilenemezse bağlı özellikler kapanır, yerel finans verisi
  açık kalır ve kullanıcıya yeniden bağlanma eylemi gösterilir.
- Çıkış işlemi yalnız sunucu oturumunu temizler; cihaz profili ve finans kayıtları
  ayrı bir onay verilmeden silinmez.

Backend mevcut issuer, audience, imza ve claim doğrulamasını sürdürür. Production web
erişimi için `MAKI_WEB_ORIGINS` tam adres izin listesi eklenir. Bu liste wildcard kabul
etmez, credentials kapalıdır ve yalnız gerekli yöntem/başlıklara izin verir. Böylece
web istemcisi bearer token kullanırken mevcut native güvenlik sınırı zayıflamaz.

## 5. Premium ve mağaza doğrulaması

`in_app_purchase` paketi Android ve iOS mağaza bağlantısını sağlar. Yeni
`StorePurchaseGateway` ürün sorgulama, satın alma akışı, satın alma güncellemeleri,
geri yükleme ve işlemi tamamlama sorumluluklarını tek sınırda toplar.

Akış:

1. Uygulama mağazadaki `BILLING_PRODUCT_ID` ürününü sorgular.
2. Kullanıcı mağaza tarafından gösterilen yerel fiyatı görür ve satın almayı başlatır.
3. Başarılı mağaza kanıtı erişim belirteciyle
   `/api/v1/billing/verifications` uç noktasına gönderilir.
4. Backend Google Play veya App Store kanıtını doğrular ve entitlement üretir.
5. Flutter `/api/v1/billing/entitlements` sonucunu tek doğruluk kaynağı olarak kullanır.
6. Sunucu doğrulamasından sonra işlem tamamlanır. Başarısız doğrulama Premium açmaz.

Yerel `maki_premium_status` değeri yetki kaynağı olmaktan çıkar. Yalnız son doğrulanmış
durumu, kullanıcı kimliği ve kısa son kullanma zamanı ile çevrimdışı görüntüleme önbelleği
olarak kullanılabilir. Debug Pro anahtarı geliştirme modunda kalır ve release'e girmez.

Webde mağaza satın alma düğmesi gösterilmez. Kullanıcı mobilde etkin bir entitlement
ile oturum açmışsa Premium durumu webde okunabilir; değilse ekran bozuk ödeme eylemi
yerine mobil mağazadan edinilebileceğini açıklar.

## 6. Bağlantılar ve Gizlilik deneyimi

Ayarlar ekranına yeni bir **Bağlantılar ve Gizlilik** kartı eklenir. Kart Maki'nin
mevcut ağaç halkası motifini kullanır; yeni bir görsel dil veya ikinci tasarım sistemi
oluşturmaz.

Detay ekranı beş durumu günlük Türkçeyle gösterir:

- **Bu cihazdaki profil:** Finans kayıtlarının cihazda tutulduğunu açıklar.
- **Güvenli oturum:** Bağlı, bağlantı gerekli veya yeniden bağlan durumunu gösterir.
- **Fiş tarama:** Backend yeteneği ve oturum durumuna göre hazır veya eylem gerekli.
- **Maki Koç:** Yerel rehber, Gemini destekli veya bağlantı gerekli durumunu gösterir.
- **Premium:** Mağaza hazır, etkin, geri yüklenebilir veya bu platformda satın alınamaz.

Renk tek durum göstergesi değildir. Her satır ikon, kısa durum metni ve gerektiğinde
tek bir eylem taşır. Teknik issuer, audience, entitlement, provider ve token sözcükleri
kullanıcı metinlerinde gösterilmez.

## 7. Görsel ve responsive iyileştirmeler

Mevcut token sistemi aynen korunur:

- Gece Çamı `#071A14`
- Çam Mürekkebi `#0E4B36`
- Maki Yaprağı `#73976B`
- Orman Sisi `#F3F6F1`
- Ölçülü Kehribar `#D7A84A`
- Toprak Mercanı `#C8623F`

Tipografi `MakiDisplay` ve `MakiSans` ile devam eder. Yeni ekranın ayırt edici öğesi,
bağlantıların tamamlanmasını gösteren sakin bir ağaç halkası güven çemberidir.

Geniş finans ekranında bugün boş kalan alan, mevcut verilerden üretilen üç bölümle
dengelenir: son işlemler, haftanın finans adımı ve hedef ilerlemesi. Dikey mobilde bu
bölümler ana içerikten sonra alt alta akar; yatay telefonda yükseklik zorlanmaz.

Web başlangıç ekranı, başlık, açıklama, manifest renkleri, favicon ve PWA ikonları
Maki markasına çevrilir. İkonlar mevcut onaylı Maki maskotu/marka varlıklarından
üretilir; Flutter varsayılan ikonu hiçbir release hedefinde kalmaz.

## 8. Hukuki metinler ve veri hakları

Uygulama içinden Gizlilik, KVKK aydınlatma ve Kullanım Koşulları sayfalarına erişilir.
Repository'de sade Türkçe başlangıç metinleri ve web sayfaları bulunur; mağaza
gönderiminden önce hukuk uzmanı incelemesi gerektiği release kontrol listesinde açıkça
belirtilir.

Kullanıcı iki ayrı eylemi ayırt edebilir:

- **Bu cihazdaki verileri sil:** Yerel profil ve finans kayıtlarını onay sonrası siler.
- **Sunucudaki verilerimi sil:** Oturum varsa mevcut privacy deletion uç noktasını
  çağırır, sonucu gösterir ve ardından yerel sunucu oturumunu temizler.

Veri dışa aktarma işlemi de yerel kayıtlar ile sunucu verilerini ayrı dosya/kapsam
olarak açıklar.

## 9. Hata yönetimi ve gözlemlenebilirlik

`FlutterError.onError`, `PlatformDispatcher.instance.onError` ve korumalı uygulama
başlatma hattı tek `AppErrorReporter` üzerinden çalışır.

- Geliştirmede hata ayrıntısı konsola yazılır.
- Production'da Sentry DSN varsa temizlenmiş teknik olay gönderilir.
- Finans tutarları, fiş görüntüsü/metni, sohbet mesajı, e-posta, access token, Gemini
  anahtarı ve cihaz profili olay alanlarına eklenmez.
- DSN yoksa hata raporlama no-op olur; uygulama başlatma davranışı değişmez.
- Ağ, oturum, mağaza ve yapılandırma hataları ayrı, eyleme dönük Türkçe mesajlara
  çevrilir.

## 10. Platform paketleme

Android:

- Mevcut kurulumun ve cihaz verisinin korunması için application ID
  `com.team120.maki.maki_app` olarak kesinleştirilir.
- Debug sürümü `.debug` sonekiyle yan yana kurulabilir.
- Release imzası yalnız git dışında tutulan `key.properties` ve keystore ile yapılır.
- Dağıtım betiği imza yoksa başarısız olur; debug anahtarı release için kullanılmaz.
- Maki launcher/adaptive ikonları, sürüm adı ve AAB üretimi doğrulanır.

iOS:

- Mevcut backend mağaza sözleşmesiyle uyumlu Bundle ID
  `com.team120.maki.makiApp` olarak kesinleştirilir.
- Kamera ve fotoğraf kitaplığı izin açıklamaları sade Türkçe eklenir.
- Maki AppIcon seti tamamlanır.
- Windows'ta kaynak ve plist testleri, GitHub macOS job'ında `flutter build ios
  --release --no-codesign` doğrulanır.
- App Store imzası ve provisioning profile yalnız Apple dağıtım ortamında sağlanır.

Web:

- Başlık `Maki | Kişisel Finans Koçun`, kısa ad `Maki` olur.
- Manifest, tema rengi, açıklama, favicon ve maskable ikonlar markalanır.
- Release build gerçek HTTPS API/OIDC yapılandırmasıyla üretilir.
- Static hosting güvenlik başlıkları, cache kuralları ve SPA fallback yapılandırılır.

## 11. Erişilebilirlik

- Etkileşimli alanlar en az 44×44 mantıksal piksel olur.
- Seçim ve bağlantı durumu yalnız renkle anlatılmaz.
- TalkBack/VoiceOver için anlamlı etiket, değer ve düğme rolleri eklenir.
- Klavye odağı görünür ve mantıksal sıradadır.
- `%200` yazı ölçeğinde yatay kayma, kesilme veya üst üste binme olmaz.
- Sistem `reduceMotion` tercihinde dekoratif geçişler kapatılır.
- Küçük üst etiketler ve pasif navigasyon metinleri WCAG AA kontrastına getirilir.

## 12. Test ve CI kapıları

Alan ve servis testleri:

- Ortam sözleşmesi ve kısmi yapılandırmanın reddedilmesi.
- CapabilityRegistry'nin platform/oturum/mağaza kombinasyonları.
- OIDC başarı, iptal, token yenileme hatası ve çıkış davranışı.
- Satın alma, geri yükleme, sunucu doğrulama hatası ve entitlement önbelleği.
- Hata raporlayıcı hassas veri temizleme sözleşmesi.
- Production web CORS izin listesi ve wildcard reddi.

Widget ve görsel testler:

- 390×844 dikey telefon.
- 844×390 yatay telefon.
- 1440×900 geniş web.
- Açık ve koyu tema.
- Klavye açık form, `%200` yazı, azaltılmış hareket ve çevrimdışı durum.
- Bağlantılar ve Gizlilik, Premium kapalı/açık ve geniş finans ekranı golden testleri.

CI:

- `flutter analyze --fatal-infos --fatal-warnings`.
- Tüm Flutter ve finance-core testleri.
- Production yapılandırma sözleşme testi.
- `flutter build web --release` ve markalama kontrolü.
- `flutter build appbundle --release` için imzasız/CI doğrulama yolu; dağıtım yolunda
  gerçek imza zorunluluğu.
- macOS job'ında `flutter build ios --release --no-codesign`.
- Oluşan artefaktlar, sürüm ve SHA-256 bilgileriyle saklanır.

## 13. Aşamalı teslim

1. Ortam sözleşmesi, capability registry ve hata sınırı.
2. OIDC oturum katmanı ve strict production web origin desteği.
3. Mağaza satın alma, backend doğrulama ve Premium kaynağının düzeltilmesi.
4. Bağlantılar ve Gizlilik ekranı, hukuki sayfalar ve geniş ekran iyileştirmesi.
5. Platform ikonları, izinler, paket kimliği ve imzalama sözleşmesi.
6. Release CI, erişilebilirlik testleri ve Android/web tarayıcı doğrulaması.

Her aşama mevcut testleri geçmeden sonrakine ilerlemez. Yeni yetenekler varsayılan
olarak kapalı gelir; mevcut yerel sürüm aşamalar boyunca çalışmaya devam eder.

## 14. Dış dağıtım gereksinimleri

Kod ile üretilemeyen ancak canlı yayın için sağlanması gereken değerler şunlardır:

- OIDC issuer, public client kayıtları ve platform redirect URI'ları.
- Google Play Console ve App Store Connect Premium ürün kaydı.
- Android release keystore ve Google Play service account.
- Apple signing certificate, provisioning profile ve App Store doğrulama kökü.
- Production backend URL, izin verilen web origin ve Sentry DSN.
- Hukuk uzmanı tarafından onaylanmış Gizlilik/KVKK ve Kullanım Koşulları metinleri.

Bu değerler yokken uygulama mevcut güvenli yerel modunu korur; kod bunları varmış gibi
göstermez ve production dağıtım betiği zorunlu olan eksikleri açıkça raporlar.
