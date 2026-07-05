# 🏃 Sprint 1 — Planlama & Proje Belirleme

**Proje:** Maki Finans Koçu · **Takım:** Takım 120
**Tarih:** 19 Haziran – 5 Temmuz · **Durum:** ✅ Tamamlandı

> **Sprint Teması:** Projeyi netleştirmek, teknoloji ve kimlik kararlarını vermek, geliştirmeye hazır bir plan ve mimari çıkarmak. *(Bu sprintte kod yazılmadı — tamamen planlama sprinti.)*

---

## 🎯 Sprint Hedefi

Ürün fikrini, hedef kitleyi ve değer önermesini netleştirmek; teknoloji yığınını ve ürün kimliğini (MakiKoç karakteri + gizlilik mimarisi) belirlemek; 3 sprintlik yol haritasını ve riskleri tanımlayarak ekibi geliştirmeye hazır hâle getirmek.

---

## 🧮 Sprint İçinde Tamamlanması Beklenen Puan (Sprint Kapasitesi)

- **Toplam proje puanı:** 300 puan (3 sprint)
- **Sprint 1 hedef puanı:** ~100 puan

> Planlama ağırlıklı bu sprint, üç sprintin temelini oluşturduğu için toplam puanın 1/3'ü olarak değerlendirilmiştir.

---

## 📊 Backlog Dağıtma Mantığı (Puan Mantığı)

- Proje 3 sprinte bölünmüş; her sprint yaklaşık eşit puan (~100) taşıyacak şekilde dengelenmiştir.
- Sprint 1 **planlama ve karar** işlerini içerir; çıktısı kod değil, **geliştirmeye hazır plan + mimari + kararlar** olduğu için "her sprintte somut ilerleme" ilkesine uygun şekilde puanlanmıştır.
- Backlog item'ları büyükten küçüğe önceliklendirilmiş; her item bir DoD (Definition of Done) ile ilişkilendirilmiştir.
- Riskli/erken doğrulanması gereken işler (ör. Türkçe fiş OCR doğruluğu) öne çekilmiş, Sprint 2 başına yerleştirilmiştir.

---

## 📋 Sprint 1 Backlog (Yapılacaklar)

| # | Görev | Durum |
|---|-------|-------|
| 1 | Problem, hedef kitle ve değer önermesinin netleştirilmesi | ✅ |
| 2 | Kimlik & metafor kararı (MakiKoç karakteri + hafif orman katmanı) | ✅ |
| 3 | Teknoloji yığını seçimi (Flutter, Isar/Drift, FastAPI, PaddleOCR, Prophet, RAG, LLM) | ✅ |
| 4 | Gizlilik mimarisi kararı (neyin cihazda kaldığı, neyin anonim gittiği) | ✅ |
| 5 | Kategori taksonomisi taslağı | ✅ |
| 6 | 3 sprint takvimi + kapsam belirleme | ✅ |
| 7 | Risklerin belirlenmesi | ✅ |

---

## 🗓️ Daily Scrum Notları

> Takım küçük olduğu için Daily Scrum'lar kısa senkron görüşmeler + yazışma üzerinden yürütülmüştür.

- **Backlog Dağıtma:** Proje 3 sprinte bölündü, temalar ve puanlar belirlendi.
- **Kimlik & Metafor:** MakiKoç karakteri ana kimlik olarak seçildi; orman metaforu ikincil/destekleyici katman olarak konumlandırıldı.
- **Gizlilik Kararı:** Tüm kişisel verinin cihazda kalması, sunucuya yalnızca anonim sinyal gitmesi kararlaştırıldı.
- **Teknoloji Kararı:** Flutter + Isar/Drift + FastAPI + PaddleOCR + Prophet + RAG + Claude yığını netleştirildi.
- **Risk Değerlendirmesi:** Zaman kısıtı, gizlilik ispatı ve Türkçe OCR doğruluğu ana riskler olarak not edildi.

> _Daily Scrum ekran görüntüleri / toplantı notları buraya eklenecektir._

---

## 🗂️ Sprint Board Updates

- **To Do → In Progress → Done** akışı kuruldu.
- Sprint 1 sonunda tüm planlama kalemleri **Done** sütununa taşındı.
- Sprint 2 backlog'u (Temel & Altyapı, Fiş OCR, AI Koçluk başlangıcı) **To Do** olarak hazırlandı.

> _Sprint board ekran görüntüsü buraya eklenecektir._

---

## 📦 Ürün Durumu

Sprint 1 planlama sprinti olduğu için henüz çalışan bir uygulama ekranı yoktur. Sprint çıktısı:

- ✅ Netleştirilmiş ürün vizyonu ve değer önermesi
- ✅ Teknoloji yığını ve mimari kararları
- ✅ Ürün kimliği (MakiKoç) ve gizlilik mimarisi kararı
- ✅ 3 sprintlik yol haritası ve risk listesi

> _Ürün konsept görselleri / mimari şeması buraya eklenecektir._

---

## 🔍 Sprint Review

- Ürün fikri, hedef kitle ve değer önermesi net biçimde ortaya kondu.
- Teknoloji yığını ve mimari, geliştirmeye başlamak için yeterli detayda belirlendi.
- Gizlilik öncelikli mimari kararı (cihazda veri) projenin en kritik farklılaştırıcısı olarak onaylandı.
- Sprint 2'de geliştirme başlangıcı için tüm ön koşullar hazır.

**Sprint Review Kararı:** Sprint 1 hedeflerine %100 ulaşıldı; kapsam dışına çıkılmadı.

---

## 🔄 Sprint Retrospective

**👍 İyi Gidenler**
- Kapsam erken netleşti; teknoloji ve kimlik kararları hızlı alındı.
- Gizlilik mimarisi baştan tasarlandığı için sonraki sprintlerde sürprizi azaltacak.

**🔧 Geliştirilebilecekler**
- Türkçe fiş OCR doğruluğu bir an önce (Sprint 2 başında) test edilmeli.
- Modeller için "önce basit çalışan sürüm, sonra iyileştir" yaklaşımı disiplinli uygulanmalı.

**🎯 Aksiyonlar (Sprint 2 için)**
- PaddleOCR Türkçe fiş doğruluğunu Sprint 2 başında pilot testle doğrula.
- Flutter iskeleti + cihaz DB şemasını sprint başında kur ki geliştirmeye erken başlanabilsin.

---

## ✅ Sprint 1 Definition of Done (DoD)

Uygulamanın ne olduğu, hangi teknolojiyle ve hangi sırayla yapılacağı yazılı; kimlik ve gizlilik kararları verilmiş; ekip geliştirmeye başlamaya hazır. **→ Karşılandı ✅**

---

## ➡️ Sonraki Sprint

**Sprint 2 (6 – 19 Temmuz):** Temel & Altyapı + Fiş OCR + AI Koçluk başlangıcı.
Hedef: Çalışan iskelet, cihazda güvenli veri, fiş ile otomatik giriş ve ilk kaynaklı koçluk.
