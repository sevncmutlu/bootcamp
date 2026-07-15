# Sprint 1 — Planlama & Proje Belirleme

**Proje:** Maki Finans Koçu · **Takım:** Takım 120
**Tarih:** 19 Haziran – 5 Temmuz · **Durum:** [Tamamlandı]

> **Sprint Teması:** Projeyi netleştirmek, teknoloji ve kimlik kararlarını vermek, geliştirmeye hazır bir plan ve mimari çıkarmak. *(Bu sprintte kod yazılmadı — tamamen planlama sprinti.)*

---

## Sprint Hedefi

Ürün fikrini, hedef kitleyi ve değer önermesini netleştirmek; teknoloji yığını ve ürün kimliğini (MakiKoç karakteri + gizlilik mimarisi) belirlemek; 3 sprintlik yol haritasını ve riskleri tanımlayarak ekibi geliştirmeye hazır hâle getirmek.

---

## Sprint Planning (Planlama)

**Sprint Süresi:** 19 Haziran – 5 Temmuz (2 hafta)

### Katılımcılar
*   **Product Owner:** Emir Hüseyin İnci
*   **Scrum Master:** Sevinç Mutlu
*   **Developer:** Emir Hüseyin İnci, Sevinç Mutlu

### Kapasite & Taahhüt
*   **Sprint kapasitesi (hedef):** ~100 SP
*   **Taahhüt edilen story point:** 60 SP (US-01 → US-07)
*   **Sprint uzunluğu:** 2 hafta

> Not: Sprint 1 planlama ağırlıklı olduğu için taahhüt edilen kalemler karar/dokümantasyon odaklıdır; kalan kapasite Sprint 2 hazırlığına ayrılmıştır.

---

## Sprint Backlog & Board

### Sprint Puan Özeti
*   **Sprint kapasitesi:** ~100 SP
*   **Taahhüt:** 60 SP
*   **Tamamlanan:** 60 SP (%100)

### Backlog Dağıtma Mantığı
*   Proje 3 sprinte bölündü; her sprint ~100 SP taşıyacak şekilde dengelendi.
*   Sprint 1 planlama & karar işlerini içerir; çıktısı kod değil, geliştirmeye hazır plan + mimari + kararlardır.
*   Riskli işler (Türkçe fiş OCR, RAG kaynaklandırma) erken sprintlere çekildi.
*   Her kalem bir DoD ile ilişkilendirildi.

### Sprint Board

| To Do | In Progress | Done |
|-------|-------------|------|
| — | — | US-01, US-02, US-03, US-04, US-05, US-06, US-07 |

> _Board ekran görüntüsü buraya eklenecektir._

### Görev Detayı & Durum

| ID | Görev | SP | Durum |
|----|-------|----|-------|
| US-01 | Problem, hedef kitle ve değer önermesinin netleştirilmesi | 8 | Done |
| US-02 | Kimlik & metafor kararı (MakiKoç + hafif orman katmanı) | 8 | Done |
| US-03 | Teknoloji yığını seçimi (Flutter, Drift + sqlite3mc, FastAPI, Gemini Multimodal, Prophet, RAG) | 13 | Done |
| US-04 | Gizlilik mimarisi kararı (cihazda veri / anonim sinyal) | 13 | Done |
| US-05 | Kategori taksonomisi taslağı | 5 | Done |
| US-06 | 3 sprint takvimi + kapsam belirleme | 8 | Done |
| US-07 | Risklerin belirlenmesi | 5 | Done |

**Toplam:** 60 / 60 SP tamamlandı.

### Sprint Burndown (Özet)

| Gün Aralığı | Kalan SP |
|-------------|----------|
| Başlangıç | 60 |
| 1. Hafta sonu | ~30 |
| 2. Hafta sonu | 0 |

> _Detaylı burndown grafiği buraya eklenecektir._

---

## Daily Scrum Notları

> Takım küçük olduğu için Daily Scrum'lar kısa senkron görüşmeler + Slack üzerinden yazışma ile yürütülmüştür.

### Hafta 1

**Gün 1–2 — Vizyon & Problem**
*   **Yapıldı:** Problem tanımı, hedef kitle ve değer önermesi tartışıldı (US-01).
*   **Yapılacak:** Ürün kimliği ve metafor kararına geçiş.
*   **Engel:** Yok.

**Gün 3–4 — Kimlik & Metafor**
*   **Yapıldı:** MakiKoç ana kimlik olarak seçildi; orman metaforu ikincil/destekleyici katman olarak konumlandırıldı (US-02).
*   **Yapılacak:** Teknoloji yığını araştırması.
*   **Engel:** Orman metaforunun koçluk mesajını gölgelememesi için denge tartışması → karara bağlandı.

**Gün 5 — Teknoloji Araştırması (başlangıç)**
*   **Yapıldı:** Teknoloji araştırması başladı. Bu proje için araştırma süreci oldukça yoğun geçti — mobil framework (Flutter vs. native), cihaz DB (Isar vs. Drift) ve backend (FastAPI) alternatifleri tek tek karşılaştırıldı (US-03).
*   **Yapılacak:** OCR, zaman serisi ve LLM tarafını netleştir.
*   **Engel:** Seçenek çok; her katman için doğru aracı seçmek zaman aldı.

### Hafta 2

**Gün 6–7 — Teknoloji Kararı (tamam)**
*   **Yapıldı:** Teknoloji yığını özenle tasarlandı. Her katman gerekçesiyle birlikte seçildi: OCR ve çift dilli koçluk için Gemini, tahmin için Prophet, RAG için FAISS/Chroma. Yığın netleşti → Flutter + Drift (sqlite3mc) + FastAPI + Gemini Multimodal + Prophet + RAG (US-03) [Tamamlandı].
*   **Yapılacak:** Gizlilik mimarisi kararı.
*   **Engel:** Yok — araştırmanın yoğunluğu sayesinde karar sağlam zemine oturdu.

**Gün 8–9 — Gizlilik Mimarisi**
*   **Yapıldı:** Gizlilik uzun uzun konuşuldu ve projenin en kritik farkı olarak kabul edildi. "Cihazda veri / sunucuya yalnızca anonim sinyal" mimarisi kararlaştırıldı (US-04) [Tamamlandı]. Hangi verinin cihazda kaldığı, neyin anonim gittiği tek tek netleştirildi.
*   **Yapılacak:** Kategori taksonomisi taslağı.
*   **Engel:** Anonim sinyalin gerçekten kimliksiz kalmasını teknik olarak garanti etmek üzerine detaylı tartışıldı; tasarım notu eklendi.

**Gün 10 — Taksonomi & Takvim & Riskler**
*   **Yapıldı:** Kategori taksonomisi taslağı (US-05) [Tamamlandı], 3 sprint takvimi (US-06) [Tamamlandı], risk listesi (US-07) [Tamamlandı].
*   **Yapılacak:** Sprint Review & Retrospective hazırlığı.
*   **Engel:** Yok — sprint hedefine ulaşıldı.

---

## Ürün Durumu

Sprint 1 planlama sprinti olduğu için henüz çalışan bir uygulama ekranı yoktur. Sprint çıktısı:

*   [Tamamlandı] Netleştirilmiş ürün vizyonu ve değer önermesi
*   [Tamamlandı] Teknoloji yığını ve mimari kararları
*   [Tamamlandı] Ürün kimliği (MakiKoç) ve gizlilik mimarisi kararı
*   [Tamamlandı] 3 sprintlik yol haritası ve risk listesi

---

## Sprint Review

*   Ürün fikri, hedef kitle ve değer önermesi net biçimde ortaya kondu.
*   Teknoloji yığını ve mimari, geliştirmeye başlamak için yeterli detayda belirlendi.
*   Gizlilik öncelikli mimari kararı (cihazda veri) projenin en kritik farklılaştırıcısı olarak onaylandı.
*   Sprint 2'de geliştirme başlangıcı için tüm ön koşullar hazır.

**Sprint Review Kararı:** Sprint 1 kabul edildi.

---

## Sprint Retrospective

### İyi Gidenler (Keep)
*   Kapsam erken netleşti; teknoloji ve kimlik kararları hızlı alındı.
*   Gizlilik mimarisi baştan tasarlandığı için sonraki sprintlerde sürprizi azaltacak.
*   Küçük takım olmasına rağmen iletişim akıcıydı; kararlar hızlı onaylandı.
*   3 sprintlik yol haritası gerçekçi ve dengeli çıktı.

### Geliştirilebilecekler (Improve)
*   Türkçe fiş OCR doğruluğu bir an önce (Sprint 2 başında) test edilmeli — bilinmezlik yüksek.
*   Modeller için "önce basit çalışan sürüm, sonra iyileştir" yaklaşımı disiplinli uygulanmalı.
*   Daily Scrum'lar daha yapılandırılmış (sabit saat) hâle getirilebilir.

### Bırakılacaklar (Stop)
*   Kapsamı genişletme eğilimi (banka entegrasyonu vb.) — MVP dışı tutulmalı.
*   Karar almadan uzun tartışmaya girmek — timebox uygulanmalı.

### Aksiyonlar (Sprint 2 için)

| # | Aksiyon | Sorumlu |
|---|---------|---------|
| 1 | Gemini Multimodal API entegrasyonu ile Türkçe fiş doğruluğunu Sprint 2 başında hızlıca test edip doğruluğu erken gör | Sevinç Mutlu |
| 2 | Flutter iskeleti + Drift şifreli cihaz DB şemasını sprint başında kur | Emir Hüseyin İnci |
| 3 | Daily Scrum için sabit saat belirle | Sevinç Mutlu (Scrum Master) |
| 4 | Her model için "basit sürüm" DoD'si tanımla | Emir Hüseyin İnci (PO) |

### Takım Morali
Sprint boyunca takım içinde zaman zaman iletişim aksaklıkları yaşandı; görev dağılımı ve karar süreçlerinde bazı kopukluklar oldu. Buna rağmen takım genel olarak iyi ilerliyor: sprint hedefine ulaşıldı ve net bir yol haritası çıktı. İletişim sorunlarının önümüzdeki sprintte daha yapılandırılmış Daily Scrum'lar (sabit saat, Slack üzerinden düzenli güncelleme) ile giderilmesi planlanıyor.

---

## Sprint 1 Definition of Done (DoD)

Uygulamanın ne olduğu, hangi teknolojiyle ve hangi sırayla yapılacağı yazılı; kimlik ve gizlilik kararları verilmiş; ekip geliştirmeye başlamaya hazır. **→ Karşılandı**

---

## Sonraki Sprint

**Sprint 2 (6 – 19 Temmuz):** Temel & Altyapı + Fiş OCR + AI Koçluk başlangıcı.
Hedef: Çalışan iskelet, cihazda güvenli veri, fiş ile otomatik giriş ve ilk kaynaklı koçluk.
