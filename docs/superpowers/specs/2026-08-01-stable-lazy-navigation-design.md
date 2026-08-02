# Maki kararlı ve akıcı sekme navigasyonu

Tarih: 1 Ağustos 2026

## Amaç

Gelir/Gider, Borç, Karşılaştır, Analiz ve Lider sekmeleri web ve fiziksel Android
cihazda her zaman değiştirilebilir kalmalı. Bir ekranın veri isteği, yükleme durumu veya
hatası başka bir sekmeye geçişi engellememeli. Redmi 9 gibi daha sınırlı cihazlarda
başlangıç belleği ve çizim yükü düşürülmeli; Maki'nin hareketli ve özenli hissi
korunmalı.

## Gözlenen neden

Ana navigasyon bugün beş tam ekranı aynı anda oluşturup `Stack` içinde üst üste
yerleştiriyor. Görünmeyen ekranlar `AnimatedOpacity`, `IgnorePointer` ve `TickerMode`
ile saklansa da oluşturuluyor, yerleşim hesaplıyor ve `initState` içindeki veri
isteklerini başlatıyor. Bu yapı:

- görünmeyen liderlik ekranının uygulama açılışında backend isteği göndermesine,
- tam ekran render katmanlarının üst üste kalmasına,
- düşük donanımlı cihazlarda gereksiz bellek ve çizim yüküne,
- geçici bir katman durumunun navigasyonu kilitlenmiş gibi göstermesine

yol açabiliyor. Yerel backend'de veritabanı destekli anonim karşılaştırma servisi
hazır olmadığı için liderlik isteği ayrıca `503` alıyor; mevcut istemci sonuçta yerel
tahmine dönse de bu ağ yükü gereksiz.

## Seçilen tasarım

### 1. Tembel sekme oluşturma

Ana navigasyon beş ekranı başlangıçta kurmayacak. Yalnız Gelir/Gider ekranı hazır
olacak; diğer ekranlar ilk kez seçildiklerinde oluşturulup önbelleğe alınacak.
Sekme seçimi yalnız yerel `setState` işlemi olacak ve hiçbir `Future` ya da backend
yanıtını beklemeyecek.

### 2. Tek etkin içerik katmanı

Üst üste `AnimatedOpacity` kullanan tam ekran katmanlar kaldırılacak. Önbelleğe
alınmış ekranlar standart `IndexedStack` içinde tutulacak; yalnız seçili indeks
boyanacak ve dokunma alacak. Etkin olmayan ekranların ticker'ları durdurulacak.
Koç balonu bu yapının üzerinde tek ve bağımsız bir katman olarak kalacak.

### 3. Animasyon politikası

Uygulamadaki animasyonlar kaldırılmayacak. Navigasyon çubuğunun seçim animasyonu,
kart hareketleri, koç balonu ve diğer mikro etkileşimler korunacak. Yalnız eski ve
yeni tam ekranı aynı anda üst üste tutan riskli çapraz geçiş kaldırılacak.

Yeni seçilen tek ekran, 160 ms boyunca çok hafif bir saydamlık ve dikey yerleşme
animasyonuyla görünecek. Bu animasyon eski ekranı dokunulabilir bir katman olarak
tutmayacak. Sistem “hareketi azalt” ayarı açıksa süre sıfır olacak.

### 4. Liderlik geri dönüşü

Yerel geliştirme modunda liderlik ekranı veritabanı tabanlı uzak servisi çağırmayacak;
cihazdaki tasarruf puanından açıkça “yerel tahmin” olarak işaretlenen sonucu anında
üretecek. Üretim/staging ortamında anonim backend sonucu kullanılmaya devam edecek.
Uzak çağrı başarısız olursa aynı yerel tahmin gösterilecek; ekran ve navigasyon hata
durumunda da kullanılabilir kalacak.

### 5. Hata ve durum sınırları

- Aynı seçili sekmeye tekrar dokunmak yeni ekran veya istek oluşturmayacak.
- Hızlı art arda sekme değişiminde son dokunulan indeks belirleyici olacak.
- Bir sekmenin bloc hatası yalnız kendi içeriğinde gösterilecek.
- Amaç değiştiğinde yalnız amaçtan etkilenen Gelir/Gider ekranı yenilenecek; diğer
  önbelleğe alınmış sekmeler gereksiz yere yeniden kurulmayacak.
- Koç balonunun sürüklenen ve kaydedilen konumu korunacak.

## Doğrulama

1. Widget testi beş sekmeye sırayla ve hızlı biçimde dokunup her seferinde doğru
   başlığın görünür olduğunu doğrulayacak.
2. Test, henüz seçilmemiş sekmenin oluşturulmadığını ve ilk seçimden sonra yalnız bir
   kez oluşturulduğunu kanıtlayacak.
3. Liderlik repository testleri geliştirme ortamında ağ çağrısı yapılmadan tahmin
   üretildiğini ve üretimdeki ağ hatasının güvenli tahmine döndüğünü doğrulayacak.
4. Mevcut Flutter test paketi, statik analiz ve web release derlemesi çalıştırılacak.
5. Web'de 390×844, 844×390 ve masaüstü boyutlarında sekme geçişleri denenecek.
6. İmzalı yerel oturum ve USB backend tüneliyle optimize edilmiş Android release APK
   Redmi 9'a kurulacak; sekmeler cihazda doğrulanacak.

## Kapsam dışı

Bu düzeltme sekmelerin görsel tasarımını, finans hesaplarını, kayıt verisini veya
üretim kimlik sağlayıcısı yapılandırmasını değiştirmez. Üretim liderlik veritabanı ve
canlı dağıtım adresi ayrı yayın altyapısı kapsamındadır.
