# Sürüklenebilir Maki Koç Balonu Tasarımı

## Amaç

Maki Koç balonu, “Harcama ekle” gibi finans işlemlerinin üzerine binmeyecek şekilde kullanıcı tarafından taşınabilecek. Kullanıcı balona dokunduğunda Koç ekranı açılacak; balonu sürüklediğinde ise Koç açılmayacak.

Balon bırakıldığında en yakın ekran kenarına yumuşakça yaslanacak ve konumu cihazda hatırlanacak. Telefon döndüğünde veya web penceresi yeniden boyutlandığında kayıtlı konum yeni güvenli alana uyarlanacak.

## Değerlendirilen Yaklaşımlar

### 1. Serbest sürükleme, kenara yaslanma ve kalıcı konum — seçilen yaklaşım

Balon güvenli alan içinde serbestçe sürüklenir. Bırakılınca en yakın yatay kenara animasyonla yaslanır. Konum, ham piksel yerine kullanılabilir alan içindeki `x/y` oranı olarak kaydedilir.

Bu yaklaşım kullanıcıya kontrol verir, ekran dönüşlerine dayanır ve balonun ortada dağınık kalmasını önler.

### 2. Tam serbest ve ham piksel konumu

Uygulaması daha basittir ancak ekran döndüğünde veya pencere küçüldüğünde balon ekran dışına çıkabilir ya da yeniden bir kontrolün üzerine binebilir.

### 3. Sabit güvenli noktalar

Balon yalnızca önceden belirlenmiş köşelere taşınır. Çakışma riski düşüktür fakat kullanıcının istediği serbest hareket hissini sağlamaz.

## Bileşenler

### `DraggableCoachBubble`

Koç balonunun çizimi, dokunma/sürükleme ayrımı, güvenli alan kısıtlaması ve kenara yaslanma animasyonundan sorumlu bağımsız bir bileşen olacak.

Bileşen şu girdileri alacak:

- Koç’u açan `onTap` çağrısı
- Kaydedilmiş normalize konum
- Konum değiştiğinde çağrılan kayıt işlevi
- Alt gezinme ve sistem güvenli alanlarından türetilen hareket sınırları

Balonun mevcut Maki maskotu, tema rengi, gölgesi, erişilebilirlik etiketi ve dokunma hedefi korunacak.

### Yerleşim

`MakiAdaptiveNavigation`, standart `floatingActionButton` alanı yerine gövde ve Koç balonunu bir `Stack` içinde yönetecek. Alt gezinme çubuğu yine `Scaffold` tarafından çizilecek. Koç balonunun hareket alanı:

- Üstte sistem güvenli alanı ve uygulama başlığı için ayrılan sınırın altında
- Altta alt gezinme çubuğu ve güvenli alanın üstünde
- Solda ve sağda en az 12 piksel iç boşlukla

sınırlandırılacak.

Masaüstü gezinme rayı kullanıldığında balon yalnızca içerik alanında hareket edecek; rayın üzerine geçemeyecek.

## Etkileşim Kuralları

- Kısa dokunma Koç ekranını açar.
- Sürükleme eşiği aşıldığında hareket başlar ve dokunma eylemi iptal edilir.
- Sürükleme sırasında balon parmağı veya imleci takip eder.
- Bırakıldığında balonun merkezi hangi yatay kenara daha yakınsa o kenara yaslanır.
- Yaslanma hareketi kısa bir `easeOutCubic` animasyonu kullanır.
- Kullanıcı hareket azaltma ayarını açmışsa yaslanma animasyonu beklemeden tamamlanır.
- Balon ekran dışına, alt menünün veya gezinme rayının üzerine taşınamaz.
- Ekran boyutu değiştiğinde balonun konumu güvenli sınırlara sıkıştırılır.

## Kalıcı Kayıt

Konum iki normalize değer olarak saklanacak:

- `coachBubbleX`: kullanılabilir genişlik içindeki `0–1` oranı
- `coachBubbleY`: kullanılabilir yükseklik içindeki `0–1` oranı

Kayıt yalnızca sürükleme tamamlanıp balon kenara yaslandıktan sonra yapılacak. Böylece her hareket pikselinde disk yazımı yapılmayacak.

Eksik, bozuk, sayı olmayan veya `0–1` dışındaki değerler yok sayılacak. Güvenli varsayılan konum, sağ kenarda ve ana işlem düğmesinden daha yukarıda olacak.

## Erişilebilirlik

- Balon en az 48×48 piksel dokunma alanına sahip olacak.
- Erişilebilirlik etiketi “Maki Koç’u aç” davranışını açıklayacak.
- Klavye/ekran okuyucu etkinleştirmesi sürükleme gerektirmeden Koç’u açacak.
- Odak göstergesi tema rengini kullanacak.
- Hareket azaltma tercihi yaslanma animasyonunda dikkate alınacak.

## Testler

- Balona dokunmanın Koç eylemini bir kez çağırması
- Sürüklemenin Koç eylemini çağırmaması
- Balonun dört ekran sınırından dışarı çıkamaması
- Bırakılınca en yakın kenara yaslanması
- Normalize konumun kaydedilip yeni bileşen örneğinde geri yüklenmesi
- Ekran `390×844` ile `844×390` arasında değiştiğinde balonun görünür ve güvenli kalması
- Alt gezinme, gezinme rayı ve “Harcama ekle” eylemiyle taşma/çakışma kontrolü
- Tüm mevcut Flutter testleri, statik analiz ve üretim web derlemesi

## Kapsam Dışı

- Koç balonunun boyutunu değiştirme
- Birden fazla Koç balonu
- Konumu hesaplar veya cihazlar arasında sunucuyla eşitleme
- Koç sohbet ekranının davranışını değiştirme
