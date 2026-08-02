# Deterministik Yerel Rehber Konuşma Motoru Tasarımı

## Amaç

API anahtarı olmadan çalışan yerel rehber, beş sabit anahtar-kelime paragrafından
çıkarılıp doğal, takip edilebilir ve güvenli bir konuşma motoruna dönüştürülecek.
Motor bir üretken model taklidi yapmayacak; cevaplarının deterministik, açıklanabilir,
hızlı ve test edilebilir olduğu kullanıcıya "Yerel rehber" etiketiyle dürüstçe
gösterilecek.

## Konuşma Mimarisi

Motor dört küçük birimden oluşur:

1. **Normalleştirici:** Türkçe karakter, noktalama ve yaygın yazım çeşitlerini
   kayıpsız eşleşme biçimine getirir; PII scrubber her zaman önce çalışır.
2. **Intent puanlayıcı:** Tam kelime/ifade ağırlıklarıyla sosyal ve finansal
   niyetleri puanlar. En yüksek puan güven eşiğini geçmezse güvenli genel yardım
   yanıtına döner.
3. **Sınırlı oturum belleği:** `session_id` başına yalnız son intent, bekleyen takip
   sorusu ve son erişim zamanını tutar. Bellek kalıcı değildir; süre aşımı ve azami
   oturum sayısıyla otomatik temizlenir.
4. **Yanıt oluşturucu:** Karşılama, doğrudan yanıt, en fazla üç uygulanabilir adım
   ve gerektiğinde tek takip sorusunu birleştirir. Aynı giriş ve bağlam aynı sonucu
   üretir.

## Desteklenen Niyetler

- Selamlaşma, hal hatır, teşekkür, vedalaşma ve "ne yapabiliyorsun?"
- Bütçe/harcama kontrolü, gelir-gider dengesi ve kategori düzeni
- Borç, kredi kartı, faiz, çığ/kartopu karşılaştırması ve ödeme planı hazırlığı
- Birikim, acil durum fonu, hedef katkısı ve sürdürülebilir katkı
- Enflasyon/TÜİK karşılaştırması ve veri yeterliliği
- Fiş tarama, gider kaydı, PDF raporu, takvim, seri ve Yaşayan Finans Ormanı
- Anlaşılmayan veya uygulama dışı konularda nazik sınır ve desteklenen konu önerisi

## Takip Konuşmaları

- "Evet", "hayır", "nasıl?", "ne kadar?", "hangisi?" gibi kısa mesajlar son
  intent ve bekleyen soruyla birlikte yorumlanır.
- Borç planında rehber önce borçların faiz/asgari bilgilerini uygulamadaki simülatöre
  eklemeyi, ardından çığ/kartopu sonucunu karşılaştırmayı önerir; veri verilmeden
  sahte süre veya kesin sonuç üretmez.
- Birikim konuşmasında hedef tutarı, süre ve sürdürülebilir katkı eksikse tek bir
  netleştirme sorusu sorar.
- Selamlaşma ve teşekkür mesajlarına finans paragrafı yapıştırılmaz; kısa ve doğal
  yanıt verilir.

## Güvenlik ve Gizlilik

- Soru, intent sınıflandırmasından önce `TextScrubber` ile temizlenir.
- Bellekte ham soru, kart numarası, e-posta, IBAN veya tutar listesi tutulmaz.
- Yanıt yatırım getirisi, borç kapanış tarihi veya finansal sonucu garanti etmez.
- Kriz, dolandırıcılık, yasa dışı talep ve yüksek riskli yatırım dili ayrı güvenlik
  sınırına düşer; uygun resmî/uzman yardımına yönlendirir.
- Disclaimer her sosyal cevaba tekrarlanmaz; finansal eylem önerilerinde kısa,
  okunabilir biçimde eklenir.
- Oturum belleği eşzamanlı isteklerde kilitli, kapasitesi sınırlı ve süre aşımıyla
  temizlenen bir yapı olur; süreç yeniden başlayınca sıfırlanır.

## Ürün Dili

- Cevaplar yargılamayan, sade Türkçe ve kısa paragraflarla yazılır.
- Kullanıcının mesajı aynen tekrar edilmez.
- Teknik terim gerekiyorsa ilk kullanımda açıklanır.
- Uygulamada var olmayan bir ekran veya özellik önerilmez.
- "Yerel rehber" etiketi korunur; API anahtarı veya internet zorunluluğu yoktur.

## Doğrulama ve Kabul Eşikleri

- Selam, teşekkür, veda ve yardım niyetlerinin tablo testlerinde doğruluğu yüzde
  100 olur.
- Finansal intent test veri kümesinde en az yüzde 90 doğru birincil intent seçilir.
- Aynı giriş/bağlam byte düzeyinde aynı cevabı üretir.
- PII temizleme testlerinde ham kart, e-posta, telefon ve IBAN yanıta/belleğe
  sızmaz.
- Oturum süresi ve kapasite sınırı test edilir; en eski/süresi dolan kayıt temizlenir.
- Takip sorusu farklı bir `session_id` konuşmasına sızmaz.
- Bilinmeyen mesaj güvenli destek menüsüne döner; boş mesaj işlenmez.
- Mevcut Gemini ve kaynaklı resmî veri yolları bozulmaz; provider hatasında bu
  motor güvenli fallback olarak çalışır.

