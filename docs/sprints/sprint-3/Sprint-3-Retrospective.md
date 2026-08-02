# Sprint 3 Retrospective

## İyi gidenler

- Kullanıcı geri bildirimleri ekran değil, ortak ürün kuralları olarak modellendi.
- Finans etkileri deterministik ve geri alınabilir tutuldu.
- Orman, hedef ve görev sistemi yerel veri üstünde birleşti.
- Mobil kararlılık sorunları widget/repository testleriyle kalıcı hâle getirildi.
- Gizlilik sınırı geniş özellik kapsamına rağmen korunabildi.
- Web'in production iddiası yerine sentetik preview olarak sınırlandırılması, gizlilik
  vaadini teknik davranışla aynı hizaya getirdi.
- Kuruş migration'ı, fiyat sepeti ve yerel tahmin ayrı kabul testleriyle ölçülebilir oldu.

## Zorlayan noktalar

- Sprint kapsamı ilk tahmini aştı; çok sayıda küçük görsel düzeltme ortak düzen
  problemlerinin geç fark edilmesine yol açtı.
- Web ve telefon arasında dosya kaydetme davranışı aynı API görünse de platformda
  farklıydı; Android'de açık sistem dosya seçicisi daha güvenilir çıktı.
- Canlı backend ve cihaz erişimi olmadığında “kod hazır” ile “üretimde bağlı” ayrımını
  belgelerde sürekli açık tutmak gerekti.
- Güvenlik araçlarının runtime sanal ortamına kurulması bağımlılık sürümlerini etkileyebilir;
  Semgrep ve Trivy CI'da ayrı araç ortamında tutulmalıdır.

## Öğrenimler

- Bir kullanıcı tercihi ancak veri, görev, öneri ve analiz davranışını değiştiriyorsa
  gerçek kişiselleştirmedir.
- Dosya işlemlerinde null/iptal sonucu başarı sayılmamalıdır.
- Oyun ekonomisi yalnız kazanma değil, kalıcı ve anlamlı harcama alanları ister.
- Uzun ömürlü cihaz içi ürünlerde şifreli yedek/aktarım sonraki sürüm için kritik
  önceliktir.

## Sonraki sürüm aksiyonları

1. Kullanıcı kontrollü şifreli dışa aktarma ve cihaz aktarımı
2. OCR mağaza/fiş türü kalite panosu ve gerçek veri seti kabul ölçümleri
3. Ekran okuyucu ve dinamik metin boyutu için geniş erişilebilirlik senaryoları
4. macOS üzerinde iOS imzalı arşiv ve fiziksel cihaz doğrulaması
5. Canlı OIDC, mağaza ürünleri ve yasal URL'lerle release candidate
