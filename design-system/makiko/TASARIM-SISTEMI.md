# MakiKoç Mobil Tasarım Sistemi

Bu belge Android ve iOS uygulamasının görsel ve etkileşim kurallarını tanımlar.
Kod tarafındaki tek doğruluk kaynağı `frontend/lib/theme/app_tokens.dart` ve
`frontend/lib/theme/app_theme.dart` dosyalarıdır.

## Tasarım İlkeleri

- Teknik olarak güçlü, görsel olarak sakin bir ürün oluştur.
- Finansal bilgiyi süsten önce göster.
- Her ekranda tek birincil görev ve belirgin bir sonraki adım sun.
- MakiKoç'u destekleyici bir rehber olarak kullan; finansal içeriğin önüne geçirme.
- Kişisel veri ve risk durumlarında açık, yargılamayan Türkçe kullan.
- Boş, yükleniyor, hata, çevrimdışı ve yetkisiz durumları tasarımın parçası say.

## Renkler

| Rol | Değer | Kullanım |
|-----|-------|----------|
| Marka yeşili | `#2E7D4D` | Birincil eylem ve seçili durum |
| Koyu orman | `#1F5A3A` | Başlık, vurgu ve koyu geçiş |
| Açık yeşil | `#5BB55F` | Koyu temada marka vurgusu |
| Kehribar | `#F2C15A` | Uyarı ve ikincil vurgu |
| Krem | `#F7F2E7` | Açık tema zemini |
| Gece | `#0E1512` | Koyu tema zemini |
| Gider | `#E2703A` | Gider ve hata vurgusu |
| Bilgi | `#3D8BC4` | Bilgilendirme durumu |

- Renk tek başına anlam taşımaz; ikon veya metinle desteklenir.
- Normal metinde en az `4.5:1`, büyük metinde en az `3:1` karşıtlık sağlanır.
- Gelir ve gider renkleri grafik dışında da açıklayıcı etiket taşır.

## Tipografi

- Material 3 sistem tipografisi kullanılır.
- Ağ üzerinden yazı tipi indirilmez. Özel yazı tipi gerekirse uygulama paketine eklenir.
- Başlıklar kısa, cümle düzeninde ve Türkçedir.
- Finansal tutarlar para birimiyle, yerel ayraçlarla ve eşit ondalık basamakla gösterilir.
- Metin ölçeği `%200` olduğunda bilgi veya eylem kaybı oluşmaz.

## Boşluk ve Köşeler

| Token | Değer |
|-------|-------|
| `xs` | `4` |
| `sm` | `8` |
| `md` | `12` |
| `lg` | `16` |
| `xl` | `24` |
| `xxl` | `32` |
| `xxxl` | `48` |

- Ekran dış boşluğu varsayılan olarak `16` birimdir.
- Kart köşesi `20`, alt panel üst köşesi `28` birimdir.
- Dokunma hedefi en az `48 × 48` birimdir.
- Sabit piksel yüksekliği yalnızca ikon ve kontrollü marka öğelerinde kullanılır.

## Bileşen Kuralları

### Düğmeler

- Ekranda en fazla bir dolu birincil düğme bulunur.
- Eylem metni fiille başlar: “Harcamayı kaydet”, “Planı oluştur”.
- İşlem sürerken tekrar dokunma engellenir ve ilerleme gösterilir.
- Yıkıcı eylem renk, ikon ve açık metinle ayrıştırılır.

### Kartlar

- Kart tek konu taşır; kart içinde başka kart kullanılmaz.
- Başlık, temel değer ve isteğe bağlı açıklama sırası korunur.
- Tıklanabilir kartın tamamı tek erişilebilir hedef olur.

### Formlar

- Etiket alanın dışında kalır; yalnızca ipucu metni etiket yerine kullanılmaz.
- Para, oran ve tarih alanları giriş sırasında doğrulanır.
- Hata mesajı sorunu ve düzeltme yolunu Türkçe açıklar.
- Klavye açıldığında birincil eylem görünür veya kaydırılabilir kalır.

### Durumlar

- Yükleniyor durumunda ekran iskeleti veya kısa ilerleme metni gösterilir.
- Boş durumda neden ve yapılabilecek ilk eylem birlikte sunulur.
- Hata durumunda teknik ayrıntı yerine güvenli kullanıcı mesajı gösterilir.
- Tekrar denenebilir hatada “Yeniden dene” eylemi bulunur.

## MakiKoç ve Orman

- Maskot karar vermez; sonucu açıklar ve kullanıcıyı destekler.
- Kritik uyarıda neşeli kutlama görseli kullanılmaz.
- Orman ilerlemesi gerçek tasarruf veya alışkanlık verisine bağlıdır.
- Maskot görselleri anlamlı alternatif metin taşır veya dekoratifse erişilebilirlik
  ağacından çıkarılır.
- Animasyonlar kısa ve sakin tutulur; azaltılmış hareket tercihinde devre dışı kalır.

## Uyarlanabilir Düzen

- Ana hedef genişlikler: `320`, `360`, `375`, `412` ve `600` birimdir.
- Dar ekranda yatay kaydırma oluşmaz.
- Alt gezinme, klavye ve sistem çubukları içeriği kapatmaz.
- Yatay ekran zorunlu değildir; açıldığında kritik eylem kaybolmaz.

## Dil

- Kullanıcı metinleri `app_tr.arb` üzerinden üretilir.
- Kullanıcı mesajları, doğrulamalar, hata metinleri ve insan tarafından yazılan
  yorumlar Türkçedir.
- Kod tanımlayıcıları ve dış API alanları teknik sözleşmeler nedeniyle İngilizce olabilir.
- Araç tarafından üretilen kaynaklar elle düzenlenmez ve Git'te tutulmaz.

## Teslim Kontrolü

- Flutter analizi uyarısız tamamlanır.
- Widget testleri `320` birim genişlik ve büyük metin ölçeğini kapsar.
- Kritik akışlarda taşma, kesilen metin veya erişilemeyen eylem bulunmaz.
- Açık ve koyu tema doğrulanır.
- Ekran okuyucu etiketleri anlamlı sırada okunur.
- Görsel regresyon değişiklikleri bilinçli olarak onaylanır.
- Kullanılmayan veya geçici görsel uygulama paketine girmez.
