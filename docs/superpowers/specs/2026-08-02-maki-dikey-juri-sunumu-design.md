# Maki Dikey Telefonlu Jüri Sunumu Tasarımı

**Tarih:** 2 Ağustos 2026

**Durum:** Kullanıcı tarafından onaylandı

**Teslim:** Yerel `.pptx` dosyası ve 12 adet 1920×1080 PNG; GitHub'a gönderilmez

## Amaç

Maki'yi hem ürün deneyimi hem de teknik güvenilirlik açısından anlatan, gerçek
Android ekranlarına dayalı 12 slaytlık bir jüri sunumu hazırlamak. Sunum, telefonun
ve uygulamanın dikey göründüğü gerçek portre ekran görüntülerini kullanır. Görsel
dil; üretken görsel kalabalığından, anlamsız dekorlardan ve şablon hissinden uzak,
editoryal ve markaya özgü olmalıdır.

## Değerlendirilen yaklaşımlar

1. **12 slayt ürün hikâyesi + teknik kanıt — seçilen yaklaşım:** Ürün akışını sekiz
   ekranda gösterir; mimari, gizlilik ve test kanıtlarıyla tamamlar. Jüri anlatımı
   için ürün ile mühendislik arasında en dengeli yapıdır.
2. **10 slayt hızlı ürün turu:** Daha kısa sunulur ancak mimari ve kalite kanıtlarına
   yeterli alan bırakmaz.
3. **15 slayt teknik derinlik:** Backend ve altyapıyı daha ayrıntılı gösterir fakat
   ürün hikâyesinin temposunu düşürür.

## Çıktılar

- `MakiKoc-Juri-Sunumu-12-Slayt.pptx`: düzenlenebilir 16:9 sunum.
- `slides/01-kapak.png` ile `slides/12-kapanis.png`: her slaydın 1920×1080 PNG'si.
- `screens/raw/`: telefondan alınan özgün portre ekran görüntüleri.
- `screens/selected/`: sunuma giren, yalnız sistem çubuğu güvenli biçimde kırpılmış
  ekran görüntüleri.
- `README-SUNUM.md`: slayt sırası, konuşmacı notları ve dosya envanteri.

Bu klasörler `work/presentation-output/maki-dikey-juri-sunumu/` altında tutulur ve
Git deposuna eklenmez.

## Görsel dil

### Marka

- Sol üstte MakiKoç'un gerçek yapraklı kelime markası kullanılır: yaprak simgesi,
  `MakiKoç` yazısı ve gerekirse küçük `Kişisel Finans Koçun` alt satırı.
- Yaprak işareti kod tabanlı vektör olarak üretilir; yeni veya farklı bir logo
  uydurulmaz.
- Maki için yalnız depodaki mevcut onaylı maskot varlıkları kullanılır. Yeni bir
  hayvan, farklı yüz veya üretken model yorumu kullanılmaz.

### Tipografi ve renk

- Başlık: `Maki Display Bold`.
- Gövde: `Maki Sans Regular/Medium/Bold`.
- Koyu orman: `#08261D`.
- Derin yeşil: `#164B39`.
- Kırık beyaz: `#F5F0E5`.
- Yaprak yeşili: `#83D8AA`.
- Ölçülü vurgu pembesi: `#EFA9BE`.
- Teknik kanıt vurgusu: `#D9B06B`.

### Düzen

- Tuval: 1920×1080, 16:9.
- Kenar boşluğu: 72 px; 12 kolonlu editoryal grid.
- Ürün slaytlarında tek bir birincil dikey telefon ekranı bulunur.
- Telefon yaklaşık 430–500 px genişlikte ve 820–900 px yükseklikte gösterilir.
- Ekranın karşısında bir ürün vaadi ve en fazla üç kısa madde yer alır.
- Maki, özellik slaytlarında alt köşede küçük anlatıcı olarak bulunur; ekranın veya
  metnin üzerine binmez.
- Mimari ve test slaytlarında telefon zorunlu değildir; Maki küçük bir rehber işareti
  olarak kalır.
- Slayt başına bir ana fikir korunur.

### Kaçınılacak öğeler

- Rastgele gradient küreleri, yoğun glow, glassmorphism kart yığınları ve anlamsız
  soyut AI arka planları.
- Bir slaytta çok sayıda küçük ekran kolajı.
- Uzun paragraflar ve dört maddeden fazla liste.
- Gerçek uygulama ekranını yeniden çizen, metnini değiştiren veya sahte veri ekleyen
  üretken görsel düzenleme.
- Cihaz modeli, seri numarası, kişisel bildirimler veya gerçek finans verisi.

## Telefon ekranı üretim kuralları

1. Bağlı fiziksel Android cihaz portre yönüne alınır; uygulama da portre yerleşiminde
   gerçek olarak çalıştırılır.
2. Yatay görüntüyü döndürerek dikeymiş gibi sunmak yasaktır.
3. Ekran yakalama ADB ile doğrudan cihazdan yapılır.
4. Yalnız Android sistem çubuğu ve güvenli çerçeve dışı alan kırpılabilir; uygulama
   bileşenleri kesilmez.
5. Debug şeridi görünen bir ekran nihai slaytta kullanılmaz. Gerekirse profil/release
   yapılandırmasıyla temiz portre yakalama yapılır.
6. Ekranda gerçek kişisel veri yerine boş durum veya sentetik örnek veri kullanılır.
7. Her ekran, slayta alınmadan önce çözünürlük, yön, okunabilirlik ve kişisel veri
   açısından kontrol edilir.

## On iki slaytlık anlatı

### 1. Kapak — MakiKoç

- Yapraklı MakiKoç logosu ana odaktır.
- Ürün vaadi: “Paranı takip et, hedefini büyüt, ormanını yaşat.”
- Dikey telefon içinde Maki'nin en güçlü ana ekranı gösterilir.
- Takım 120 ve ekip rolleri sade biçimde yer alır.

### 2. Problem ve çözüm

- Problem: finans uygulamaları rakam gösterir ancak davranış ve devamlılık hissi
  üretmez.
- Çözüm: Maki, finansal davranışı kişisel rota ve yaşayan orman ilerlemesine bağlar.
- Bir problem/çözüm karşılaştırması ve küçük Maki anlatımı kullanılır.

### 3. Dört finans rotası

- Farkındalık, hedef, borç ve öğrenme rotaları gösterilir.
- Onboarding ekranı gerçek dikey telefonda yer alır.
- Seçimin ana ekranı, görevleri ve önerileri gerçekten değiştirdiği anlatılır.

### 4. Ana finans ekranı ve takvim

- Gelir, gider, net durum, haftalık takvim ve seri görünümü gösterilir.
- Birincil mesaj: “Bugünü görürken hedefi kaybetmez.”
- Kişiselleştirilmiş rota kartı vurgulanır.

### 5. Gelir/gider ve fiş OCR

- Manuel kayıt ile fiş tarama aynı finans akışında anlatılır.
- OCR toplamı kullanıcı onayından sonra gider olur.
- Ağ gerektiren OCR ile cihazda kalan kayıt arasındaki sınır açıkça belirtilir.

### 6. Hedefler ve görsel yol haritası

- Hedef oluşturma, kalan yol, katkı aralığı ve kilometre taşları gösterilir.
- Gelir/gider eklerken `hedefi etkilesin` seçiminin kullanıcı kontrolünde olduğu
  anlatılır.
- Hedef ödüllerinin tekrar kazanılamadığı belirtilir.

### 7. Yaşayan Finans Ormanı

- Orman ekranı, seri, günlük görev ve mağaza ekonomisi gösterilir.
- 325 görevlik katalog, seçilen rotaya ve güne göre çeşitlenir.
- Tohumdan koruluğa uzanan ilerleme tek görsel yol olarak anlatılır.

### 8. Kişisel enflasyon ve harcama tahmini

- Yerel Laspeyres sepeti, kapsama oranı ve veri yeterliliği gösterilir.
- Harcama tahmini için en az 56 günlük geçmiş gerektiği dürüstçe belirtilir.
- Veri yoksa sahte sayı yerine “yetersiz veri” ekranı kullanılır.

### 9. Borç simülatörü

- Çığ, kartopu ve özel kullanıcı stratejileri karşılaştırılır.
- Borçsuz kalma tarihi ve toplam faiz farkı anlaşılır Türkçeyle sunulur.
- Özellik finansal tavsiye değil, karşılaştırmalı simülasyon olarak konumlanır.

### 10. Maki Koç, bildirimler ve raporlar

- Yerel rehberin API anahtarı olmadan çalıştığı gösterilir.
- İsteğe bağlı Gemini modu ve gizli veri temizleme sınırı anlatılır.
- LinTS bildirim zamanlaması ile cihaz içi günlük/haftalık/aylık PDF raporu aynı
  “devamlılık” başlığında birleştirilir.

### 11. Gizlilik ve mimari

- Flutter istemci, Drift/SQLite3MC, ortak finans çekirdeği ve FastAPI backend arasındaki
  sınırlar tek diyagramla gösterilir.
- Para alanlarının `Int64` kuruş biriminde tutulduğu belirtilir.
- Android production hedefi; web demo/preview; iOS kaynak-hazır sınırı açıkça yazılır.
- Ağ gerektiren OCR/online koç ile yerel finans verisi ayrıştırılır.

### 12. Doğrulama ve kapanış

- Doğrulanmış yerel sonuçlar: 178 Flutter testi, 224 backend testi, 56 finans
  çekirdeği testi ve Semgrep'te 0 bulgu.
- GitHub Actions sonucu yalnız ilgili commit gerçekten yeşilse “CI geçti” olarak
  gösterilir; aksi durumda yerel doğrulama olarak etiketlenir.
- Kapanış mesajı ve Maki'nin kısa cümlesi: “Küçük adımlar görünür olduğunda devam
  etmek kolaylaşır.”

## Sunum üretim yapısı

- Her slayt ortak bir tasarım sistemi kullanır; başlık, logo, sayfa numarası ve alt
  bilgi alanı şablondan gelir.
- Telefon ekranları ayrı dosya girdileridir ve orijinal piksel verisi korunur.
- Grafikler ve mimari diyagram kod tabanlı şekillerle çizilir; ekran görüntüsü veya
  üretken görsel olarak eklenmez.
- Konuşmacı notları her slaytta 30–50 saniyelik anlatı hedefler.
- Geçişler kapalı veya çok hafiftir; içerik hareketle değil hiyerarşiyle anlaşılır.

## Doğrulama

- Android ekranlarının tümü portre ve fiziksel cihaz kaynaklı olmalıdır.
- Her slayt tam 1920×1080 PNG olarak render edilmelidir.
- `.pptx` içindeki metinler düzenlenebilir olmalıdır.
- Font taşması, kesilen telefon, üst üste binen Maki ve okunamayan küçük metin
  bulunmamalıdır.
- Slayt montajı 3×4 veya 4×3 temas sayfasında ayrıca incelenmelidir.
- İlk, orta ve son slayt tek tek tam boy render edilerek kalite kontrolünden geçmelidir.
- Sunum klasöründe cihaz adı veya gerçek kişisel veri araması sıfır sonuç vermelidir.

## Başarı ölçütü

Sunumu ilk kez gören biri, 12 slayt sonunda Maki'nin üç farkını açıkça
söyleyebilmelidir: finans amacına göre değişen deneyim, gerçek davranışla büyüyen
Yaşayan Finans Ormanı ve cihazda kalan gizlilik odaklı finans çekirdeği.
