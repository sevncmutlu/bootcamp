# Maki Sunum Ekran Görselleri Tasarımı

**Tarih:** 2 Ağustos 2026

**Durum:** Örnek düzen kullanıcı tarafından onaylandı

## Amaç

Maki'nin gerçek Android uygulamasındaki özellikleri, jüri ve ürün sunumunda tek
bakışta anlaşılabilecek 16:9 görsellerle anlatmak. Her görsel gerçek cihaz ekranını
değiştirmeden koruyacak ve Maki'yi kısa bir rehber olarak kullanacak.

## Değerlendirilen yaklaşımlar

1. **Ekran + anlatıcı Maki — seçilen yaklaşım:** Solda gerçek telefon ekranı,
   sağda özellik başlığı ve en çok üç kısa fayda, sağ altta Maki. Okunabilirliği ve
   ekran doğruluğunu birlikte korur.
2. **Tam ekran telefon + işaret noktaları:** Telefon ekranı ortada büyür, özellikler
   çizgilerle işaretlenir. Ayrıntılı ekranlarda güçlüdür ancak metin ve çizgi
   kalabalığı üretir.
3. **Özellik kolajı:** Bir slaytta iki veya üç ekran gösterilir. Toplam slayt sayısını
   azaltır fakat küçük ekran yazıları sunum mesafesinden okunmaz.

İlk örnek ve devamındaki seri için birinci yaklaşım kullanılır.

## Görsel sistem

- Çıktı: 1920×1080 PNG, 16:9 yatay.
- Zemin: Maki'nin koyu orman paleti; düşük kontrastlı organik halka ve yaprak
  dokuları yalnız boş alanlarda kullanılır.
- Telefon ekranı: Android cihazdan alınmış özgün piksel çıktısı; metin, renk,
  değer veya uygulama bileşeni yeniden üretilmez.
- Anlatım alanı: Özellik adı, tek cümlelik ürün vaadi ve en çok üç kısa madde.
- Maki: Mevcut proje varlıklarından uygun duygu pozu; üretken modelle farklı bir
  karaktere dönüştürülmez.
- Alt etiket: `Maki Finans Koçu · Takım 120`.
- Gizlilik: Cihaz adı, seri numarası, bildirim içeriği ve kişisel finans verisi
  görsellerde yer almaz. Gerekirse yalnız sentetik örnek veri kullanılır.

## İlk örnek

**Başlık:** Ana Finans Ekranı

**Ürün vaadi:** Gelir, gider ve hedef ilerlemesini tek bakışta anlaşılır hale getirir.

**Maki'nin anlatımı:**

- Haftanın gelir ve gider akışını takvimde gösterir.
- Seçilen finans rotasına göre ana kartı kişiselleştirir.
- Günlük küçük adımları hedef ve orman ilerlemesine bağlar.

**Maki balonu:** “Bugünün parasını gösterirken yarının hedefini de unutmuyorum.”

## Üretim akışı

1. Android uygulaması güncel debug paketinden açılır.
2. Ekran kişisel veri göstermeyen kararlı bir durumda yakalanır.
3. Görüntü kırpılmaz veya üretken modelle yeniden çizilmez; yalnız sunum
   tuvaline yerleştirilir.
4. Mevcut Maki varlığı, başlık ve açıklamalar aynı şablona eklenir.
5. PNG çıktısı 1920×1080 çözünürlükte doğrulanır.
6. Kullanıcı ilk örneği onayladıktan sonra özellik envanteri aynı şablonla üretilir.

## Kabul ölçütleri

- Telefon ekranındaki tüm metinler özgün ekran görüntüsüyle piksel olarak aynıdır.
- Çıktı tam 1920×1080 pikseldir ve slaytta kırpılmadan görünür.
- En fazla üç özellik maddesi vardır; her madde tek satıra yakın tutulur.
- Maki ekranın kritik bölümünü kapatmaz.
- Cihaz modeli veya kişisel veri görünmez.
- İlk örnek kullanıcı tarafından görsel olarak onaylanmadan seri üretime geçilmez.
