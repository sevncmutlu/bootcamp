# Aktif Hedef Seçimi ve Doğrudan Harita Tasarımı

## Amaç

Gelir/Gider ana kartındaki hedef rotası yalnızca ilk hedefi gösteren pasif bir kart
olmayacak. Kullanıcı iki veya daha fazla aktif hedef arasından birini seçebilecek;
seçilen hedef uygulamanın gerçek aktif hedefi olacak. Karttaki "Hedef yolunu aç"
eylemi Orman ana sayfasını aradan çıkarıp doğrudan seçili hedefin tam ekran
haritasını açacak.

## Veri Davranışı

- Aktif hedef, mevcut `SavingsGoals.priority` alanıyla temsil edilir.
- Seçilen hedef atomik bir veritabanı işlemiyle `priority = 0` yapılır.
- Diğer aktif hedefler kararlı sıraları korunarak `1..N` önceliklerine taşınır.
- Tamamlanmış veya silinmiş hedef aktif hedef olamaz.
- Aktif hedef tamamlanır/silinirse sıradaki en yüksek öncelikli aktif hedef otomatik
  olarak birincil olur.
- Yeni bir şema alanı veya migration eklenmez.

## Arayüz ve Navigasyon

- Hedef kartının başlık alanı buton semantiği, seçim göstergesi ve aşağı ok ile
  basılabilir hale gelir.
- Dokunulduğunda aktif hedefler; ad, ilerleme, biriken ve kalan tutarla erişilebilir
  bir alt sayfada listelenir.
- Mevcut seçim onay işareti ve "Aktif hedef" etiketiyle görünür.
- Bir hedefe dokunmak seçimi kaydeder, listeyi kapatır ve finans kartını aynı anda
  yeniler.
- "Hedef yolunu aç" butonu seçili `SavingsGoalView` ile doğrudan
  `GoalWorldMapScreen` sayfasını açar.
- Hedef yoksa kart ve harita eylemi gösterilmez; mevcut hedef oluşturma akışı
  korunur.

## Uygulama Etkisi

- Gelir/gider formlarındaki "hedefi etkilesin" seçeneği yeni aktif hedefi kullanır.
- Bağlanan yeni işlemler yalnız seçili hedefi etkiler; önceki işlemlerin `goalId`
  bağlantısı geriye dönük değiştirilmez.
- Orman büyüme hesabı ve kilometre taşı görünümü seçili aktif hedefi kullanır.
- Diğer hedeflerin birikimi, katkıları ve ödül yüksek-su işaretleri korunur.

## Hata ve Eşzamanlılık

- Seçim işlemi tek transaction içinde tamamlanır; yarım öncelik sırası oluşamaz.
- Seçilen hedef işlem sırasında silinmiş/tamamlanmışsa kullanıcıya kısa hata
  gösterilir ve snapshot yeniden yüklenir.
- Navigasyon sırasında hedef bulunamazsa Orman'a sessizce yönlendirmek yerine
  anlaşılır bir "Hedef artık aktif değil" mesajı gösterilir.

## Doğrulama

- Birden çok hedef arasında seçim birincil hedefi ve sıralamayı değiştirir.
- Seçim uygulama/snapshot yeniden yüklemesinden sonra korunur.
- Finans kartı, gelir/gider formu ve orman hesabı aynı aktif hedefi görür.
- Eski hedefe bağlı işlem bağlantıları değişmez.
- CTA doğrudan doğru hedef kimliğiyle `GoalWorldMapScreen` açar.
- Dar ekranda hedef listesi taşmaz; buton ve seçici semantiği erişilebilirdir.

