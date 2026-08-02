# Kişisel Harcama Enflasyonu ve Finans Baskısı

## Amaç

Ürün-fiyat sepeti girişini teslim kapsamından çıkarıp kullanıcının zaten kaydettiği
gelir ve giderlerden anlaşılır, cihaz içinde çalışan bir içgörü üretmek. Ekran iki
farklı kavramı birbirine karıştırmadan gösterir:

1. Kullanıcının aylık tüketim harcaması değişimi ve aynı dönem TÜİK aylık TÜFE
   değişimi.
2. Gelir, gider ve borç ödemelerine dayalı kişisel finans baskısı.

## Hesaplama

- Güncel pencere son 30 gün, karşılaştırma penceresi ondan önceki 30 gündür.
- Borç, kredi, kredi kartı ve taksit ödemeleri başlık/kategori anahtarlarından
  belirlenir. Bu ödemeler tüketim harcaması değişiminden çıkarılır ve yalnız borç
  yüküne katılır.
- İki pencerede en az üçer tüketim gideri varsa kişisel harcama değişimi
  `(güncel gider / önceki gider - 1) * 100` olarak hesaplanır.
- Resmî karşılaştırma mevcut backend sözleşmesindeki son iki TÜİK genel TÜFE
  endeksinin aylık değişimidir. Sonuçlar yüzde puan farkıyla sunulur.
- Finans baskısı 0–100 aralığındadır: gider/gelir yükü 60 puan, borç
  ödemesi/gelir yükü 25 puan, pozitif harcama ivmesi 15 puan ağırlığındadır.
  Gelir yoksa kesin skor yayımlanmaz; eksik veri durumu gösterilir.
- Bu sonuç resmî TÜFE veya finansal tavsiye olarak etiketlenmez. Arayüzde
  “kişisel harcama değişimi” ifadesi kullanılır.

## Arayüz

- “Sepetime fiyat ekle” eylemi ve sepet yeterlilik metinleri kaldırılır.
- Özet kartında kişisel harcama değişimi, TÜİK aylık oranı, yüzde puan farkı,
  gelir, gider, net nakit, borç yükü ve finans baskısı gösterilir.
- Maki; finans baskısı düşük ve kişisel değişim TÜİK oranının altındaysa gururlu,
  aksi durumda destekleyici/endişeli görsel kullanır.
- Paylaş/PNG akışı korunur; dosya ve paylaşım metni “kişisel finans özeti” olarak
  güncellenir.
- Yeterli iki dönem yoksa TÜİK oranı yine görünür, kişisel oran yerine “Veri
  birikiyor” gösterilir ve mevcut finans özeti sunulur.

## Veri ve Gizlilik

- Ham gelir/gider kayıtları cihazdan çıkmaz. Backend’e yalnız mevcut resmî TÜİK
  snapshot isteği yapılır.
- Web preview sentetik veride çalışır; Android debug kurulum test oturumuyla
  açılır. Production kimlik/güvenli oturum zorunluluğu emülatör derlemesinde
  etkinleştirilmez.

## Kabul Kriterleri

- Sepet giriş düğmesi ve sepet bekleme metni görünmez.
- İki 30 günlük dönemde yeterli veri varsa kişisel değişim deterministik hesaplanır.
- TÜİK değeri varsa karşılaştırma ve yüzde puan farkı görünür.
- Gelir/gider/borç göstergeleri gerçek yerel kayıtlardan gelir.
- Eksik veri sahte `0%` üretmez.
- PNG indirme/paylaşma çalışır.
- İlgili birim/widget testleri ve `dart analyze` hatasız geçer.
