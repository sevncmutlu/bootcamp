# Sprint 3 Review

**Tarih:** 1 Ağustos 2026 · **Karar:** Kabul

## Gösterilen ürün akışları

1. Yaş profili ve dört amaçtan biriyle cihaz profili oluşturma
2. Rota seçimine göre değişen ana finans kartı, görevler ve öneriler
3. Gelir/gider kaydı, takvim ve isteğe bağlı hedef katkısı
4. Fiş tarama, bulunan toplamı onaylama ve gider taslağı
5. Yaşayan Finans Ormanı, seri, mağaza ve büyüme yolu
6. Hedef rotası, 30 duraklı harita ve kilometre taşı ödülleri
7. Borç stratejileri, kişisel enflasyon ve Maki Koç
8. Cihaz içi PDF üretme, Android'de farklı kaydetme ve paylaşma

## Kabul sonuçları

| Kontrol | Sonuç |
|---|---|
| Flutter statik analiz | Hatasız |
| Flutter testleri | 178 / 178 başarılı |
| Backend Ruff / mypy | Hatasız |
| Backend testleri | 224 başarılı, Docker'a bağlı 9 test atlandı |
| Finans çekirdeği | 56 / 56 başarılı; fatal analiz temiz |
| Android debug APK | Başarılı |
| Web preview release | Sentetik in-memory veriyle Chromium'da başarılı |
| Semgrep | 447 dosya, 8 özel kural, 0 bulgu |
| Dar ekran ve dönüş | Regresyon testleri başarılı |
| Finans verisinin PDF için ağdan çıkmaması | Doğrulandı |
| Android PDF sistem kayıt akışı | Birim testi ve APK derlemesi başarılı |

## Product Owner geri bildirimi

- Orman yalnız görsel değil, kullanıcı davranışına bağlı bir ilerleme sistemi olmalıydı;
  takvim, seri, görev, hedef ve mağaza aynı defterde birleştirildi.
- Amaç seçimi dört farklı ürün hissi vermeliydi; ortak navigasyon korunurken içerik
  profilleri ayrıştırıldı.
- Yabancı terimler son kullanıcı metinlerinden çıkarıldı veya Türkçe karşılığıyla
  açıklandı.
- Telefon kararlılığı görsel yoğunluktan daha yüksek öncelikte tutuldu.

**Review sonucu:** Sprint 3 ve GitHub teslim kapsamı kabul edildi.
