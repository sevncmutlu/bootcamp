# Maki Takvimli Amaç Motoru ve Yaşayan Orman Tasarımı

Tarih: 31 Temmuz 2026

## Karar

Önceki ürün incelemesinde seçilen **A yaklaşımı** uygulanır: beşli ana navigasyon
sabit kalır; ana finans ekranı, haftalık plan, Maki önerileri, görevler, analiz
önceliği ve ormandaki tür seçilen finansal amaca göre kişiselleşir.

Bu çalışma dört kullanıcı problemini birlikte çözer:

1. Gelir/gider formunda yazarken klavyenin kapanması.
2. Dar telefon, büyük metin ve yatay ekranda taşma/piksel oturmaması.
3. Onboarding'de seçilen amacın ürün davranışını değiştirmemesi.
4. Orman deneyiminin 14 sayfalık flora ve mobil deneyim yönünden kopuk olması.

## Deneyim mimarisi

### 1. Takvimli ana finans yüzeyi

Gelir/gider sekmesi ürünün günlük merkezi olur. Üstte yedi günlük kaydırılabilir
takvim yer alır. Her gün için gelir, gider ve işlem yoğunluğu işaretlenir. Seçilen
gün; toplam gelir, toplam gider, net akış ve o güne ait işlemleri gösterir. Bugün
seçiliyken kart aynı zamanda haftalık amaç ilerlemesini ve bir sonraki güvenli
adımı sunar.

Veri mevcut `TransactionBloc` durumundan türetilir; ikinci bir finans gerçeği
oluşturulmaz. Takvim seçimi yalnızca sunum durumudur. Tarih karşılaştırmaları gün
başına normalize edilir.

### 2. Amaç motoru

Dört amaç ortak bir `GoalExperience` sözleşmesiyle tanımlanır:

- `track_spending`: kategori farkındalığı, harcama serisi ve haftalık limit.
- `save_goal`: güvenli katkı, hedef kilometre taşı ve varış projeksiyonu.
- `pay_debt`: ödeme günleri, kar topu/çığ karşılaştırması ve faizden kaçınma.
- `learn_invest`: temel kavram öğrenme, risksiz mini ders ve bilgi kontrolü.

Her profil; başlık, vurgu rengi, flora türü, ana ölçüm, haftalık görevler, Maki
önerisi, analiz odağı ve hızlı eylem üretir. Kişiselleştirme, finans verisini veya
hesaplama kurallarını değiştirmez; hangi gerçeğin önce gösterileceğini değiştirir.
Amaç ayarlardan değiştirildiğinde ana ekran ve orman yeniden okunarak anında
yenilenir.

### 3. Yaşayan flora atlası

Orman; tek bir genel ilerleme kartı yerine dört yerel türden oluşan bir atlas
olarak çalışır:

- Harcama takibi: Karayemiş.
- Birikim: Kermes meşesi.
- Borç azaltma: Mersin.
- Finans öğrenme: Ilgın ağacı.

Her tür beş görünür aşamaya sahiptir: tohum, filiz, fidan, ağaç/çalı ve koruluk.
Seçili amaçtaki tür kahraman yüzeyinde öne çıkar; diğer türler parsellerde
korunur. Aşama; mevcut XP, haftalık tasarruf oranı ve tamamlanan görevlerden
deterministik olarak türetilir. Kullanıcıya hangi davranışın kaç gelişim puanı
kazandırdığı açıkça anlatılır. Orman ödül değil, finansal davranışın okunabilir
bir günlüğüdür.

### 4. Kalıcı ve adaptif formlar

Gelir ve gider ekleme yüzeyleri ayrı stateful sheet bileşenlerine taşınır. Form
anahtarı, controller, focus node, seçili kategori/kaynak ve tarih bu bileşenin
`State` ömrü boyunca korunur. `SafeArea`, klavyeye göre `AnimatedPadding` ve
`SingleChildScrollView` kullanılır. Böylece klavye açılırken form yeniden doğmaz,
odak kaybolmaz ve gönder düğmesi erişilebilir kalır.

### 5. Portrait ve landscape kabuğu

Dar portrait'te mevcut yüzen alt dock korunur. Yatay veya geniş düzende aynı beş
hedef `NavigationRail` içinde gösterilir; içerik kalan alanda maksimum genişlikli
bir yüzeye oturur. Kartlar sabit yüksekliğe dayanmaz; `LayoutBuilder`, `Wrap` ve
constraint tabanlı grid kullanır. 320 px, 390 px, 844×390 landscape ve büyük
metin ölçeği test sözleşmesine girer.

## Bileşen sınırları

- `GoalExperience`: amaç anahtarı ile tüm kişiselleştirilmiş metin ve görsel
  öncelikleri eşler; veri saklamaz.
- `GoalExperienceController`: kayıtlı amacı okur, değişimleri yayınlar.
- `FinanceCalendar`: işlem listesinden günlük özet üretir ve seçimi yayınlar.
- `GoalDashboard`: seçili gün + amaç profili + finans özetini kartlara dönüştürür.
- `TransactionEntrySheet`: gelir/gider form durumunu klavye değişiminden izole eder.
- `FloraAtlas`: amaç profili ve gamification durumundan deterministik aşama üretir.
- `AdaptiveNavigationShell`: dock/rail seçimini tek yerde yapar.

Bu parçalar mevcut BLoC ve repository sınırlarını korur; backend veya veritabanı
şeması değişikliği gerektirmez.

## Hata ve boş durumları

- Amaç okunamazsa `track_spending` güvenli varsayılandır.
- Seçilen günde işlem yoksa sıfır değerli, eylem sunan boş durum gösterilir.
- Gelir olmadan tasarruf oranı hesaplanmaz; kullanıcıya veri eksikliği açıklanır.
- Form gönderimi doğrulama başarısızsa odak ilk hatalı alana taşınır.
- Görsel varlık yüklenemezse flora kartı renk/ikon temsiliyle kullanılabilir kalır.
- Hareket azaltma açıkken inset ve ekran geçişleri animasyonsuz çalışır.

## Test sözleşmesi

- Klavye inset'i değişirken girilmiş metin, focus ve form anahtarı korunur.
- Her amaç ana ekranda farklı ana ölçüm, görev, Maki önerisi ve flora üretir.
- Gün seçimi doğru gelir/gider/net değerlerini hesaplar.
- Amaç değişimi uygulamayı yeniden başlatmadan görünür deneyimi günceller.
- 320×640, 390×844 ve 844×390 boyutlarında overflow oluşmaz.
- Büyük metin ölçeğinde birincil eylemler erişilebilir kalır.
- Ormanın beş gelişim aşaması sınır değerlerinde deterministiktir.
- Mevcut finans, gamification, erişilebilirlik ve görsel regresyon testleri korunur.

## Kapsam dışı

- Banka hesabı bağlama, yeni backend endpoint'i veya bulut senkronizasyonu.
- Yatırım tavsiyesi ya da kişiye özel finansal ürün önerisi.
- Yeni ücretlendirme kurgusu.
- Navigasyon bilgi mimarisinin tamamen değiştirilmesi.
