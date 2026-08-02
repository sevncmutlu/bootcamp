# Maki Cihaz İçi Typst Kullanım Raporları Tasarımı

Tarih: 1 Ağustos 2026
Rapor şartname sürümü: 1.0

## Karar ve ürün vaadi

Maki günlük, haftalık ve aylık finans kullanım raporlarını tamamen cihaz içinde
üretir. Typst'in açık kaynak Rust derleyicisi Android/iOS'ta yerel kütüphane,
web'de WebAssembly worker olarak gömülür. Finans özeti, hedef, işlem, kişisel
yorum veya PDF üretim verisi hiçbir sunucuya gönderilmez. Sunucuya geri dönüş
seçeneği yoktur.

Raporun görsel dili mevcut MakiKoç marka sistemi ve Yaşayan Finans Ormanı ile
uyumludur: veri önce gelir; yuvarlak kulaklı, dolgun tüylü Maki yalnız gerekli
yerlerde rehberlik eder. Çıktı paylaşılabilir, okunabilir ve denetlenebilir bir
finans günlüğüdür; yatırım, kredi veya kesin gelecek sonucu vaadi değildir.

## Kullanıcı akışı

“Raporlarım” merkezi takvim ve ayarlar üzerinden açılır. Kullanıcı:

1. günlük, haftalık veya aylık rapor seçer;
2. geçerli tarih/gün/hafta/ayı seçer;
3. tutarları göster/gizle seçimini yapar;
4. isteğe bağlı işlem dökümü ekini açar;
5. rapor önizlemesini üretir ve sistem paylaşım sayfasıyla kaydeder/paylaşır.

Son kullanılan gizlilik seçimi cihazda saklanır. Tutarları gizle varsayılanı,
uygulamadaki genel “tutarları gizle” tercihini devralır. PDF oluşturulduktan sonra
uygulama kalıcı kopya saklamaz; kullanıcı açıkça kaydettiği konumu yönetir.

## Sabit içerik ve sayfa sözleşmeleri

### Günlük rapor

Temel rapor tam **1 sayfadır**:

- marka, tarih ve rapor türü başlığı;
- gelir, gider ve net akış için üç özet kartı;
- gün içi akış ve kategori dağılımı;
- günlük orman bakımı, seri ve kazanılan XP/tohum özeti;
- en fazla 220 karakter ve üç satırlık tek Maki yorumu.

İşlem dökümü istenirse temel sayfa değişmez; ek sayfaları sonuna eklenir.

### Haftalık rapor

Temel rapor tam **3 sayfadır**:

1. kapak, dönem, gelir/gider/net özet ve haftanın tek ana içgörüsü;
2. gün gün nakit akışı, kategori dağılımı ve olağandışı hareket açıklamaları;
3. hedef rotası, orman/seri/ödül özeti ve en fazla üç güvenli sonraki adım.

İşlem dökümü temel üç sayfayı değiştirmeyen ek olur.

### Aylık rapor

Temel rapor tam **5 sayfadır**:

1. kapak ve yönetici özeti;
2. haftalara göre gelir, gider ve net akış;
3. kategori eğilimleri ve kullanıcı tarafından doğrulanmış olağandışı hareketler;
4. hedef rotaları, katkı aralığı, tahmini varış aralığı ve veri güveni;
5. Yaşayan Orman, seri, ödül özeti ve en fazla üç öneri kartı.

Her öneri kartı sırasıyla **Öneri**, **Dayanak**, **Güven: düşük/orta/yüksek**
alanlarını taşır. Sayfanın sonunda “Bu rapor yatırım veya kredi tavsiyesi değildir”
uyarısı bulunur. Veri yetersizse öneri uydurulmaz; hangi verinin eksik olduğu ve
kullanıcının güvenli bir sonraki kaydı açıklanır.

### İşlem dökümü eki

Ek, tarih-saat, gelir/gider türü, kategori, açıklama ve tutarı tablo halinde
gösterir. Sayfa başına en fazla 25 işlem, rapor başına en fazla 500 işlem vardır.
Daha çok işlem seçilirse kullanıcı tarih aralığını daraltması için uyarılır;
sessiz kırpma yapılmaz. Ek sayfaları temel raporun sayfa sayısını değiştirmez.

## Tutarları gizleme sözleşmesi

“Tutarları gizle” yalnız karttaki büyük rakamları maskelemez. Şunların tamamına
uygulanır:

- metrikler, toplamlar, net değer, tablo hücreleri ve işlem tutarları;
- grafik eksenleri, ölçekler, veri etiketleri ve açıklama metinleri;
- hedef tutarı, katkı tutarı, kalan tutar ve varış hesaplarının parasal girdileri;
- Maki yorumları, öneri dayanakları, PDF belge başlığı/metadata ve dosya adı.

Grafikler parasal eksen yerine `100` tabanlı göreli endeks veya yüzde payı
kullanır. Farklı seriler yalnız renkle değil; etiket, çizgi deseni ve işaretçiyle
ayrılır. Gizli mod dosya adı yalnız dönem ve rapor türünü içerir; örneğin
`Maki-Aylik-Rapor-2026-08.pdf`. Çıktı baytlarında TL tutarı sızıntısını arayan
otomatik test rapor kapısını geçmeden özellik yayımlanmaz.

## Görsel dil ve Maki kullanımı

- Kapakta Maki sayfa alanının en fazla yüzde 15'ini, iç sayfada yüzde 8'ini,
  final sayfasında yüzde 10'unu kaplar.
- Maki her sayfada bulunmaz; en fazla kapak, hedef/orman sayfası ve son yorumda
  kullanılır.
- Maki turuncu-beyaz-kahverengi guinea pig, yeşil kapüşonlu, iki yanda simetrik
  yuvarlak tüylü kulaklı ve dolgun beyaz alın tüylüdür; kel/seyrek tepe yoktur.
- Grafik ve tablo veri alanı dekorasyondan daha yüksek kontrast ve öncelik taşır.
- Maki cümlesi sakin, somut ve suçlamayan dildir; ünlem en fazla bir kez,
  emoji kullanılmaz, kesin getiri/gelecek vaadi verilmez.
- Günlük yorum en fazla 220 karakter/3 satır; haftalık içgörü 300 karakter/4
  satır; aylık öneri kartı başına en fazla 320 karakterdir.

## Erişilebilirlik sözleşmesi

Hedef **PDF/UA-1 uyumlu çıktı** üretmektir; doğrulayıcı geçmeden “PDF/UA-1
uyumludur” iddiası yapılmaz. Üretim hattı:

- belge dilini `tr-TR` olarak işaretler;
- semantik başlıklar, tablo başlık hücreleri, okunma sırası ve sayfa yer imleri
  üretir;
- anlamlı görsellere alternatif metin, dekoratif görsellere artifact işareti
  verir;
- gövde metnini en az 10 pt, tablo metnini en az 9 pt tutar;
- normal metinde en az `4,5:1` kontrast sağlar;
- grafik bilgisini yalnız renge bağlamaz; veri etiketi/desen/işaretçi ekler;
- uzun Türkçe metinlerde bölünme ve taşmayı test eder.

Her release adayında otomatik erişilebilirlik denetleyicisi ve ekran okuyucu
odaklı manuel örnek inceleme yapılır. Denetleyici başarısızsa PDF paylaşılabilir
ama ayarlarda uyumluluk rozeti gösterilmez ve sürüm kapısı başarısız sayılır.

## Mimari

### Ortak sözleşme

- `ReportSnapshotBuilder`: seçili dönemi salt okunur, sürümlü ve beyaz listeli
  `ReportSnapshot` modeline dönüştürür.
- `ReportExportCoordinator`: ön koşul, dosya adı, atomik yazma, paylaşım ve
  temizliği yönetir.
- `TypstReportRenderer`: platformdan bağımsız `render(snapshot, settings)`
  arayüzüdür.
- `NativeTypstRenderer`: Android/iOS için Rust Typst derleyicisini FFI üzerinden
  çağırır.
- `WasmTypstRenderer`: web'de derlemeyi ana UI iş parçacığından ayrı worker'da
  yapar.
- `ReportAssetBundle`: sürümlü `.typ` şablonu, gömülü açık lisanslı fontlar,
  Maki varlıkları ve grafik desenlerini taşır.

Typst kaynağı bellekte üretilir. Finans verisi şablon komutuna dönüştürülmeden
önce tipli veri modeli olarak kaçışlanır; kullanıcı metni doğrudan Typst kodu
olamaz. Şablonlar ağ erişimine sahip değildir ve yalnız paket içindeki varlıkları
okur. Android/iOS/web aynı snapshot JSON şemasını ve aynı rapor şartname sürümünü
kullanır.

### Dosya güvenliği ve atomiklik

Çıktı önce uygulamanın geçici alanında rastgele adla oluşturulur, PDF doğrulanır,
sonra hedef dosyaya atomik yeniden adlandırılır veya paylaşım sağlayıcısına
aktarılır. Başarısız derleme, disk dolu, iptal ya da paylaşım hatasında kısmi
hedef dosya bırakılmaz. Paylaşım tamamlanınca/iptal edilince geçici PDF ve bütün
derleyici ara baytları temizlenir. Düz Typst kaynak dosyası diske yazılmaz.

Snapshot beyaz listesi erişim belirteci, API anahtarı, fiş görseli, ham OCR
metni, cihaz kimliği, bildirim kimliği ve yedek anahtarı içeremez. Rapor üretimi
telemetriye finans tutarı, kategori, hedef veya kullanıcı metni göndermez.

## Veri ve yorum kuralları

- Günlük/haftalık/aylık toplamlar mevcut işlem repository'sinin aynı para ve gün
  sınırı kurallarını kullanır; PDF ayrı finans hesabı yapmaz.
- Tek seferlik hareket yalnız kullanıcı onayladıysa olağandışı olarak açıklanır.
- Hedef katkı aralığı Yaşayan Orman şartnamesindeki formül ve güven derecesinden
  gelir; rapor yeni formül icat etmez.
- Varış tarihi kesin gün değil aralıktır. Veri yetersiz/negatif nakit akışında
  tarih gizlenir ve veri gereksinimi açıklanır.
- Kategori boşsa `Kategorisiz` olarak açıkça görünür; sessizce `Diğer`e taşınmaz.
- Yuvarlama, ekran özeti ve PDF arasında aynı `MoneyFormatter` sözleşmesini
  kullanır.

## Hata deneyimi

- Derleyici hazır değilse kullanıcıya “Rapor motoru hazırlanamadı” ve yeniden
  dene eylemi gösterilir; sunucuya gönderme önerilmez.
- Desteklenmeyen şablon/snapshot sürümünde veri değişmeden uyumlu uygulama
  sürümüne yönlendirme yapılır.
- Eksik font/varlık release testinde hata, üretimde ise rapor oluşturmayı durduran
  açıklanabilir teknik durumdur; sistem fontuyla sessiz marka bozulması yapılmaz.
- Disk alanı yetersizse gereken tahmini alan ve depolama ayarına geçiş sunulur.
- Önizleme/oluşturma iptal edilebilir; iptal finans kayıtlarını değiştirmez.

## Sayısal kabul eşikleri

Ölçümler Redmi 9 sınıfı 4 GB Android cihazda release yapısında, 30 tekrarın p95
değeriyle yapılır. İlk Typst motor yüklemesi dahil soğuk ölçüm ayrıca kaydedilir.

| Rapor | Sabit veri seti | p95 üst sınır |
| --- | --- | ---: |
| Günlük temel | 25 işlem, 10 kategori, 3 hedef, 10 katkı | 3 sn |
| Haftalık temel | 150 işlem, 12 kategori, 4 hedef, 30 katkı | 5 sn |
| Aylık temel | 500 işlem, 15 kategori, 4 hedef, 100 katkı | 8 sn |
| Aylık + ek | Yukarıdaki aylık veri + 500 işlem satırı | 12 sn |

Aylık temel PDF en fazla 5 MB, 500 satırlık ekli çıktı en fazla 10 MB olur.
Web'de derleme UI iş parçacığında 100 ms'den uzun kesintiye neden olmaz. Platformlar
arası özet toplamları birebir, sayfa sayıları ve görsel kırılım tolerans içinde
aynı olmalıdır.

## Test sözleşmesi

### Birim ve bütünleşme

- Snapshot oluşturma aynı dönem için deterministik ve salt okunurdur.
- Günlük 1, haftalık 3, aylık 5 temel sayfa sözleşmesi bütün desteklenen veri
  sınırlarında korunur.
- Ek sayfa başına 25 ve toplam 500 işlem sınırı doğrulanır.
- Türkçe karakter, çok uzun kategori/hedef/not ve negatif/çok büyük değerler
  taşma üretmez.
- Tutarları gizle testi metin, tablo, grafik ekseni, metadata, dosya adı, Maki
  yorumu ve PDF çıkarılmış metninde parasal sızıntı arar.
- Kullanıcı metnindeki Typst komutları kaçışlanır ve şablon enjeksiyonu yapamaz.
- Başarısız/iptal derleme kısmi dosya bırakmaz; atomik yeniden adlandırma ve
  geçici temizlik doğrulanır.
- Gizlilik testi snapshot ve çıktı hattında yasaklı alanların bulunmadığını
  kanıtlar.

### Görsel ve erişilebilirlik

- Her şablon sabit örnekle render edilir; sayfalar PNG'ye çevrilip altın görsel
  karşılaştırması ve insan gözüyle taşma/kontrast incelemesi görür.
- `tr-TR`, başlık hiyerarşisi, okunma sırası, yer imleri, tablo etiketleri,
  alternatif metinler ve artifact işaretleri otomatik denetlenir.
- PDF/UA-1 doğrulayıcı geçmeyen çıktı uyumluluk rozeti alamaz.
- Grafikler gri ton ve renk görme yetersizliği simülasyonunda etiket/desenle
  anlaşılır kalır.
- Maki alan oranı, poz sözleşmesi ve metin uzunluğu otomatik/görsel test edilir.

### Platform ve performans

- Android release, iOS release derleme artefaktı ve web WASM aynı fixture'da aynı
  toplamları üretir.
- Dört sabit performans veri seti 30 kez ölçülür; p95 sınırı aşılırsa release
  kapısı başarısız olur.
- Uçak modunda bütün rapor türleri oluşturulur; ağ isteği testi sıfır olmalıdır.
- Düşük disk, arka plana geçiş, işlem iptali ve paylaşım sayfası dönüşü finans
  verisini veya geçici dosya temizliğini bozmaz.

## Başarı ölçütleri

- Kullanıcı günlük, haftalık ve aylık raporu çevrimdışı üretebilir.
- Hiçbir finans verisi PDF üretimi için cihaz dışına çıkmaz.
- Sabit sayfa, performans, boyut, gizlilik ve erişilebilirlik kapıları otomatik
  testlerde ölçülür.
- Gizli tutar modu PDF'nin bütün yüzeylerinde tutarlı ve sızıntısızdır.
- Öneriler dayanak ve güven seviyesiyle açıklanır; yatırım/kredi tavsiyesi gibi
  sunulmaz.
- Maki raporu sıcak ve ayırt edici yapar ancak verinin önüne geçmez.

## Kapsam dışı

- Sunucuda PDF üretimi veya finans verisi yükleme.
- PDF içinde düzenlenebilir form, e-imza veya parola koruması.
- Banka ekstresi, vergi belgesi veya resmi muhasebe belgesi iddiası.
- 500 işlemden büyük tek PDF eki; kullanıcı dönemini bölerek dışa aktarır.
- Finansal tavsiye, kredi onayı veya getiri garantisi.

## Teknik referanslar

- Typst açık kaynak derleyicisi: https://github.com/typst/typst
- Typst PDF çıktı seçenekleri: https://typst.app/docs/reference/pdf/
