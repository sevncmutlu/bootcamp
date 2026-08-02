# Maki Global Tema Paleti Tasarımı

## Amaç

Kullanıcı Ayarlar ekranından vurgu temasını değiştirdiğinde yalnızca düğmeler değil, Maki'nin bütün dekoratif arayüzü aynı renk ailesine geçecek. Ana finans ekranındaki hedef kartı, takvim, alt gezinme, sayfa zeminleri, kartlar, çipler ve Orman ekranındaki arayüz yüzeyleri seçilen temayı yansıtacak.

Finansal anlam taşıyan renkler temadan bağımsız kalacak: gelir ve başarı yeşil, gider ve hata mercan/kırmızı, uyarı kehribar olacak. Bu ayrım okunabilirliği ve öğrenilmiş anlamları koruyacak.

Orman ekranına gömülen "Tasarruf Liderlik Tablosu" bölümü kaldırılacak. Ayrı liderlik ekranı ve servisleri bu iş kapsamında silinmeyecek.

## Değerlendirilen Yaklaşımlar

### 1. Anlamsal tema paleti — seçilen yaklaşım

Seçilen vurgu renginden eksiksiz bir `ColorScheme` ve Maki'ye özel bir `ThemeExtension` üretilecek. Tüm dekoratif yüzeyler bu merkezi paleti okuyacak. Finansal anlam renkleri tema uzantısında ayrı roller olarak tanımlanacak.

Avantajları: tek kaynak, tutarlı açık/koyu mod, yeni ekranların otomatik uyumu ve test edilebilir renk rolleri. İlk düzenleme kapsamı diğer seçeneklerden biraz daha geniştir fakat kalıcı çözümdür.

### 2. Yalnızca Material `ColorScheme` temizliği

Sabit renkler `Theme.of(context).colorScheme` alanlarıyla değiştirilir. Daha hızlıdır ancak Maki'ye özgü gradyan, atmosfer, finans rolleri ve çizim yüzeyleri için yeterli ifade gücü sağlamaz.

### 3. Ekran bazlı renk eşleme

Her ekranda seçilen temaya göre ayrı renk hesaplanır. Görsel kontrol sağlar fakat tekrar üretir, yeni ekranlarda unutulur ve mevcut sorunun yeniden oluşmasına açıktır.

## Mimari

### Tema üretimi

`AppTheme`, kaydedilmiş vurgu rengini ve açık/koyu mod bilgisini alacak. Vurgu renginden Material renk şeması üretilecek; mevcut sabit orman yüzeyleri seçili rengin tonlarına dönüştürülecek. Varsayılan tema seçildiğinde Maki'nin bugünkü orman kimliği korunacak.

Yeni Maki tema uzantısı şu rolleri sağlayacak:

- Sayfa atmosferi ve yükseltilmiş yüzeyler
- Kahraman/hedef kartı gradyanının başlangıç ve bitiş renkleri
- Hafif vurgu, kontur, seçili durum ve gezinme yüzeyleri
- Gelir/başarı, gider/hata ve uyarı gibi sabit anlamsal renkler

Kayıt akışı değişmeyecek: ayarlardaki tema anahtarı yerel ayarlara kaydedilecek, uygulama kökü bunu renge çevirecek ve hem açık hem koyu `ThemeData` yeniden üretilecek. Bilinmeyen veya eski bir anahtar gelirse varsayılan orman teması kullanılacak.

### Bileşen dönüşümü

Öncelikli dönüşüm alanları:

- Ana finans ekranındaki hedef kartı ve gradyanı
- Haftalık takvim, seçili gün ve gelir/gider göstergeleri
- Alt gezinme, sekmeler, çipler, düğmeler ve giriş alanları
- Sayfa arka planı ve Maki'nin büyüme halkaları
- Orman ekranındaki paneller, ilerleme kartları ve çevresel vurgu yüzeyleri
- Ortak bakiye, hedef ve özet kartlarındaki dekoratif sabit yeşiller

`GoalExperience` yalnızca hedefe göre metin, simge, görev ve davranış seçmeye devam edecek. Hedefin kendi `accent` rengi görsel tema kaynağı olmayacak; böylece "Birikim yapmak" seçimi kullanıcı mor veya mavi tema seçtiğinde kartı tekrar yeşile çevirmeyecek.

Maki maskotu, doğal ağaç illüstrasyonları ve fotoğraf niteliğindeki varlıklar zorla tek renge boyanmayacak. Bunları çevreleyen atmosfer, kart ve kontroller seçilen temaya uyacak. Bu, görsellerin tanınabilirliğini korurken uygulama kabuğunun bütünüyle tema değiştirmesini sağlar.

### Orman liderlik bölümü

`ForestScreen` içindeki gömülü `LeaderboardView` ve başlık/sekme bağlantısı kaldırılacak. Orman ekranı yalnızca kullanıcının büyümesi, görevleri ve ilerleme hikâyesine odaklanacak. Ayrı liderlik sayfası mevcut gezinmede kalacak; veri modeli, backend uçları ve liderlik testleri bu değişiklikten etkilenmeyecek.

## Erişilebilirlik ve Hata Davranışı

- Tema tonları açık ve koyu mod için ayrı üretilecek; metinler yüzeye karşı yeterli karşıtlıkta kalacak.
- Seçili kontrol yalnızca renkle anlatılmayacak; mevcut simge, etiket ve durum göstergeleri korunacak.
- Gelir/gider ayrımı renk yanında ok, etiket ve işaretlerle devam edecek.
- Geçersiz tema tercihi uygulamayı bozmayacak; varsayılan vurgu rengine düşecek.
- Tema geçişi mevcut uygulama yeniden oluşturma akışını kullanacak ve kullanıcı verisine dokunmayacak.

## Doğrulama

- Tema üretimi için açık/koyu ve en az iki farklı vurgu rengiyle birim/widget testleri
- Hedef kartının seçilen tema rengini kullandığını, hedef profilinin rengini kullanmadığını doğrulayan test
- Gelir, gider ve uyarı rollerinin tema değişiminde anlamsal olarak sabit kaldığını doğrulayan test
- Orman ekranında gömülü liderlik başlığı ve görünümünün bulunmadığını doğrulayan test
- Tüm Flutter testleri ve statik analiz
- Üretim web derlemesi
- Masaüstü ve telefon ölçülerinde en az iki tema için ekran görüntüsüyle taşma, kontrast ve tema kaçağı kontrolü

## Kapsam Dışı

- Liderlik özelliğinin backend'den veya ayrı sayfadan tamamen silinmesi
- Maki maskotu ve illüstrasyon varlıklarının yeniden üretilmesi
- Tema seçeneği sayısının artırılması
- Kullanıcı verisi, API sözleşmeleri veya finans hesaplama davranışlarının değiştirilmesi
