# Değişiklik Kaydı

Bu proje [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/) yaklaşımını izler.

## [1.0.0] — 2026-08-01

### Eklendi

- Farkındalık, hedef, borç ve öğrenme için dört işlevsel finans rotası
- Tam ekran Yaşayan Finans Ormanı, 325 görev, seri, XP ve tohum ekonomisi
- Orman mağazası, seri koruma yaprakları ve yerel bitki parselleri
- 30 duraklı hedef haritası, kilometre taşları ve tekrar ödül koruması
- Hedefe açık seçimle bağlanabilen gelir ve gider işlemleri
- Günlük, haftalık ve aylık cihaz içi PDF rapor merkezi
- Yaş profili, akıllı bildirim zamanlaması ve sürüklenebilir Maki Koç
- Kişisel enflasyon kartı, borç stratejileri ve kullanıcı stratejisi
- Android, iOS ve web kaynaklarıyla responsive ürün kabuğu
- Kullanıcının onayladığı fiyat geçmişinden cihaz içinde Laspeyres kişisel enflasyon hesabı
- 56 günlük yerel medyan/MAD harcama tahmini ve backend hata durumunda yerel geri dönüş
- İşletim sistemi izni ve gerçek planlamayla çalışan LinTS bildirim geri bildirim döngüsü

### Değiştirildi

- Onboarding amaçları uygulama genelindeki rota profillerine dönüştürüldü.
- Orman, finans takvimi ve günlük görevlerle ortak ilerleme defterine bağlandı.
- Son kullanıcı metinlerinde teknik terimler sade Türkçe ile değiştirildi.
- Tema renkleri bütün ana finans, takvim ve orman yüzeylerine yayıldı.
- Gezinme, ekranları ihtiyaç olduğunda oluşturan kararlı yapıya taşındı.
- SQLite para alanları `Int64` kuruş birimine taşındı; kayıpsız migration doğrulamaları eklendi.
- Web kalıcı finans depolamasından ayrılıp yalnız sentetik in-memory preview olarak kilitlendi.
- Orman, gider, ana finans, borç ve enflasyon mega-widget'ları sorumluluklarına ayrıldı.

### Düzeltildi

- Hızlı navigasyonda uygulamanın seçilen ekranda takılı kalması
- Hedef ekleme sonrası mobil rota açılışındaki çökme
- Orman ekranından geri dönememe ve rota kartının aşağıda kalması
- Maki Koç balonunun içerik üstünü kapatması ve dönüşte ekran dışına çıkması
- Gider formunda klavye/odak davranışı ve çeşitli dar ekran taşmaları
- Hedef büyüme yolu çizgisi ve hedef kartının ikinci sayfası
- Android PDF indirmede sistem kayıt ekranının açılmaması
- PDF kayıt iptalinin yanlışlıkla başarı olarak gösterilmesi
- Eski `sqlite3.wasm` ile güncel bağlayıcı arasındaki web açılış uyumsuzluğu
- Yerel bildirim eklentisi için eksik Android core-library desugaring yapılandırması

### Güvenlik ve gizlilik

- Finans verileri ve PDF üretimi cihaz içinde tutuldu.
- Geliştirme oturumu ile üretim OIDC sınırı ayrıldı.
- Asimetrik, kısa ömürlü JWT doğrulaması ve kişisel veri temizleme korundu.
- Teslim paketinden sırlar, yerel DB'ler, loglar ve üretilmiş binary'ler çıkarıldı.

### Doğrulama

- Flutter statik analiz: temiz
- Flutter testleri: 178 / 178 başarılı
- Backend: Ruff/mypy temiz; 224 test başarılı, Docker'a bağlı 9 test atlandı
- Finans çekirdeği: fatal analiz temiz; 56 / 56 test başarılı
- Flutter web preview release derlemesi ve Chromium açılışı: başarılı
- Android debug APK derlemesi: başarılı
- Semgrep: 447 kaynak dosya, 8 özel kural, 0 bulgu
