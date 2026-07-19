# Yerel sır yönetimi

Bu dizine gerçek sır koymayın. Yerel Compose yalnız `.env` üzerinden geçici PostgreSQL parolası
alır. Üretimde veritabanı DSN'i, JWT anahtarı, mağaza kimliği ve sağlayıcı anahtarları dağıtım
platformunun sır yöneticisinden süreç ortamına enjekte edilir.

Sırlar imaja, Compose dosyasına, loga veya Git geçmişine yazılmaz. Örnek değerler üretimde
kullanılmaz. OCR model dosyaları salt okunur volume ile bağlanır.
