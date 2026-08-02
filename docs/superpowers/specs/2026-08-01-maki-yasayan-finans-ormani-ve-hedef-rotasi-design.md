# Maki Yaşayan Finans Ormanı ve Hedef Rotası Tasarımı

Tarih: 1 Ağustos 2026

## Karar ve ürün vaadi

Maki'nin ayırt edici çekirdeği **Yaşayan Finans Ormanı** olur. Gerçek finans
davranışları takvimde görünür bir günlük oluşturur; günlük süreklilik ormanı
büyütür; kullanıcı tanımlı birikim hedefleri ise harita üzerindeki rotalara
dönüşür. Oyun katmanı finans verisinin önüne geçmez ve yapay etkileşim üretmez.
Her büyüme, kullanıcının anlayabileceği gerçek bir davranışa dayanır.

Bu tasarım birlikte şu ihtiyaçları karşılar:

1. Güvenilir fiş sonucunu otomatik olarak gider kaydına dönüştürmek.
2. Toplam tutar okunamadığında veya şüpheli olduğunda yanlış kayıt oluşturmamak.
3. Haftalık özet takvimini dokunulabilir tam takvim ve günlük finans günlüğüne
   dönüştürmek.
4. Günlük finans davranışlarından seri, XP, seviye ve orman ödülü üretmek.
5. Bir ana ve en fazla üç yan birikim hedefini rota haritasında ilerletmek.
6. Harcanabilir ama gerçek parayla ilişkisi olmayan bir orman ekonomisi kurmak.
7. Kullanıcı uygulamaya girmediğinde bağlama uygun, öğrenen ve gerçek yerel
   bildirimler göndermek.
8. Yerel-öncelikli gizlilik ve mevcut sıfır saklamalı fiş işleme ilkesini
   korumak.

Günlük, haftalık ve aylık Typst PDF kullanım raporu bu çekirdeği okuyacak ancak
ayrı bir bağlı tasarım belgesinde ele alınacaktır.

## Deneyim mimarisi

### 1. Tam takvim ve günlük bakım

Gelir/Gider ekranındaki haftalık kartın başlığı veya takvim simgesi tam takvim
sayfasını açar. Tam takvim ay görünümü, seçili gün özeti ve o günün orman bakım
durumunu birlikte gösterir. Her gün için gelir, gider, net akış, işlem sayısı,
tamamlanan davranış ve seri durumu görünür.

Şu davranışlardan en az biri bir günü tamamlar:

- gelir veya gider kaydetmek;
- güvenilir bir fişi onaylamak ya da otomatik kaydetmek;
- bir hedefe katkı kaydetmek;
- günlük finans kontrolünü tamamlamak.

Uygulamayı yalnızca açmak seri kazandırmaz. Aynı davranışı silip yeniden eklemek
ikinci ödül üretmez. Geçmiş tarihli finans kayıtları takvimi düzeltir; son 48 saat
içinde girilen doğrulanmış kayıtlar seriyi onarabilir. Daha eski kayıtlar günlüğe
işlenir fakat mevcut seriyi geriye dönük büyütmez.

Bir günün kaçırılması ormanı soldurmaz veya kazanılmış eşyayı geri almaz.
Kullanıcıda koruma yaprağı varsa seri otomatik korunabilir; yoksa yeni seri
başlar ve en iyi seri geçmişte saklanır.

### 2. Kullanıcı hedefleri ve rota haritası

Kullanıcı hedef adı, hedef tutarı, mevcut başlangıç birikimi, isteğe bağlı hedef
tarihi ve görsel simge seçer. Aynı anda bir ana hedef ve en fazla üç aktif yan
hedef bulunabilir. Ana hedef, ana finans kartı, orman kahraman alanı ve bildirim
önceliğini belirler.

Katkılar gelir veya gider değildir; ayrı bir hedef katkı defterinde tutulur.
Katkı kaydetmek banka hesabından para taşımaz. Her katkı aşağıdaki kaynak
türlerinden birini taşır:

- `manual_unverified`: kullanıcı yalnız rota ilerlemesini düzeltir; XP veya tohum
  vermez ve finans bakiyesini değiştirmez;
- `linked_transaction`: mevcut tekil bir finans hareketine bağlanır, tam ödül
  verir ve aynı hareket birden fazla hedefe bağlanamaz;
- `confirmed_transfer`: kullanıcı gerçek bir para ayırma/aktarma işlemini açıkça
  doğrular; 24 saatlik bekleme sonunda tam ödül verir;
- `balance_adjustment`: başlangıç ya da düzeltme amaçlıdır; ilerlemeyi düzeltir,
  ödül vermez.

Katkı silinirse rota deterministik olarak geri hesaplanır. Bekleyen ödül iptal
edilir; kesinleşmiş XP/tohum olayına ise değiştirilemez ödül defterinde ters kayıt
atılır ve eksi bakiye yaratmadan gelecekteki kazançlardan mahsup edilir. Önceden
açılmış kalıcı görsel geri alınmaz. Kaynak kimliği ve hedef bağlantısı tekildir;
silip yeniden eklemek yeni ödül üretemez.

Maki en fazla son sekiz tam haftayı kullanır ve son dört haftaya daha yüksek
ağırlık vererek sürdürülebilir bir haftalık katkı aralığı hesaplar. Tek bir kesin
tutar vermez.

Hesaplama sırası şöyledir:

1. Her hafta için olağan gelir eksi bütün gerçek giderler alınarak haftalık net
   nakit akışı bulunur. Kullanıcının zorunlu olarak işaretlediği kira, fatura,
   ulaşım ve benzeri tekrar eden giderler ödeme haftasını yapay biçimde bozmasın
   diye aylık tutardan haftalığa (`aylık / 4,345`) dağıtılır; özgün işlem yalnız
   bir kez hesaba girer. Zorunlu gider hiçbir koşulda öneri hesabından çıkarılmaz
   ve açıklamada ayrı toplam olarak gösterilir.
2. Kullanıcının “tek seferlik” olarak onayladığı hareketler öneri hesabından
   çıkarılır ama raporda ayrıca gösterilir. Sistem, aynı kategorinin medyanının
   üç katını veya sekiz haftalık gelirin yüzde 20'sini aşan ve tekrarlanmayan
   hareketleri yalnızca inceleme adayı olarak işaretler; kendiliğinden dışlamaz.
3. Düzeltilmiş haftalık netlerin yüzde 25'lik dilimi `temkinli_kapasite` olur.
4. Alt sınır, pozitif temkinli kapasitenin yüzde 15'i; üst sınır yüzde 30'udur.
   Sonuçlar kullanıcı para biriminde anlamlı basamağa aşağı yuvarlanır.
5. Haftalık netlerin değişkenlik katsayısı yüzde 35'i aşıyorsa üst sınır yüzde
   20'ye düşer. En az dört kullanılabilir hafta, üç haftada gelir ve toplam 12
   hareket yoksa sayısal aralık verilmez.

Veri güveni `düşük`, `orta` veya `yüksek` gösterilir. Orta güven için en az dört,
yüksek güven için en az sekiz tam hafta, haftaların en az yüzde 75'inde gelir ve
en az 30 hareket gerekir. Kullanıcı hangi haftaların, hangi tek seferlik
hareketlerin ve hangi oynaklık düzeltmesinin kullanıldığını görebilir. Gelir
verisi yetersiz veya net akış negatifse kesin tarih vaat edilmez; önce veri
toplama veya daha küçük bir başlangıç katkısı önerilir.

Rota haritası başlangıç, yüzde 10, 25, 50, 75 ve 100 duraklarını gösterir. Her
durak yeni bir flora öğesi, parsel, mevsim ayrıntısı veya tohum ödülü açar. Hedef
tutarı ya da tarihi değiştiğinde rota deterministik biçimde yeniden hesaplanır;
kazanılmış kalıcı ödüller geri alınmaz.

Hedef oluşturmak, yeniden adlandırmak veya hedef tutarını değiştirmek tek başına
ödül vermez. Ödül ilerlemesi başlangıç birikiminden değil, hedef oluşturulduktan
sonraki net katkılardan hesaplanır. Ödül hesabının hedef tutarı, o hedefin
geçmişte gördüğü en yüksek tutardır; tutarı düşürmek yeni kilometre taşı açmaz.
Aynı hedefte aynı yüzde durağı yalnız bir kez ödül verir ve olay defterinde
kalıcı olarak işaretlenir. Arşivlenip 30 gün içinde aynı normalize ad ve tutarla
yeniden oluşturulan hedef önceki ödül geçmişini devralır. Kilometre taşı
ödülleri dahil haftalık tohum üst sınırı kötüye kullanımı sınırlar. Üst sınıra
takılan tek seferlik kilometre taşı ödülü kaybolmaz; olay defterinde `bekliyor`
durumuna alınır ve sonraki haftalarda sınır dahilinde peyderpey cüzdana aktarılır.

### 3. Yaşayan orman, XP ve seviye

Orman seçilen finansal amaçtaki yerel türü öne çıkarır ve mevcut flora atlasını
korur. Takvim serisi ormanın sürekliliğini, hedef katkıları rota ilerlemesini,
görevler çeşitliliği ve XP ise genel ustalık seviyesini temsil eder.

XP kalıcıdır ve harcanmaz. Seviye atlamak yeni parselleri, mağaza raflarını,
mevsimleri ve bakım seçeneklerini açar. Orman büyümesi salt XP'ye değil; seri,
tamamlanan benzersiz davranışlar ve hedef kilometre taşlarının ağırlıklı,
deterministik birleşimine dayanır.

#### XP, seviye ve büyüme sözleşmesi

| Olay | XP | Sınır |
| --- | ---: | --- |
| Günün ilk anlamlı davranışı | 20 | Günde 1 |
| İkinci farklı davranış türü | 10 | Günde 1 |
| Günlük finans kontrolü | 10 | Günde 1 |
| Güvenilir fiş | 5 | Günde 1 |
| Doğrulanmış hedef katkısı | 15 | Günde 1 |
| Doğrulanmış borç ödemesi | 15 | Günde 1 |
| Haftalık değerlendirme | 30 | Haftada 1 |
| 7 / 30 / 100 günlük seri | 40 / 120 / 300 | Her eşik bir kez |
| Hedef yüzde 10 / 25 / 50 / 75 / 100 | 25 / 50 / 100 / 150 / 250 | Hedef ve eşik başına 1 |

Aynı davranış türünün tekrarı ek XP vermez. Tekrarlanabilir kaynaklar günde 50,
haftada 280 XP ile sınırlıdır; tekil seri ve hedef kilometre taşları bu sınıra
dahil değildir. Sürüm 1 seviye eşikleri şöyledir: seviye 1 `0`, 2 `100`, 3
`250`, 4 `450`, 5 `700`, 6 `1.000`, 7 `1.400`, 8 `1.900`, 9 `2.500`, 10
`3.200`; 11–20 için sırasıyla `4.000`, `4.900`, `5.900`, `7.000`, `8.200`,
`9.500`, `10.900`, `12.400`, `14.000`, `15.700` XP. Hedef denge, haftada
150–220 XP kazanan düzenli kullanıcının 4–5 haftada seviye 5'e ulaşmasıdır.

Ormanın temel büyüme yüzdesi aşağıdaki deterministik formülle hesaplanır:

`100 × (0,40 × min(toplamXP / 3.200, 1) + 0,25 × min(seri / 30, 1) +`
`0,20 × son7GündekiTamGün / 7 + 0,15 × anaHedefDurakOranı) + eşyaBonusu`

Sonuç `0–100` aralığında sınırlandırılır. Aşamalar yüzde `0–19` tohum, `20–39`
filiz, `40–64` fidan, `65–84` olgun ağaç ve `85–100` koruluktur. Görsel aşama
yüksek su izi olarak saklanır; katkı geri alındığında finansal rota gerileyebilir
ama orman görseli küçülmez. Yağmur suyu bir sonraki benzersiz davranışa `+2`
yüzde puan verir; bütün eşya bonuslarının toplamı `10` puanı aşamaz ve hiçbir
eşya XP/tohum çarpanı oluşturmaz.

Orman sahnesi telefonda akıcı katmanlı illüstrasyon ve küçük hareketlerle
çalışır. Hareket azaltma açıkken bütün hareketler statik duruma geçer. Web,
Android ve iOS aynı veri modelini ve görsel aşamaları kullanır.

Hedef rota haritası, düz bir ilerleme çubuğu yerine orman içinden geçen kıvrımlı
bir patikadır. Yüzde durakları taş işaretler, köprüler, yeni koruluklar ve mevsim
kapılarıyla görünür olur. Geçilmiş yol sıcak ve canlı, sıradaki durak belirgin,
uzak yol ise puslu ama okunabilir gösterilir. Harita finansal tutarları gizle
seçeneğine uyar ve dar telefonda yatay taşma üretmez.

Maki karakteri mevcut turuncu-beyaz-kahverengi guinea pig kimliğini, yeşil
kapüşonlusunu ve yüz oranlarını korur. Yeni ana modelin kulakları belirgin biçimde
yuvarlak, iki yanda simetrik ve tüylüdür; başın üstünde seyrek/kel alan yoktur.
Alın çizgisindeki beyaz tüy doğal ve dolgun devam eder. Aynı ana model; haritada
rehber, hedef durağında kutlayan, mağazada görevli, bildirimde nazikçe hatırlatan
ve PDF raporunda yorumlayan pozlara türetilir. Her poz aynı renk lekeleri, göz,
burun, hoodie ve vücut oranı karakter sözleşmesini kullanır.

### 4. Tohum cüzdanı ve orman mağazası

Tohum puanı yalnız oyun içi, harcanabilir bir değerdir. Gerçek para ile satın
alınamaz, nakde çevrilemez, finans bakiyesi gibi gösterilmez ve abonelikle
çarpanlanmaz. Tohum; günlük bakım, doğrulanmış fiş, hedef katkısı, haftalık
değerlendirme ve kilometre taşlarından kazanılır.

Mağazada kozmetik öğelerin yanında şu işlevli öğeler bulunur:

- **Koruma yaprağı:** kaçırılan tek günü korur.
- **Yağmur suyu:** sonraki uygun görevin orman gelişim etkisini artırır.
- **Baykuş rehber:** o güne uygun olmayan bir görevi bir kez değiştirir.
- **Sera:** seçili parselin dinlenme günündeki görsel sürekliliğini korur.
- **Pusula:** ana hedef için o günün en güvenli sonraki adımını öne çıkarır.

Hiçbir eşya gerçek finans getirisini artırmaz, yatırım sonucu vaat etmez veya
kullanıcıyı harcama yapmaya teşvik etmez. Satın alma, cüzdan düşümü ve envanter
ekleme tek yerel veritabanı işlemi içinde atomik yapılır.

#### Başlangıç ekonomi dengesi

| Olay | Tohum | Sınır |
| --- | ---: | --- |
| Günün ilk anlamlı davranışı | 8 | Günde 1 |
| İkinci farklı davranış türü | 4 | Günde 1 |
| Günlük finans kontrolü | 4 | Günde 1 |
| Güvenilir fiş bonusu | 3 | Günde 1 |
| Hedef katkısı | 5 | Günde 1 |
| Haftalık değerlendirme | 18 | Haftada 1 |
| 7 / 30 / 100 günlük seri | 20 / 60 / 160 | Her eşik bir kez |
| Hedef yüzde 10 / 25 / 50 / 75 / 100 | 15 / 25 / 40 / 60 / 100 | Hedef ve eşik başına 1 |

Tekrarlanabilir günlük kazanç 20 tohumla, bütün kaynakların haftalık toplamı 180
tohumla sınırlıdır. Düzenli ama aşırı kullanmayan bir kullanıcının haftalık hedefi
80–110 tohumdur.

| Ürün | Fiyat | Tür |
| --- | ---: | --- |
| Baykuş rehber | 35 | Tüketilebilir |
| Yağmur suyu | 55 | Tüketilebilir |
| Koruma yaprağı | 90 | Tüketilebilir; yaklaşık bir haftalık emek |
| Pusula | 280 | Kalıcı açılım |
| Sera | 450 | Kalıcı açılım |
| Kozmetik bitki/dekor | 80–700 | Koleksiyon |
| Yeni biyom veya mevsim bahçesi | 1.200–2.400 | Uzun vadeli açılım |

İlk mağaza kataloğunun toplam bedeli en az 5.000 tohum olur; 120 tohum/hafta
hızında bütün kataloğun açılması 40 haftadan kısa sürmez. Fazla tohum için her
mevsim yenilenen çiçek ekimi, parsel teması ve kalıcı koleksiyon rozeti bulunur.
Bu tüketim alanları fayda kaybı veya zorunlu bakım yaratmaz. Denge; gerçek
haftalık kazanım, satın alma süresi ve kullanılmayan bakiye dağılımı yalnız
cihazda ölçülerek sürüm bazında yeniden ayarlanabilir; geçmiş bakiye azaltılmaz.

### 5. Fişten güvenli otomatik gidere

PaddleOCR hattı Türkçe fişler için aşağıdaki biçimlerde güçlendirilir:

- `1.250,50`, `1250,50`, `1,250.50`, `1250.50` ve `1250` para biçimleri;
- `TL`, `TRY` ve lira simgesi;
- `TOPLAM`, `GENEL TOPLAM`, `ÖDENECEK`, `KART TOPLAMI` gibi etiketler;
- `TOPKAM`, `T0PLAM`, `T0P1AM` gibi sınırlı ve güvenli OCR karışmaları;
- toplam satırı ile KDV, ara toplam, para üstü ve kart numarası ayrımı;
- eğik, düşük kontrastlı ve gölgeli görüntü için birden çok ön işleme varyantı.

Toplam adayları etiket yakınlığı, sayfadaki dikey konum, OCR güveni ve diğer
tutarlarla tutarlılık üzerinden sıralanır. Otomatik kayıt için mağaza adı,
pozitif toplam ve toplam güveni eşik üstünde olmalı; parser `requires_review`
üretmemeli ve kategori güvenilir biçimde belirlenmelidir.

Sayısal otomatik kayıt kapısı şöyledir:

- toplam alan güveni en az `0,92`;
- mağaza alan güveni en az `0,85`;
- kategori güveni en az `0,95` veya kullanıcının daha önce onayladığı tam yerel
  mağaza eşleşmesi;
- toplamın pozitif olması, para biçiminin tek anlamlı çözüme sahip olması ve
  mutabakat kontrolünün geçmesi;
- `requires_review = false` olması.

En az 15 farklı fiş düzeninden, en az 500 izinli ve kişisel bilgileri
anonimleştirilmiş Türkçe fişten oluşan sürüm doğrulama setinde genel toplamın
kuruşuna kadar doğruluğu en az yüzde 96 olmalıdır. Otomatik kayda kabul edilen
alt kümede yanlış toplam veya kategoriyle otomatik kayıt oranı en fazla yüzde
0,5; başka bir ifadeyle otomatik kayıt precision değeri en az yüzde 99,5
olmalıdır. Desteklenen, okunabilir fişlerde otomatik kayıt kapsaması en az yüzde
65 hedeflenir; bu kapsama ulaşmak için precision eşiği düşürülemez.

Kategori, önce kullanıcının aynı mağaza için geçmişte onayladığı yerel eşlemeden,
sonra güvenli mağaza kurallarından bulunur. İlk kez görülen veya belirsiz mağaza
`Diğer` kategorisiyle sessizce kaydedilmez; hızlı onay ekranına düşer. Kullanıcının
onayı sonraki taramalar için yalnız cihazda mağaza-kategori eşlemesi oluşturur.

Başarılı OCR işinin kimliği gider kaydında teknik kaynak referansı olarak tutulur.
Aynı iş kimliği ikinci gideri veya ikinci ödülü oluşturamaz. Fiş görseli ve ham
OCR satırları işlem tamamlanınca saklanmaz.

Toplam ve kategori güvenleri ayrı izotonik kalibratörlerden geçer. Eğitim,
kalibrasyon ve son doğrulama ayrımı mağaza ve fiş düzenine göre gruplanır; aynı
mağaza/düzen ailesi iki parçaya sızamaz. Her desteklenen düzen doğrulamada en az
20 örnek taşır. Yüksek güven kovasında beklenen kalibrasyon hatası (`ECE`) en
fazla `0,03` olur; reliability eğrisi, Brier skoru, precision, recall ve otomatik
kapsam sürüm raporunda birlikte yayımlanır. Model, ön işleme, parser ya da kural
sürümü değiştiğinde kalibrasyon yeniden üretilir ve eşikler yeniden doğrulanır.
Kapalı doğrulama seti ilk sürümde 500 fiş/15 düzen, üretim olgunluğunda en az
2.000 fiş/40 düzen hedefler; eşik tutturmak için doğrulama seti elle seçilmez.

### 6. Akıllı ve gerçek bildirimler

Mevcut zaman seçme modeli gerçek bir bildirim düzenleyicisine bağlanır. Android
ve iOS'ta yerel bildirim uygulama kapalıyken çalışır. Bildirim izni ancak kullanıcı
takvim, hedef veya ormanın değerini gördükten sonra bağlamlı olarak istenir.

Kurallar:

- günde en fazla bir davranış bildirimi;
- kullanıcı tarafından ayarlanabilir sessiz saatler;
- o gün anlamlı davranış tamamlandıysa hatırlatmayı iptal etme;
- seri riski, hedef katkısı ve haftalık değerlendirme arasında öncelik seçme;
- bildirime dokununca ilgili gün, hedef veya orman görevine derin bağlantı;
- izin yoksa aynı öneriyi uygulama içi görev kartında gösterme.

Yerel öğrenme modeli yalnız sabah/öğle/akşam seçmez; hafta içi/sonu, son başarılı
zaman aralığı, bildirim türü ve açılıştan sonra anlamlı eylem yapılıp yapılmadığını
kullanır. Ham finans tutarı, hedef adı veya fiş mağazası model girdisi olmaz.
Kilit ekranında varsayılan bildirim metni tutar ve hedef adını göstermez.

Bir bildirimin başarı ödülü, teslimden sonra en geç altı saat içinde ve yerel gün
bitmeden tamamlanan benzersiz gelir/gider, fiş onayı, hedef katkısı veya günlük
kontroldür. Yalnız uygulama açılışı başarı sayılmaz. Ana ölçüm “teslim edilen
uygun bildirim başına anlamlı davranış” oranıdır; açılma oranı ikincil ölçümdür.
Bir zaman kolu en az 12 uygun gösterim görmeden model o kolu kalıcı olarak
bastıramaz. Kullanıcı başına günlük bir bildirim sınırı deneylerde de aşılamaz.

Zaman seçimi cihaz içinde bağlamsal Thompson Sampling ile yapılır. Kollar yerel
saatle `09:00`, `14:00`, `20:00`; bağlam girdileri sabit terim, hafta sonu,
bildirim türü, son başarılı zaman kolu ve bugün anlamlı davranış yapılıp
yapılmadığıdır. Katsayı öncülleri sıfır ortalamalı bağımsız normal dağılım,
keşif katsayısı `0,35` olur. Soğuk başlangıçta kullanıcının seçtiği saat; seçim
yoksa hafta içi `20:00`, hafta sonu `09:00` kullanılır. Her kol 12 uygun gösterim
görene kadar en az yüzde 10 keşif korunur; sonra taban keşif yüzde 5'tir.

Bir kol 12 gösterimden sonra yüzde 5'in altında anlamlı davranış üretirse yedi
gün dinlendirilir. Beş ardışık yanıtsız bildirim türün önceliğini bir kademe
düşürür; bildirimler tamamen kapanmaz, kullanıcı ayarı üstün gelir. Saat dilimi
üç saatten fazla değiştiğinde plan yerel güne yeniden bağlanır; önceki 72 saat
kısa vadeli zaman sinyalinden çıkarılır fakat uzun dönem öğrenme korunur. Kullanıcı
“bildirim öğrenmesini sıfırla” dediğinde yalnız model öncülleri ve etkileşim özeti
silinir. Finans tutarı, kategori, mağaza ve hedef adı hiçbir model girdisi olmaz.

Mesajlar suçlayıcı değildir. Örnekler: “Ormanının bugünkü küçük bakımı kaldı”,
“Rotanda güvenli bir adım var” ve “Bu haftanın orman günlüğü hazır”. Kullanıcı
bildirim türlerini ayrı ayrı kapatabilir.

### 7. Mevcut finans yüzeylerinin ürün seviyesinde tamamlanması

Yaşayan Orman yeni bir ada gibi eklenmez; mevcut finans yüzeyleri aynı kalite ve
dil seviyesine çıkarılır.

#### Borç kapatma planı

- “Ek Aylık Bütçe” alanı “Borçlara ayırabileceğin ek aylık tutar” olur ve değer
  yerel para birimiyle (`₺300` / `300 TL`) gösterilir.
- Başlığın altında sonuç vaadi yer alır: aylık bütçeye göre kapanış tarihi,
  toplam faiz ve ödeme sırası karşılaştırılır.
- Kullanıcı dostu ana adlar korunur; bilinen teknik adlar ikincil etikettir:
  “Toplam faizi azalt — Çığ yöntemi” ve “Küçük borçları kapat — Kartopu yöntemi”.
- “Dengeli ilerle”, faiz maliyeti ile hızlı kapanışı dengelediğini açıklar.
- “Kendi yolunu çiz” kopuk bir düğme değil, altıncı ödeme yolu olarak
  “Özel ödeme sırası oluştur” başlığı ve “Borçlarının ödeme sırasını kendin
  belirle” açıklamasıyla aynı listede bulunur.
- Borç yokken merkezde açıklamalı boş durum ve “İlk Borcumu Ekle” birincil eylemi
  görünür; üstteki “Borç Ekle” eylemi de korunur.
- Hesaplama düğmesi yalnız geçerli borç ve bütçe varken etkinleşir; etkin durumda
  tema vurgusuyla açıkça ayırt edilir.
- Marka etiketi okunur büyüklüğe çıkarılır; pasif seçim göstergesi kontrastı,
  ikon çizgi ağırlıkları, klavye odağı ve web hover/cursor durumları eşitlenir.
- Doğrulanmış borç ödemesi takvimde anlamlı davranış sayılır. Bağlı finans
  hareketiyle kanıtlanan ödemeler bir kez XP/tohum verir; aynı hareket hedef
  katkısına da bağlanmışsa yalnız yüksek olan tek ödül uygulanır.
- Borcun yüzde 25, 50 ve 100 anapara kapanışları Mersin florasından ayrı rota
  işaretleri açar. Görsel ödül finans borcunu azaltmaz ve ödeme geri alınırsa
  rota yeniden hesaplanır; tekil ödül tekrar verilmez.

#### Gelir/Gider ana yüzeyi

- Yatay görev şeridi metni kesmez. Dar ekranda görevler erişilebilir yatay
  kaydırma ve son öğede yeterli güvenli boşlukla çalışır; büyük metinde kart veya
  iki satırlı düzene geçer.
- Yüzen Maki/koç balonu navigasyon işlevini tooltip, semantik etiket ve sürükleme
  davranışıyla açıklar; salt dekor olarak görünmez ve hiçbir CTA'yı kapatmaz.
- İşlem yokken boş alan yukarı alınır; seçili gün bağlamında “İlk harcamamı ekle”
  veya “İlk gelirimi ekle” merkezi eylemi sunulur.
- Geniş ekranda hedef kartı ve haftalık takvim görsel ağırlığı dengelenir; sağ
  kart ezilmez. Sakin, suçlamayan Maki cümleleri korunur.

#### Harcama tahmini

- “Yeterli geçmiş yok” tek satırlık son durum değildir. Hazırlık kartı kaç farklı
  günde kayıt bulunduğunu ve sıradaki eylemi gösterir.
- Dört farklı kayıt günü ilk eğitim eşiğidir: kullanıcıya düşük güvenli, açıkça
  “erken görünüm” olarak etiketlenen örnek aralık ve silik yedi günlük grafik
  gösterilebilir. Bu sonuç model tahmini veya finansal vaat olarak sunulmaz.
- Üretim tahmini mevcut 56 günlük doğrulanmış seri eşiğini korur. İlerleme `x/56
  gün` olarak görünür ve “Harcama ekle” eylemi seçili güne gider.
- Metin “yapay zekâ tabanlı” teknoloji iddiasını öne çıkarmak yerine,
  “Geçmiş davranışlarına göre önümüzdeki 7 günün olası harcama aralığını gör”
  faydasını anlatır.
- Boş durumda gelecekte oluşacak grafiğin iskeleti ve beklenen gün etiketleri
  görünür; sayfa yüklenmemiş yönetim paneli gibi boş kalmaz.
- Üretim modeli 56 günlük doğrulanmış seride hareketli zaman doğrulamasıyla
  ölçülür. Son 14 gün test penceresidir; eğitim penceresi geçmişe doğru genişler
  ve gelecek verisi eğitimde kullanılamaz. Tahmin, son dört aynı haftanın günü
  medyanını kullanan mevsimsel saf modele karşı WAPE'de en az yüzde 10 iyileşmeli;
  WAPE en fazla yüzde 30 olmalı ve yüzde 80 tahmin aralığının gerçek kapsaması
  yüzde 75–90 arasında kalmalıdır. Bu kapılar geçmezse tek sayı yerine yalnız
  geniş “erken görünüm” aralığı gösterilir.

#### Birikim Konumum

- Negatif ve yargılayıcı yüzdelik cümlesi yerine yolculuk dili kullanılır:
  “Tasarruf yolculuğunun ilk yüzde 25'lik bölümündesin” gibi.
- Haftalık tasarruf oranı, benzer grubun anonim aralık/ortalaması, yüzdelik konum
  ve bir sonraki gruba açıklanabilir mesafe birlikte gösterilir.
- Yüzdelik konum yatay 0–100 çizgisi üzerinde işaretlenir. “Ağaç / Seviye” bilgisi
  karşılaştırma metriğine karıştırılmaz; orman ilerlemesine ayrı bağlantı olur.
- Bir üst gruba yaklaşma önerisi yalnız gerçek yerel gelir-gider verisi ve
  backend'in döndürdüğü kova sınırıyla hesaplanabiliyorsa sayısallaştırılır.
  Aksi halde kesin `150 TL` benzeri uydurma tutar verilmez; davranış yönü ve
  tahmini olduğu açıkça yazılır.
- Anonim grup verisi yoksa yerel tahmin “tahmini” etiketi taşır ve kullanıcının
  kendi önceki haftasıyla karşılaştırma birincil olur.

Üretimde bu yüzey “liderlik tablosu” değildir. Kullanıcı açıkça katılmadan karşılaştırma
isteği gönderilmez. Sunucuya ham tutar/hareket değil; en az beş puanlık kovaya
yuvarlanmış tasarruf oranı, geniş yaş/hanede yaşayan kişi bandı ve anonim teknik
istek kimliği gider. Bir grup en az `k=50` gerçek, son 30 günde etkin katılımcı
olmadan yüzdelik döndürmez. Sonuç beş yüzdelik puanlık kovalar halinde gelir ve
grup büyüklüğü `50–99`, `100–499`, `500+` olarak gösterilir. Aynı grubu daraltarak
kişileri çıkarsamayı önlemek için istekler hız sınırlıdır. Gerçek grup yoksa
“anonim referans aralığı” veya yalnız kişinin geçmişi kullanılır; sahte kullanıcı
sayısı ya da uydurma sıra gösterilmez.

#### Kişisel fiyat değişimi

Kullanıcının kişisel fiyat değişimi son 90 gündeki yerel kategori harcama
ağırlıkları ile Türkiye İstatistik Kurumunun resmi, sürüm ve tarih bilgisi gösterilen
TÜFE ana harcama grubu endekslerinin ağırlıklı birleşimidir. Ham finans hareketi
cihazdan çıkmaz; uygulama yalnız yayımlanmış endeks verisini indirir. Yerel
kategorilerin resmi gruplara eşleme kapsaması yüzde 70'in altındaysa tek oran
gösterilmez ve “veri yetersiz” açıklaması verilir. Kullanıcı kullanılan kategori
ağırlıklarını, resmi veri ayını ve kaynak bağlantısını görebilir. Sonuç resmi
enflasyon oranı veya yatırım tavsiyesi olarak sunulmaz; “senin harcama dağılımına
göre fiyat değişimi” olarak adlandırılır.

## Bileşen ve veri sınırları

### Yerel tablolar

- `SavingsGoals`: hedef kimliği, başlık, hedef tutarı, başlangıç tutarı, tarih,
  ana/yan sırası, durum ve simge.
- `GoalContributions`: hedef, tutar, tarih, not, kaynak türü, ödül durumu ve
  benzersiz kaynak kimliği; bağlı finans hareketinde tekil indeks.
- `DailyForestActivities`: gün, davranış türü, kaynak kimliği, XP ve tohum ödülü.
- `ForestXpLedger`: değiştirilemez XP kazanım/ters kayıtları, neden ve tekil olay
  kimliği; seviye doğrudan bu toplamdan türetilir.
- `ForestWalletLedger`: artı/eksi tohum hareketi, neden ve benzersiz olay kimliği.
- `ForestInventory`: ürün, adet, kullanım durumu ve seçili parsel.
- `ForestStreakState`: mevcut seri, en iyi seri, son tamamlanan gün ve koruma
  bilgisi.
- `MerchantCategoryMappings`: normalize mağaza anahtarı ve onaylı kategori.
- `NotificationEngagements`: tür, zaman dilimi, planlandı/açıldı/eylem yapıldı
  durumu; finansal içerik taşımaz.
- `GoalMilestoneAwards`: hedef ve yüzde durağı için tekil ödül kaydı ile ödül
  hesabında kullanılan değiştirilemez en yüksek hedef tutarı.
- `BackupManifests`: yalnız dışa aktarma sürümü ve son başarılı yedek zamanı;
  parola, anahtar veya yedek içeriği taşımaz.

Mevcut gelir, gider, gamification ve bildirim tabloları silinmez. Şema geçişi
tekrarlanabilir ve mevcut kullanıcı verisini koruyacak şekilde ilerler.

### Servis sınırları

- `ReceiptExpenseCoordinator`: OCR sonucunu güven eşiğine göre otomatik kayıt veya
  incelemeye yönlendirir.
- `DailyActivityEngine`: benzersiz davranışı gün, seri, XP ve tohum hareketine
  dönüştürür.
- `GoalRouteService`: hedef katkısı, önerilen aralık ve harita duraklarını üretir.
- `ForestEconomyService`: cüzdan, satın alma, envanter ve tüketilebilir öğeleri
  yönetir.
- `SmartNotificationOrchestrator`: izin, zamanlama, iptal, derin bağlantı ve yerel
  öğrenme geri bildirimini yönetir.

Bu servisler ekranlardan bağımsızdır. Finans kaydı tek gerçek kaynak olarak mevcut
transaction repository'de kalır.

## İşlem ve hata kuralları

- Gider ekleme ile günlük aktivite ödülü atomik yapılır; biri başarısızsa ikisi de
  geri alınır.
- Hedef katkısı, rota ilerlemesi ve ödül aynı benzersiz katkı kimliğini kullanır.
- Tohum bakiyesi yetersizse satın alma hiçbir değişiklik yapmadan açıklanır.
- Bildirim planlama hatası uygulamayı veya finans kaydını engellemez.
- OCR modeli hazır değilse kamera akışı korunur ve manuel gider formuna geçiş
  sunulur.
- Toplam bulunamazsa mağaza adı korunur, tutar alanı odaklanır ve kullanıcıdan
  yalnız eksik bilgi istenir.
- Tarih/saat dilimi değişiminde seri yerel takvim günü üzerinden yeniden
  değerlendirilir; aynı gün iki kez ödüllendirilmez.
- Hedefin silinmesi katkı geçmişini arşivler; finans işlemlerini silmez.
- Uygulama çökmesi veya işlem tekrarı çift gider, çift katkı, çift XP ya da çift
  tohum üretemez.

## Gizlilik ve güvenlik

- Gelir, gider, hedef, katkı, seri, cüzdan, envanter ve bildirim etkileşimleri
  cihazda saklanır; yeni bulut senkronizasyonu eklenmez.
- Fiş görseli mevcut geçici iş hattında tutulur ve iş tamamlanınca silinir. Ham
  OCR satırları, mağaza adı ve tutar loglara yazılmaz.
- Mağaza-kategori öğrenmesi yalnız cihazda yapılır.
- Bildirim zaman modeli yalnız cihazda öğrenir; kişisel finans metni model girdisi
  veya telemetri olmaz.
- Kilit ekranı bildirimleri varsayılan olarak hassas tutar, hedef adı ve mağaza
  adı içermez.
- Analitik olaylar gerekiyorsa yalnız özellik durumu ve anonim teknik hata kodu
  taşır; finans değeri taşımaz.
- Kullanıcı tüm hedef, orman ekonomisi ve bildirim öğrenme verisini ayarlardan
  silebilir. Silme mevcut gizlilik temizliğiyle birlikte çalışır.
- Tohum puanı gerçek para, kripto varlık, çekiliş bileti veya parasal hak değildir.

### Şifreli kurtarma dosyası

Telefon kaybı ve cihaz değişimi için kullanıcı isteğe bağlı `.maki-backup`
dosyası oluşturabilir. Dosya; gelir/gider, hedef, katkı, takvim, seri, XP, tohum,
envanter, kullanıcı tercihleri ve mağaza-kategori eşlemelerini içerir. Fiş
görseli, ham OCR metni, erişim belirteci, Gemini anahtarı, bildirim izni ve cihaz
kimliği yedeğe girmez.

Arşiv sürümlü bir manifest taşır ve kullanıcı parolasıyla türetilen anahtar
üzerinden AES-256-GCM ile doğrulanmış olarak şifrelenir. Her dışa aktarmada yeni
128 bit salt ve benzersiz 96 bit nonce üretilir. Anahtar türetme Argon2id için
en az `m=19 MiB`, `t=2`, `p=1` kullanır ve hedef cihazda bir saniyenin altında
kalacak biçimde yalnız yukarı doğru ayarlanabilir. Parola veya türetilmiş anahtar
saklanmaz.

İçe aktarma önce kimlik doğrulama etiketini, şema sürümünü, boyut sınırını ve
kayıt sayılarını doğrular; sonra kullanıcıya bir önizleme sunar. Yanlış parola
ve bozuk dosya mevcut veriyi değiştirmez. Onaylı geri yükleme tek veritabanı
işlemidir ve işlem öncesi geçici geri dönüş noktası oluşturur. Mobilde sistem
paylaşım sayfasıyla Drive/iCloud gibi kullanıcının seçtiği alana kaydedilebilir;
Maki bu sağlayıcılara hesap erişimi almaz. Web'de dosya indirme/yükleme kullanılır.

Dışa aktarma parolası en az 12 karakter veya boşluklarla ayrılmış en az dört
kelimelik parola cümlesi olur ve iki kez girilir. Güç uyarısı gösterilir; Maki
parolanın kurtarılamayacağını açıkça söyler. Şifrelenmemiş arşiv veya JSON ara
dosyası diske yazılmaz; içerik akış halinde şifrelenir, paylaşım/iptal/hata
sonunda geçici şifreli dosya temizlenir. Kullanıcı isterse içe aktarma önizlemesinde
tutarları maskeleyebilir. Uygulama mevcut ve önceki iki yedek şema sürümünü okur;
daha eski dosyayı mevcut veriye dokunmadan “önce uyumlu bir Maki sürümüne aktar”
mesajıyla reddeder. Yanlış parola ile bozuk dosya aynı genel hata metnini kullanır
ve mevcut veri, sayaçlar ya da başarısız deneme dışı durum değişmez.

Bu seçim, OWASP'ın Argon2id asgari parametreleri ve NIST'in doğrulanmış şifreleme
için GCM tanımıyla uyumludur.

## Sayısal ürün kabul eşikleri

- **OCR otomatik kayıt:** toplam ≥ 0,92; mağaza ≥ 0,85; kategori ≥ 0,95;
  otomatik kayıt yanlış oranı ≤ yüzde 0,5.
- **OCR toplam doğruluğu:** izinli doğrulama setinde kuruşuna kadar ≥ yüzde 96;
  okunabilir desteklenen fişlerde otomatik kapsam ≥ yüzde 65.
- **Bildirim davranışı:** teslimden sonraki altı saat ve gün bitmeden anlamlı
  davranış; yalnız açılış başarı değildir.
- **Orman açılışı:** Redmi 9 sınıfı 4 GB düşük seviye Android cihazda release
  yapısında rota dokunuşundan etkileşimli ilk kareye sıcak p95 ≤ 0,9 saniye,
  soğuk p95 ≤ 1,8 saniye.
- **Orman akıcılığı:** hedef 60 FPS; ölçülen karelerin en az yüzde 95'i UI ve
  raster iş parçacığında 16,7 ms altında; 100 ms üzeri kare yok; üç ardışık
  kaçırılmış kare kümesi yok.
- **Ekonomi:** olağan kullanıcı 80–110 tohum/hafta; tekrarlanabilir 20/gün ve
  bütün kaynaklar 180/hafta üst sınırı; başlangıç kataloğu en az 5.000 tohum.

Performans eşikleri aynı veri seti ve aynı release yapı üzerinde en az 30 tekrar
ile ölçülür. Debug profil sonuçları kabul kanıtı olarak kullanılamaz.

## Test sözleşmesi

### Backend OCR

- Türkçe ve uluslararası para biçimleri doğru kuruşa çevrilir.
- Etiket OCR karışımları yalnız izinli benzerlik sınırında kabul edilir.
- KDV, para üstü, kart son hanesi ve ara toplam genel toplam seçilmez.
- Birden çok toplam adayı deterministik sıralanır.
- Düşük güven ve mutabakat hatası `requires_review` üretir.
- Fiş bytes ve ham OCR içeriğinin kalıcı saklama veya loga sızma testi korunur.

### Flutter veri ve alan testleri

- Şema yükseltme mevcut gelir/gider ve XP verisini korur.
- Aynı kaynak kimliği çift gider veya çift ödül oluşturmaz.
- Seri 48 saatlik onarım, koruma yaprağı, saat dilimi ve gün sınırlarında doğrudur.
- Bir ana ve en fazla üç yan aktif hedef kuralı korunur.
- Rota durakları hedef değişiminde deterministiktir.
- Hedef tutarını düşürmek, yükseltmek, arşivlemek ve yeniden oluşturmak aynı
  kilometre taşı ödülünü tekrar vermez.
- Cüzdan ve satın alma atomik; negatif bakiye imkânsızdır.
- XP harcanamaz ve tohum bakiyesinden bağımsızdır.
- Bildirim yalnız uygun ve eksik davranış için planlanır; eylem tamamlanınca iptal
  edilir.
- Dört katkı kaynak türü banka bakiyesini değiştirmez; yalnız doğrulanmış kaynak
  tam ödül verir ve silme/ters kayıt çift kazanç üretmez.
- XP olayı sınırları, 20 seviye eşiği, büyüme formülü ve görsel yüksek su izi
  tablo-güdümlü altın testlerle doğrulanır.
- Thompson Sampling testlerinde saat, rastgelelik ve saat dilimi enjekte edilir;
  soğuk başlangıç, keşif, dinlendirme ve sıfırlama deterministik doğrulanır.
- OCR kalibrasyon ayrımı mağaza/düzen grubu sızıntısını engeller; ECE, Brier,
  precision, recall ve kapsam kapıları kapalı sette geçmeden otomatik kayıt açılmaz.

### Arayüz ve platform testleri

- Haftalık karttan tam takvime, takvimden güne, bildirimden doğru hedefe derin
  bağlantı çalışır.
- 320×640, 390×844, 844×390 ve geniş web görünümünde taşma olmaz.
- Büyük metin ve ekran okuyucuda gün, seri, bakiye ve mağaza eylemleri anlaşılır.
- Hareket azaltma açıkken orman ve ödül animasyonları durur.
- Android ve iOS bildirim izin reddi uygulama içi akışı bozmaz.
- Web'de bildirim desteği yoksa uygulama içi görev merkezi eksiksiz çalışır.
- Redmi 9 sınıfı cihazdaki performans ölçümleri sayısal kabul eşiklerini sağlar.
- Yuvarlak kulaklı, dolgun tüylü Maki modeli bütün pozlarda karakter sözleşmesini
  korur; seyrek veya kel baş görünümü oluşmaz.
- Borç ekranında para birimi, altı ödeme yolu, açıklamalı boş durum, aktif/pasif
  CTA ve klavye odağı doğru çalışır.
- Gelir/Gider görevleri dar ekran ve büyük metinde kesilmez; koç balonu CTA veya
  içerik üstünü kapatmaz.
- Tahmin hazırlık durumu dört günlük erken görünüm ile 56 günlük üretim eşiğini
  açıkça ayırır; boş durumdan ilgili güne gider eklenebilir.
- Karşılaştırma ekranı yüzdelik çizgisini, veri kaynağı durumunu ve yalnız
  hesaplanabilir gelişim önerisini gösterir; ağaç seviyesi finans metriği gibi
  sunulmaz.
- Tahmin modeli mevsimsel saf modeli geçmediğinde kesin aralık göstermez; kişisel
  fiyat değişimi yüzde 70 eşleme kapsamı olmadan tek oran üretmez.
- Birikim Konumum katılım kapalıyken ağ isteği yapmaz; `k<50` grupta yüzdelik,
  sahte kişi sayısı veya dar grup bilgisi göstermez.

### Yedekleme testleri

- Yanlış parola, değiştirilmiş GCM etiketi, tekrarlanan nonce, aşırı büyük arşiv
  ve desteklenmeyen şema güvenli biçimde reddedilir.
- Yedek erişim belirteci, API anahtarı, fiş görseli veya ham OCR metni içermez.
- Dışa aktarma ve geri yükleme sonrası finans toplamları, hedef katkıları, seri,
  cüzdan defteri ve envanter birebir aynıdır.
- İçe aktarma yarıda kesilirse mevcut veriler korunur.

## Başarı ölçütleri

- Güvenilir fiş tek akışta gider olur; belirsiz fiş yanlış tutarla kaydolmaz.
- Kullanıcı takvimden bugünkü finans durumunu ve seriyi iki dokunuştan az sürede
  anlar.
- Her XP, tohum ve orman büyümesi açıklanabilir bir davranışa bağlanır.
- Hedef haritası kalan tutarı, sürdürülebilir katkı aralığını ve varış tahminini
  açıkça gösterir.
- Bildirimler günde bir sınırını aşmaz ve tamamlanmış gün için gönderilmez.
- Mevcut veriler ve gizlilik garantileri sürüm yükseltmesinde korunur.
- Şifreli kurtarma dosyasıyla cihaz değişiminde hedef, seri ve orman eksiksiz geri
  yüklenir; Maki kullanıcının bulut hesabına erişmez.
- Borç, ana finans, tahmin ve karşılaştırma ekranlarında boş durum kullanıcıya
  sonucu, veri gereksinimini ve tek bir sonraki eylemi açıkça gösterir.

## Teslim sürümleri ve kapılar

Bu şartnamenin tamamı uygulanır; aşamalar kapsam azaltma değil, güvenli teslim
sırasıdır. Bir aşama kendi veri geçişi, kabul eşiği ve geri dönüş testi geçmeden
sonraki aşamaya temel olmaz.

1. **Maki 1.1 — Finans günlüğü:** tam takvim, seri, temel XP, tek ana hedef,
   rota, temel orman büyümesi ve şifreli kurtarma dosyası.
2. **Maki 1.2 — Güvenilir fiş:** kalibre OCR, hızlı inceleme, otomatik gider,
   mağaza-kategori öğrenmesi ve uçtan uca tekillik.
3. **Maki 1.3 — Orman ekonomisi:** tohum defteri, mağaza, envanter, eşya etkileri,
   kilometre taşları ve kötüye kullanım ters kayıtları.
4. **Maki 1.4 — Akıllı rehber:** bağlamsal bildirim seçimi, katkı aralığı,
   bildirim davranış ölçümü ve açıklanabilir öneri.
5. **Maki 1.5 — Rapor ve ürün tamamlama:** cihaz içi Typst raporları, borç,
   tahmin, kişisel fiyat değişimi, Birikim Konumum ve platform sertleştirmesi.

Her sürüm mevcut yerel veriyi koruyan ileri şema geçişi ve temiz kurulum testiyle
çıkar. Özelliğin yarım verisi sonraki aşamada geçici ekran olarak kullanıcıya
gösterilmez.

## Kapsam dışı

- Banka hesabından otomatik para transferi.
- Gerçek para ile tohum veya mağaza ürünü satın alma.
- Yatırım getirisi, kredi ürünü veya kesin varış tarihi garantisi.
- Sosyal medya benzeri herkese açık orman profili.
- Bu belgede Typst PDF üretiminin görsel ve teknik ayrıntıları; ayrı spec'te ele
  alınacaktır.

## Güvenlik referansları

- OWASP Password Storage Cheat Sheet, Argon2id asgari çalışma parametreleri:
  https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
- NIST SP 800-38D, GCM doğrulanmış şifreleme modu:
  https://csrc.nist.gov/pubs/sp/800/38/d/final
