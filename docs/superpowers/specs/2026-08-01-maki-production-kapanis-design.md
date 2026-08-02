# Maki Production Kapanış Tasarımı

**Tarih:** 1 Ağustos 2026

**Durum:** Kullanıcı tarafından bölüm bölüm onaylandı; uygulama planına hazır
**Yayın hedefi:** Android production, web demo/preview, iOS kaynak-hazır

## 1. Amaç

Bu çalışma Maki'ye yeni bir ürün alanı eklemez. Mevcut ürünün production teslimini
engelleyen son güvenilirlik halkalarını kapatır:

1. Bütün parasal yerel veriyi kuruş bazlı `Int64` alanlara taşımak
2. Manuel release komutlarını eksik production yapılandırmasında fail-closed yapmak
3. Şifrelenmeyen web veri katmanını açıkça oturumsuz demo/preview sınırına almak
4. Bildirim ayar ekranını gerçek Android bildirimi ve finance core LinTS döngüsüne bağlamak
5. Kişisel enflasyonu gerçek fiyat sepeti ve yerel Laspeyres hesabıyla çalıştırmak
6. Harcama tahminini çevrimdışı temel model ve güvenilir backend geçişiyle tamamlamak
7. Beş mega-widget'ı davranış ve görünüm değiştirmeden sürdürülebilir parçalara ayırmak
8. Güncel APK'yı fiziksel cihazda doğrulayıp kaynak ZIP'inden ayrı teslim etmek

## 2. Kesin kapsam dışı

- Maki Koç, Gemini, BYOK anahtarı, coach backend sözleşmesi ve koç ekranı değiştirilmeyecek.
- Leaderboard'un development fallback davranışı genişletilmeyecek.
- Gerçek mağaza/premium satın alma entegrasyonu genişletilmeyecek.
- Web için uygulama seviyesinde şifreleme geliştirilmeyecek; web production ilan edilmeyecek.
- iOS signing, provisioning veya App Store yayını yapılmış gibi sunulmayacak.
- Orman, hedef, rota ve mevcut görsel tasarım yeniden tasarlanmayacak.

## 3. Fazlar ve bağımlılıklar

### Faz 1 — Para ve yayın sınırı

Önce parasal şema migration'ı, ortak para ayrıştırma sınırı, web preview modu ve
fail-closed release doğrulaması tamamlanır. Sonraki bütün özellikler yeni kuruş alanlarını
kullanır; hiçbir yeni kod eski `double` para modeline yazılmaz.

### Faz 2 — Gerçek ürün motorları

Android bildirim/LinTS hattı, kişisel enflasyon fiyat sepeti ve harcama tahmini yeni veri
modeli üstünde tamamlanır. Demo verisi yalnız web preview veri sağlayıcısında bulunur.

### Faz 3 — Mimari parçalama ve teslim

Mega-widget'lar bölünür, kalite sınırları eklenir, bütün test/build kapıları çalıştırılır,
APK telefona kurulur ve teslim paketi yeniden oluşturulur.

## 4. Parasal veri modeli

### 4.1 Kuruşa taşınacak alanlar

Drift şeması `5` sürümünden `6` sürümüne çıkarılır. Aşağıdaki alanlar `REAL/double`
yerine SQLite `INTEGER` ve Dart `int` olur:

| Tablo | Eski alan | Yeni anlam |
|---|---|---|
| `expenses` | `amount` | `amountMinor` |
| `incomes` | `amount` | `amountMinor` |
| `savings_goals` | `targetAmount` | `targetAmountMinor` |
| `savings_goals` | `startingAmount` | `startingAmountMinor` |
| `savings_goals` | `rewardTargetHighWater` | `rewardTargetHighWaterMinor` |
| `goal_contributions` | `amount` | `amountMinor` |
| `goal_milestone_awards` | `targetHighWater` | `targetHighWaterMinor` |

`growthHighWater`, grafik oranları, güven skorları ve LinTS matematik matrisleri para
değildir; `double` kalırlar.

### 4.2 Migration güvenliği

SQLite alan türü yerinde değiştirilmez. Her etkilenen tablo transaction içinde yeni v6
tablosuna kopyalanır:

1. Eski değerlerin null, sonlu ve `Int64 / 100` sınırında olduğu doğrulanır.
2. Her değer `CAST(ROUND(old_amount * 100.0) AS INTEGER)` ile çevrilir.
3. Eski/yeni satır sayıları eşit olmalıdır.
4. Her satır için geri ölçekleme farkı en fazla yarım kuruş olabilir.
5. Yabancı anahtarlar ve benzersiz `sourceRef` değerleri korunur.
6. Kontroller geçmeden eski tablo düşürülmez veya yeniden adlandırılmaz.
7. Her hata bütün transaction'ı geri alır; kısmi migration mümkün değildir.

Migration tekrar çalıştırılabilir olmayacak, fakat sürüm kontrolü nedeniyle idempotent
biçimde yalnız `from < 6` durumunda uygulanacaktır. V5 fixture veritabanıyla gerçek
migration testi bulunacaktır.

### 4.3 Uygulama para sınırı

Tek bir para ayrıştırıcı şu zinciri zorunlu kılar:

```text
UI metni → yerel ondalık ayrıştırma → integer minor unit → Drift → finance core
```

- Virgül ve nokta girişleri Türkçe/İngilizce locale'e göre ayrıştırılır.
- İkiden fazla ondalık basamak açık hata üretir; sessiz yuvarlama yapılmaz.
- Negatif veya sıfır kabulü her use-case tarafından açıkça tanımlanır.
- `double` dönüşümü yalnız görsel grafik oranlarında ve son gösterim katmanında yapılır.
- Repository/entity sözleşmeleri para için `int` veya finance core `Money` taşır.

## 5. Platform ve release sınırı

### 5.1 Android production

Android tek production hedefidir. APK/AAB release yardımcıları ortak bir doğrulayıcı
kullanır ve aşağıdaki değerlerden biri yoksa Flutter derlemesini başlatmadan başarısız olur:

- `MAKI_ENV=production`
- HTTPS `MAKI_BACKEND_URL`
- HTTPS `MAKI_OIDC_ISSUER`
- `MAKI_OIDC_CLIENT_ID`
- `MAKI_OIDC_AUDIENCE`
- Android OIDC redirect URI
- `MAKI_PRIVACY_URL` ve `MAKI_TERMS_URL` (HTTPS)
- `MAKI_BILLING_PRODUCT_ID`

Release scripti bu değerleri eksiksiz `--dart-define` olarak geçirir. Store billing açık
release'te ürün kimliği ve OIDC olmadan derleme yapılamaz. Debug/test APK komutları bu
production kapısından bağımsız kalır.

### 5.2 Web demo/preview

Web production değildir. `MAKI_ENV=preview` ve `WEB_DEMO_MODE=true` birlikte zorunludur.

- Uygulama görünür ve kalıcı bir “Demo · örnek veriler” bandı gösterir.
- Oturum, OCR, gerçek finans kaydı ve production API çağrıları kapalıdır.
- Veri, gerçek `maki_finance` IndexedDB'si yerine oturum ömürlü preview veritabanında tutulur.
- Yenileme/reset örnek senaryoyu deterministik başlangıç durumuna getirir.
- Android/iOS kullanıcı verisi web'e aktarılmaz.
- Web'de `MAKI_ENV=production` uygulama başlangıcında fail-closed hata üretir.

Preview senaryosu 90 günlük açıkça sentetik gelir/gider ve fiyat gözlemi içerir. Hiçbir
ekran bu kayıtları gerçek kullanıcı sonucu olarak adlandırmaz.

### 5.3 iOS

iOS kaynakları yeni veri modeli ve bildirim arayüzüyle derlenebilir tutulur. İzin metinleri
ve adapter kaynakları hazırlanır; fakat signing, IPA ve fiziksel cihaz doğrulaması macOS
bulunmadan tamamlandı sayılmaz.

## 6. Gerçek bildirim ve LinTS döngüsü

### 6.1 Bileşenler

- `NotificationScheduler`: izin, planlama, iptal ve açılış olaylarını soyutlar.
- `NativeNotificationScheduler`: Android gerçek yerel bildirim uygulamasıdır; iOS kaynak
  adapter'ını aynı arayüz altında taşır.
- `PreviewNotificationScheduler`: web'de hiçbir OS bildirimi göndermez.
- `NotificationPolicyRepository`: finance core `LinTsPolicy` durumunu sürümlü JSON olarak
  yerel DB'de saklar.
- `NotificationOrchestrator`: güvenlik filtresi, politika kararı, OS planlama ve sonuç
  uzlaştırmasını yürütür.

Mevcut iki boyutlu `LintsBanditLocalDataSource` ürün akışından çıkarılır. Matematik için
yalnız `maki_finance_core` içindeki doğrulamalı LinTS kullanılır.

Politika yalnız gönderim saatini seçer; finansal tavsiye veya bildirim metni üretmez.
Kollar `morning=09.00`, `afternoon=14.00`, `evening=20.00` olur. Altı boyutlu yerel bağlam
vektörü `[bias, weekend, recentActivity, streakAtRisk, hasActiveGoal, fatigue]` alanlarını
taşır; oranlar `0..1` aralığına sabitlenir ve cihaz dışına çıkmaz. Bildirim metni seçilen
finans rotası ve yerel durumdan deterministik şablonlarla üretilir.

### 6.2 Karar ve olay kaydı

`notification_engagements` v6'da şu alanlarla genişletilir:

- `id` aynı zamanda `decisionId`
- `notificationType`, `arm`, `contextJson`
- `platformNotificationId`
- `scheduledAt`, `deliveredAt`, `openedAt`, `meaningfulActionAt`
- `status`: pending, scheduled, opened, rewarded, expired, cancelled
- `rewardBasisPoints`

Finance core politika durumu için tek satırlı, `schemaVersion` ve `stateJson` taşıyan ayrı
`notification_policy_states` tablosu kullanılır.

### 6.3 Çalışma döngüsü

```text
yerel bağlam → güvenlik filtresi → LinTS kararı → OS planlama
→ bildirim açılışı → anlamlı finans davranışı → tek ödül → politika güncellemesi
```

- İzin yalnız kullanıcı akıllı bildirimleri açtığında istenir.
- Sessiz saatler 21.00–09.00'dur.
- Kullanıcı başına günde en fazla bir finans bildirimi planlanır.
- Uygulama açılışında/ön plana geldiğinde sonuçlar uzlaştırılır ve sonraki yedi günlük
  kayan pencere planlanır; exact-alarm izni istenmez.
- Bildirim payload'ı `decisionId` ve güvenli uygulama rotası taşır.
- `deliveredAt` yalnız platform teslim geri bildirimi sağlarsa doldurulur; Android'in teslim
  callback'i vermediği durumda plan saati teslim kanıtı sayılmaz. Ödül yalnız gerçek açılış
  ve uygulama içi davranıştan türetilir.
- Açılmayan ve 24 saatte süresi dolan karar ödül `0` alır.
- Açılan fakat anlamlı işlem üretmeyen karar ödül `0.25` alır.
- Açılıştan sonraki 24 saatte gelir, gider veya hedef katkısı üreten karar ödül `1` alır.
- Aynı karar yalnız bir kez ödüllendirilebilir.
- Kullanıcı özelliği kapatınca bekleyen bütün bildirimler iptal edilir.

Android 13+ bildirim izni ve gerekli manifest tanımı eklenir. İzin reddi hata değildir;
ayar ekranı durumu açıklar ve LinTS kararı üretmez.

## 7. Kişisel enflasyon motoru

### 7.1 Yerel veri modeli

Yeni tablolar:

**`price_products`**

- `id`, `displayName`, `normalizedName`, `categoryId`, `unitCode`, `createdAt`
- Normalize ad + kategori + birim benzersiz ürün anahtarıdır.

**`price_observations`**

- `id`, `productId`, `observedAt`, `unitPriceMinor`, `quantityMilli`
- `sourceType`: receipt, manual, preview
- `sourceRef`, `confidenceBasisPoints`, `confirmedAt`
- Yalnız kullanıcı tarafından onaylanan gözlem hesaba katılır.

**`official_inflation_snapshots`**

- `seriesId`, `sourceName`, `sourceVersion`, `period`, `indexBasisPoints`, `fetchedAt`
- Resmî veri cevabı sürümlü ve zaman damgalı olarak cache'lenir.

Miktarlar üç ondalık basamağa kadar `quantityMilli` olarak saklanır; ürün fiyatı kuruştur.
Finans DB'sinde fiyat veya miktar için `double` saklanmaz.

### 7.2 Veri edinimi

- OCR backend sonucu ürün adı, miktar, birim fiyat, satır toplamı ve güven değerlerini
  istemciye taşır.
- Kullanıcı OCR kalemlerini düzenleyip onaylamadan fiyat gözlemi oluşmaz.
- Kullanıcı geçmiş veya güncel fiyatı elle ekleyebilir.
- Ürün eşleştirme cihazda normalize ad/kategori/birim üzerinden yapılır.
- Resmî TÜİK kategori endeksleri backend'in sürümlü official-data repository'sinden okunur;
  ham kullanıcı sepeti backend'e gönderilmez.
- Ağ yoksa yerel eşleşen ürünlerle kişisel sonuç hesaplanır; resmî kıyas “güncel değil” veya
  “erişilemiyor” olarak gösterilir.

### 7.3 Hesap ve yeterlilik

- Hesap `maki_finance_core` içindeki `LaspeyresIndex` ile cihazda yapılır.
- Eşleşen ürün `matched`, resmî kategori endeksi kullanılan ürün `proxy`, veri bulunmayan
  ürün `excluded` olur.
- Kapsama oranı `%70` altındaysa kesin kişisel enflasyon yayımlanmaz.
- Sonuç; endeks, enflasyon basis-point'i, eşleşen/vekil/dışlanan payları, kategori katkıları
  ve resmî veri sürümünü taşır.
- UI sahte sıfır göstermez. Durumlar: sepet yok, ikinci dönem bekleniyor, yetersiz kapsama,
  normal sonuç, resmî veri eski/erişilemiyor.

Web preview aynı motoru yalnız sentetik ve açıkça etiketli fiyat sepetiyle çalıştırır.

Mobil sözleşme `GET /api/v1/official-data/inflation/latest` uç noktasını kullanır. Cevap;
`source_name`, `source_version`, `published_at`, `period`, `series_id`, genel endeks ve
kategori endekslerini basis-point olarak taşır. Uç nokta yalnız yayınlanmış repository
snapshot'ını döndürür; canlı TÜİK isteğini kullanıcı isteğinin içinde yapmaz. Boş veya eski
snapshot açık durum koduyla cevaplanır ve istemci son geçerli cache'i tarih etiketiyle
kullanabilir.

## 8. Harcama tahmini

### 8.1 Girdi

- Cihaz son 56 gün için günlük gider toplamını kuruş olarak üretir.
- Gözlem olmayan günler sıfırdır; gözlem gün sayısı ayrıca taşınır.
- Üçten az gözlem günü varsa tahmin üretilmez.
- 3–13 gözlem gününde yalnız düşük güvenli yerel temel tahmin kullanılabilir.
- En az 14 gözlem gününde backend göreli endeks tahmini için uygundur.

### 8.2 Yerel temel model

Finance core'a deterministik bir `SpendingBaseline` eklenir:

- Önce hedef haftanın aynı günlerine ait gözlemlerin medyanını kullanır.
- Aynı hafta günü yetersizse bütün gözlem günlerinin medyanına düşer.
- Medyan mutlak sapmadan düşük/orta/yüksek belirsizlik üretir.
- Sonuç kuruş, kullanılan gün sayısı, yöntem ve güven seviyesi taşır.

Bu model AI olarak adlandırılmaz; “Yerel temel tahmin” etiketiyle gösterilir.

### 8.3 Backend geçişi

- Yeterli veride istemci gerçek tarih/tutar yerine göreli günlük endeks gönderir.
- Backend tahminini gerçek TL ölçeğine çevirme cihazda yapılır.
- Zaman aşımı, kimlik veya servis hatasında ekran çökmez; yerel temel modele düşer.
- UI kaynak, kullanılan gün, güven seviyesi ve fallback nedenini gösterir.
- Android production'da sentetik veri eklenmez.
- Web preview deterministik 90 günlük sentetik geçmişle aynı akışı gösterir.

## 9. Mega-widget parçalama

Görsel ve kullanıcı davranışı korunarak şu dosyalar bölünür:

- `forest_screen.dart`
- `expense_entry_screen.dart`
- `personalized_finance_overview.dart`
- `debt_simulator_screen.dart`
- `inflation_screen.dart`

Her feature şu sınırlara yaklaşır:

```text
presentation/pages/        yalnız ekran iskeleti ve route bağı
presentation/sections/     büyük görsel bölümler
presentation/widgets/      tekrar kullanılabilir küçük parçalar
presentation/controllers/ UI'ya özgü koordinasyon
presentation/forms/        form state ve doğrulama
data/mappers/              DB/API → domain dönüşümleri
domain/usecases/           tek ürün davranışı
```

- Page dosyası en fazla 450, section/widget dosyası en fazla 350 satır olabilir.
- Generated ve localization dosyaları bu sınırın dışındadır.
- Presentation widget'ları doğrudan `di.sl`, `AppDatabase.instance` veya ağ istemcisine
  erişmez; bağımlılık constructor, Provider/BLoC veya use-case üzerinden gelir.
- Mevcut golden/widget testleri görsel regresyonu korur.
- Refactor sırasında yeni tasarım veya özellik eklenmez.

## 10. Hata yönetimi

- Migration hatası uygulamayı bozuk şemada açmaz; transaction rollback ve güvenli hata
  ekranı üretir.
- Release yapılandırma hatası Flutter build başlamadan değişken adıyla raporlanır; sır
  değeri loglanmaz.
- Bildirim izin reddi, OS planlama hatası ve iptal ayrı durumlardır.
- Enflasyon veri yetersizliği hata değildir; hesap durumu olarak modellenir.
- Tahmin backend hatası kullanıcı verisini veya yerel tahmini kaybettirmez.
- Preview'de kapalı production işlemleri açıklayıcı demo mesajı gösterir.
- Telemetry tutar, ürün adı, bildirim bağlamı veya OCR kalemi taşımaz.

## 11. Test ve kabul ölçütleri

### Para ve migration

- V5 fixture içindeki `0.01`, `10.10`, büyük tutar ve hedef katkısı birebir kuruşa taşınır.
- Satır kimlikleri, yabancı anahtarlar ve `sourceRef` korunur.
- Geçersiz/aşırı değer migration'ı tamamen geri alır.
- Repository ve UI testlerinde parasal entity alanları `int`/`Money` dışında olamaz.

### Release ve preview

- Her zorunlu production değişkeninin eksikliği için fail-closed test vardır.
- HTTP API ve hukuk URL'leri reddedilir.
- Production web başlangıcı reddedilir.
- Preview banner, sentetik veri kaynağı ve kapalı ağ özellikleri test edilir.

### Bildirim

- İzin kabul/ret, günlük sınır, sessiz saat ve yedi günlük plan fake scheduler ile test edilir.
- `decisionId` açılış rotasına taşınır.
- `0`, `0.25`, `1` ödülleri bir kez uygulanır ve yeniden başlatmada korunur.
- Web scheduler hiçbir platform çağrısı yapmaz.

### Enflasyon ve tahmin

- Laspeyres eşleşen/vekil/dışlanan payları ve `%70` sınırı test edilir.
- OCR kalemi onaysızken fiyat geçmişine girmez.
- Resmî veri yok/eski durumları sahte sayı göstermez.
- Tahmin `<3`, `3–13`, `>=14` gözlem durumları test edilir.
- Backend hata ve zaman aşımı yerel baseline'a düşer.
- Preview verisi deterministiktir; Android repository'sine sızmaz.

### Mimari ve teslim

- Beş page dosyası doğrudan service locator/DB erişimi taşımaz.
- CI yapısal sınırı, bölünen beş feature'ın page dosyalarında 450 ve yeni section/widget
  dosyalarında 350 satır üstünü reddeder.
- Flutter analiz ve bütün Flutter testleri geçer.
- Backend Ruff, mypy ve pytest kapıları geçer; Docker'a bağlı atlamalar ayrıca raporlanır.
- Finance core analiz/testleri geçer.
- Web preview ve Android debug APK build edilir.
- Son APK fiziksel Android telefona kurulur ve açılır.
- `frontend/test/failures/`, cache, build, sır ve kullanıcı verisi kaynak ZIP'ine girmez.
- APK kaynak ZIP'inden ayrı teslim edilir.

## 12. Dokümantasyon ve teslim söylemi

README, Product Backlog, CHANGELOG, DELIVERY ve Sprint 3 kayıtları şu gerçeği açıkça
yansıtır:

- Android production hedefidir; release için dış signing/OIDC/store değerleri gerekir.
- Web yalnız örnek verili demo/preview'dir ve şifreli finans kasası değildir.
- iOS kaynak-hazırdır; Mac signing/cihaz kanıtı yoktur.
- Kişisel enflasyon gerçek yerel fiyat sepeti yeterliyse hesaplanır; yetersiz veride sonuç
  uydurulmaz.
- Tahmin kaynağı ve güven seviyesi kullanıcıya gösterilir.
- Koç/Gemini bu kapanış çalışmasında değiştirilmemiştir.

## 13. Tamamlanma tanımı

Çalışma ancak bütün kabul testleri geçince, mevcut kullanıcı verisi migration testinde
korununca, web preview sınırı görünür olunca, gerçek Android bildirimi uçtan uca fake ve
cihaz seviyesinde doğrulanınca, enflasyon/tahmin sahte veri olmadan çalışınca, mega-widget
sınırları uygulanınca ve güncel APK + temiz kaynak ZIP'i ayrı teslim edilince tamamlanır.
