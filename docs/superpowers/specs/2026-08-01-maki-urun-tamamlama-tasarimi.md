# Maki Ürün Tamamlama Tasarımı

Tarih: 1 Ağustos 2026
Durum: Kullanıcı tarafından A yaklaşımı onaylandı

## Amaç

Bu ek tasarım, Maki’nin son kullanıcıda eksik veya bozuk görünen dört yüzeyini
tamamlar: Yaşayan Orman rota detayı, Akıllı Bildirim Merkezi, cihaz profili ve
cihaz içi rapor/enflasyon deneyimi. PDF üretiminin ayrıntılı sözleşmesi
`2026-08-01-maki-typst-kullanim-raporlari-design.md` belgesidir; bu belge o
sözleşmenin uygulamadaki giriş noktalarını kesinleştirir.

## 1. Orman rota detayı

- Rota detayı ayrı, geri çıkılabilir tam ekran sayfadır.
- Üst görsel telefonlarda ekran yüksekliğinin en fazla yüzde 24’ünü, geniş
  ekranlarda en fazla 240 pikseli kullanır.
- Bilgi kartı sabit yüzde 34 üst boşlukla aşağı itilmez. Güvenli alan içinde,
  üst görselin altına bindirilen kaydırılabilir içerik olarak başlar.
- Geri düğmesi sistem güvenli alanında kalır; içerik yüksekliği ne olursa olsun
  ilk ekranda rota adı ve tür adı görünür.
- 360×640, 390×844, yatay telefon ve 1280×720 web kabul boyutlarında sarı/siyah
  taşma şeridi veya erişilemeyen eylem bulunamaz.

## 2. Akıllı Bildirim Merkezi

- Son kullanıcı ekranı yalnız akıllı zamanlama anahtarı, Maki’nin önerdiği saat
  ve kısa gizlilik açıklamasını gösterir.
- Hassasiyet matrisi, `b` vektörü, bandit kol adları, simülasyon seçicisi ve
  “açıldı say” düğmesi debug derlemesinde bile müşteri yüzeyine çıkmaz.
- Öğrenme motoru ve yerel veritabanı çalışmaya devam eder; yalnız teşhis arayüzü
  kaldırılır. Motor davranışı birim testleriyle doğrulanır.

## 3. Cihaz profili ve yaş

- Profil oluştururken ad ve `13–100` aralığında tam sayı yaş zorunludur; e-posta
  isteğe bağlı kalır.
- Sayısal klavye, rakam dışı giriş engeli ve anlaşılır aralık hatası kullanılır.
- Yaş mevcut şifreli cihaz profili JSON’una geriye uyumlu, nullable alan olarak
  eklenir. Eski profiller açılır; profilde “Yaş ekle” çağrısı görünür.
- Yaş profil ekranından değiştirilebilir. Tam yaş yalnız cihazda tutulur.
  Karşılaştırma gerektiğinde uygulama `13–17`, `18–24`, `25–34`, `35–44`,
  `45–54`, `55+` aralığını üretir; ağ isteğine kesin yaş eklenmez.

## 4. Raporlarım merkezi

- Ayarlar’da görünür bir **Raporlarım** öğesi bulunur; gizli geliştirici menüsü
  veya premium anahtarına bağlı değildir.
- Merkez günlük, haftalık ve aylık dönem seçimi; tutarları gizle; işlem dökümü
  ekle; önizle; PDF indir ve paylaş eylemlerini sunar.
- Snapshot mevcut yerel işlem, hedef ve orman servislerinden salt okunur üretilir.
  Finans verisi PDF oluşturmak için cihaz dışına çıkmaz.
- Üretim, mevcut cihaz içi Typst rapor şartnamesindeki renderer/coordinator
  sınırlarını kullanır. Android ve web bu çalışma ortamında çalışır biçimde
  doğrulanır; iOS aynı arayüzü kullanır ancak imza ve fiziksel test Mac kapısıdır.
- Rapor motoru veya dönem verisi hazır değilse sahte PDF üretilmez; kullanıcıya
  açıklanabilir hata ve yeniden dene eylemi gösterilir.

## 5. Kişisel enflasyon ve 3D Maki kartı

- 3D Maki sonuç kartı ekranın ilk içerik bölümünde her zaman görünür.
- Eşleşmiş fiyat sepeti yoksa kartta rakam yerine `—`, “Veri bekleniyor” etiketi
  ve hangi verinin gerektiği gösterilir. Bu önizleme “Örnek” olarak işaretlenir;
  indirme/paylaşma düğmeleri gerçek sonuç oluşana kadar kapalıdır.
- Gerçek kişisel ve resmî karşılaştırma değerleri geldiğinde aynı kart otomatik
  olarak gururlu veya ilgili Maki pozuna geçer; PNG indir/paylaş etkinleşir.
- Toplam harcamadan fiyat enflasyonu uydurulmaz. Eşleşmiş birim fiyat yoksa sonuç
  üretilmez ve kullanıcı yanıltılmaz.

## Veri akışı ve geriye uyumluluk

1. Profil yaşı `UserEntity → AuthEvent → AuthRepository → secure storage`
   hattından geçer.
2. Eski JSON kaydında yaş yoksa okuma başarısız olmaz.
3. Rapor snapshot’ı yalnız beyaz listeli alanları okur; cihaz kimliği, API
   anahtarı, fiş görseli ve ham OCR metni dışarıda kalır.
4. Enflasyon önizlemesi veri modelini değiştirmez; nullable değerleri dürüst boş
   durum olarak gösterir.

## Hata ve erişilebilirlik

- Bütün yeni alanlarda Türkçe açıklama, semantik etiket, en az 48 piksel dokunma
  alanı ve klavye ile erişim bulunur.
- Yaş doğrulama hatası alanın yanında ve ekran okuyucuya duyurulur.
- PDF iptali/kaydetme hatası finans verisini değiştirmez ve kısmi dosya bırakmaz.
- Küçük ekranda rota/PDF diyalogları `SafeArea` ve kaydırılabilir içerik kullanır.

## Test ve kabul kapıları

- Rota detayı dört hedefte telefon, yatay telefon ve web boyutlarında taşmaz.
- Bildirim ekranında `precision`, `matrix`, `b =`, `debug`, `simülasyon` müşteri
  metni bulunmaz.
- Yaş için 12, 101, boş ve rakam dışı giriş reddedilir; 13 ve 100 kabul edilir;
  eski yaşsız profil okunur.
- Raporlarım öğesi Ayarlar’da görünür; günlük/haftalık/aylık seçimleri renderer’a
  doğru dönemi iletir; gizli tutar çıktısında para sızıntısı aranır.
- Enflasyon kartı boş veride 3D Maki ve “Veri bekleniyor” gösterir; gerçek veride
  doğru pozu, yüzde farkını, indirme ve paylaşma eylemlerini gösterir.
- Tam Flutter test paketi, web release derlemesi ve bağlı Android cihaz debug APK
  derlemesi/kurulumu başarılı olmadan çalışma tamamlanmış sayılmaz.

## Kapsam sınırı

Bu çalışma yeni sosyal hesap, bulut profil, banka entegrasyonu veya toplam
harcamadan tahmini enflasyon üretmez. Mevcut gizlilik ve yerel-öncelikli mimari
korunur.
