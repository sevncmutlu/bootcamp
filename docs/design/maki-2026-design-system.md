# Maki 2026 ürün arayüzü

Tarih: 30 Temmuz 2026

## Ürün tezi

MakiKoç, Türkiye’de parasını daha bilinçli yönetmek isteyen mobil kullanıcılar
için mahremiyet odaklı kişisel finans koçudur. Arayüzün tek işi, kullanıcının
finansal durumunu yargılamadan anlaşılır kılmak ve bir sonraki doğru adımı
göstermektir.

Görsel yön “fintech dashboard” değil, küçük kararlarla büyüyen yaşayan bir
Anadolu koruluğudur. Ağaç halkaları ürünün imza öğesidir: küçük finansal
hareketlerin zaman içinde görünür büyümeye dönüşmesini temsil eder.

## Tasarım token’ları

| Rol | Ad | Değer |
|---|---|---:|
| Ana marka | Çam mürekkebi | `#0E4B36` |
| Derin yüzey | Gece çamı | `#071A14` |
| Destek | Maki yaprağı | `#73976B` |
| Yumuşak vurgu | Liken | `#DCE5CF` |
| Arka plan | Orman sisi | `#F3F6F1` |
| Eylem vurgusu | Ölçülü kehribar | `#D7A84A` |
| Gider | Toprak mercanı | `#C8623F` |

Kart yarıçapı 24 px, kahraman yüzeyleri ve navigasyon 32 px, kontrol yüzeyleri
18 px kullanır. Gölge; koyu, düşük opaklıklı ve geniş yayılımlıdır.

## Tipografi

- `MakiDisplay`: finansal rakamlar ve büyük başlıklar için Roboto Condensed.
- `MakiSans`: gövde, kontrol ve veri etiketleri için Roboto.
- Font dosyaları uygulamayla birlikte paketlenir; sistem fontuna veya ağa
  bağımlı değildir.
- Lisanslar `frontend/assets/fonts/` altında tutulur.

## Uygulanan sistem

- Açık/koyu tema için elle dengelenmiş Material 3 renk rolleri.
- Ağaç halkası atmosferli, responsive ve maksimum içerik genişliği olan ortak
  sayfa zemini.
- Ekran bağlamını iki satırda veren ortak Maki başlığı.
- Yüzen, yuvarlatılmış ve yalnız seçili etiketi gösteren beşli navigasyon
  iskelesi.
- Durumu koruyan, hareket azaltma tercihini dikkate alan 220 ms ekran geçişi.
- Ağaç halkası ve finansal yol motifli net bakiye ve istatistik kartları.
- Mobil yükseklik daraldığında kaydırılabilen boş durumlar.
- Yerel cihaz mahremiyetini görünür kılan finans özeti ve koç yüzeyleri.
- Orman görseliyle bütünleşen premium ekranı.
- Onboarding, nakit akışı, karşılaştırma, borç, analiz, orman, liderlik, koç,
  profil, ayarlar ve fiş tarama ekranlarında ortak tasarım dili.

## Görsel risk ve sınır

Tek cesur karar, veri yüzeylerini ağaç halkası/finansal yol metaforuna bağlamak
ve büyük finansal rakamları dar display tipografiyle sunmaktır. Diğer
dekorasyonlar azaltıldı; jenerik neon, cam efekti, coin ve banka sembolleri
kullanılmadı.

## Kalite kapıları

- `flutter analyze --no-pub`: 0 sorun.
- `flutter test --no-pub`: 99 test geçti.
- 390 × 844 ana ekran görsel regresyon sözleşmesi eklendi.
- 320 px dar navigasyon ve dar yükseklik boş durum testleri geçti.
- Hareket azaltma davranışı korunuyor.
- Frontend kaynak sınırı: 120 dosya, SHA-256
  `A03F3BF1F4460763F77F771D4E1D9959033CC236B59DF0A5092DED5F799A1448`.
