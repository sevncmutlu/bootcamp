# Sprint 3 Günlük İlerleme Notları

## 20–22 Temmuz — Ürün kabuğu ve amaçlar

- Telefon, yatay ekran ve web için uyarlanabilir navigasyon kuruldu.
- Onboarding amaçları rota profillerine dönüştürüldü.
- Ana finans kartı, haftalık akış ve öneriler seçilen rotaya bağlandı.

## 23–25 Temmuz — Yaşayan Finans Ormanı

- Takvim, seri, XP, tohum cüzdanı ve ödül defteri bağlandı.
- Görev kataloğu 325 benzersiz kaleme çıkarıldı; günlük seçim deterministik yapıldı.
- Yerel bitki parselleri, mağaza, büyüme aşamaları ve tam ekran orman eklendi.
- Orman çıkışı ve Maki balonunun ekran üstünü kapatması düzeltildi.

## 26–28 Temmuz — Hedef, OCR ve finans araçları

- Hedef oluşturma ve 30 duraklı rota haritası tamamlandı.
- Gelir/gider formlarına “hedefi etkilesin” seçeneği eklendi.
- Fiş toplamı ayıklama ve gider taslağı onay akışı iyileştirildi.
- Borç stratejileri genişletildi ve kullanıcı stratejisi oluşturma eklendi.

## 29–30 Temmuz — Raporlar ve kişiselleştirme

- Günlük/haftalık/aylık cihaz içi PDF raporu eklendi.
- Kişisel enflasyon Maki kartı, indirme ve paylaşım akışları tamamlandı.
- Profil yaş alanı, sade bildirim ekranı ve Maki Koç sağlayıcı sınırı bağlandı.
- Tema renkleri ana kartlar, takvim ve orman yüzeylerine yayıldı.

## 31 Temmuz — Kararlılık

- Tembel gezinme ve hızlı ekran değişimlerinde son hedefi koruyan geçiş eklendi.
- Hedef ekleme sonrası rota açılışındaki mobil çökme düzeltildi.
- Sürüklenebilir Maki balonu kenara yaslanma ve konum hatırlama ile tamamlandı.
- Açılış ekranında takılı kalma için güvenli zaman aşımı davranışı doğrulandı.

## 1 Ağustos — Teslim

- Hedef kartının ikinci sayfası ve büyüme yolu çizgisi son kez düzenlendi.
- Android PDF indirme, izin gerektirmeyen sistem “Farklı kaydet” akışına taşındı.
- Android PDF iptali artık yanlış başarı mesajı üretmiyor.
- Para alanları Int64 kuruşa taşındı; kayıpsız V5→V6 migration ve hassasiyet kapıları eklendi.
- Bildirim izni/planlama/açılma/anlamlı davranış döngüsü LinTS politikasına bağlandı.
- Kişisel enflasyon gerçek yerel fiyat sepeti ve Laspeyres hesabına; harcama tahmini
  56 günlük yerel medyan/MAD geri dönüşüne bağlandı.
- Web yalnız sentetik, in-memory preview olarak kilitlendi; eski uyumsuz SQLite WASM
  varlığı güncel sürümle değiştirildi ve Chromium açılışı doğrulandı.
- Orman, gider, ana finans, borç ve enflasyon mega-widget'ları parçalara ayrıldı;
  yapısal boyut kapısı release doğrulamasına eklendi.
- 178 Flutter, 224 backend ve 56 finans çekirdeği testi tamamlandı; 447 dosyalık
  Semgrep taramasında 0 bulgu bulundu.
- README, Product Backlog, Sprint 3, changelog ve teslim belgeleri güncellendi.
- Kaynak dışı çıktılar ve yerel sırlar teslim ZIP'inden çıkarıldı.

## Açık dış bağımlılıklar

- iOS imza ve fiziksel cihaz kontrolü macOS/Apple hesabı gerektirir.
- Mağaza yayını release imzası, OIDC, yasal URL ve mağaza ürün kimliklerini gerektirir.
- Bu değerler kaynak koda veya teslim ZIP'ine eklenmemiştir.
