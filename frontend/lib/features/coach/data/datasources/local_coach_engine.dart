import 'dart:collection';

typedef LocalCoachClock = DateTime Function();

final class LocalCoachEngine {
  LocalCoachEngine({
    this.memoryTtl = const Duration(minutes: 20),
    this.maximumSessions = 256,
    LocalCoachClock? clock,
  }) : _clock = clock ?? DateTime.now {
    if (memoryTtl <= Duration.zero || maximumSessions <= 0) {
      throw ArgumentError('Yerel koç bellek ayarları geçersiz.');
    }
  }

  final Duration memoryTtl;
  final int maximumSessions;
  final LocalCoachClock _clock;
  final LinkedHashMap<String, _LocalCoachMemory> _sessions = LinkedHashMap();

  static const _financialDisclaimer =
      '\n\nBu yanıt eğitim amaçlıdır; önemli finans kararlarında koşullarını ayrıca değerlendir.';

  static const Map<String, Map<String, int>> _intentTerms = {
    'fraud': {
      'dolandirildim': 10,
      'kartim calindi': 10,
      'izinsiz islem': 10,
      'sifrem calindi': 10,
    },
    'debt': {
      'kart borcu': 7,
      'asgari odeme': 7,
      'odeme plani': 6,
      'borc': 4,
      'kredi': 4,
      'faiz': 4,
    },
    'emergency': {'acil durum': 7, 'guvence': 4, 'acil fon': 7},
    'inflation': {
      'kisisel enflasyon': 8,
      'enflasyon': 5,
      'tuik': 5,
      'zam': 3,
      'fiyat': 3,
    },
    'receipt': {'fis tara': 8, 'fis': 4, 'fatura': 4, 'ocr': 5},
    'report': {'pdf': 6, 'rapor': 5, 'disa aktar': 5, 'indir': 2},
    'calendar': {
      'yasayan orman': 8,
      'takvim': 5,
      'seri': 4,
      'streak': 5,
      'tohum': 4,
      'orman': 4,
      'gorev': 3,
    },
    'goal': {
      'hedef rotasi': 8,
      'hedef haritasi': 8,
      'hedef yolu': 8,
      'hedef': 4,
      'rota': 3,
      'katki': 3,
    },
    'savings': {'para ayir': 7, 'birik': 5, 'tasarruf': 5},
    'budget': {'butce': 5, 'harcama': 4, 'gider': 4, 'gelir': 4, 'toparla': 3},
    'help': {'ne yapabilirsin': 9, 'neleri biliyorsun': 9, 'yardim': 6},
    'wellbeing': {'nasilsin': 8, 'ne haber': 8, 'keyfin nasil': 8},
    'thanks': {'tesekkur': 7, 'sag ol': 7, 'eyvallah': 6},
    'goodbye': {'gorusuruz': 7, 'hosca kal': 7, 'kendine iyi bak': 7, 'bye': 6},
    'greeting': {
      'gunaydin': 7,
      'iyi aksamlar': 7,
      'merhaba': 6,
      'selam': 6,
      'slm': 6,
    },
  };

  static const _financialIntents = {
    'debt',
    'emergency',
    'inflation',
    'receipt',
    'report',
    'calendar',
    'goal',
    'savings',
    'budget',
  };

  String respond({required String question, required String sessionId}) {
    final now = _clock();
    _evictExpired(now);
    final userQuestion = _extractUserQuestion(question);
    final normalizedUserQuestion = _normalize(userQuestion);
    final previous = _sessions[sessionId];
    var intent = _classify(normalizedUserQuestion);
    if (intent == 'fallback') intent = _classify(_normalize(question));
    if (_isFollowUp(normalizedUserQuestion) && previous != null) {
      intent = previous.intent;
    }

    final answer = _response(intent, normalizedUserQuestion, previous);
    if (_financialIntents.contains(intent)) {
      _sessions.remove(sessionId);
      _sessions[sessionId] = _LocalCoachMemory(intent, now);
      while (_sessions.length > maximumSessions) {
        _sessions.remove(_sessions.keys.first);
      }
      return '$answer$_financialDisclaimer';
    }
    return answer;
  }

  void _evictExpired(DateTime now) {
    final expired = _sessions.entries
        .where((entry) => now.difference(entry.value.updatedAt) > memoryTtl)
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final sessionId in expired) {
      _sessions.remove(sessionId);
    }
  }

  String _classify(String value) {
    var winner = 'fallback';
    var winningScore = 0;
    for (final intent in _intentTerms.keys) {
      final score = _intentTerms[intent]!.entries
          .where((entry) => _hasTerm(value, entry.key))
          .fold<int>(0, (total, entry) => total + entry.value);
      if (score > winningScore) {
        winner = intent;
        winningScore = score;
      }
    }
    return winner;
  }

  bool _isFollowUp(String value) {
    const followUpWords = {
      'hangisi',
      'nasil',
      'neden',
      'ne',
      'kadar',
      'peki',
      'devam',
      'olur',
      'evet',
      'tamam',
    };
    final tokens = value.split(' ').where((token) => token.isNotEmpty).toSet();
    return tokens.length <= 7 && tokens.any(followUpWords.contains);
  }

  bool _hasTerm(String value, String term) =>
      RegExp('(?:^|\\s)${RegExp.escape(term)}').hasMatch(value);

  String _extractUserQuestion(String value) {
    const marker = 'kullanıcının sorusu:';
    final index = value.toLowerCase().lastIndexOf(marker);
    return index < 0 ? value : value.substring(index + marker.length).trim();
  }

  String _normalize(String value) {
    const replacements = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };
    var normalized = value.toLowerCase();
    for (final entry in replacements.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized
        .replaceAll(RegExp('[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(' +'), ' ');
  }

  String _response(
    String intent,
    String normalized,
    _LocalCoachMemory? previous,
  ) {
    switch (intent) {
      case 'fraud':
        return 'Hemen bankanın resmî uygulamasından kartı geçici olarak kapat ve bankanın resmî destek hattını ara. Tanımadığın işlemler için itiraz kaydı oluştur; şifre, SMS kodu ve kart bilgini kimseyle paylaşma.';
      case 'greeting':
        return 'Merhaba! Ben cihazında çalışan Maki rehberiyim. Bütçe, borç, hedef, fiş, rapor, takvim ve Yaşayan Orman konusunda birlikte ilerleyebiliriz. Bugün neye bakalım?';
      case 'wellbeing':
        return 'İyiyim, teşekkür ederim. Finans yükünü biraz hafifletmeye hazırım; bugün neyi çözmek istersin?';
      case 'thanks':
        return 'Rica ederim. Küçük ama sürdürülebilir bir sonraki adımı birlikte seçebiliriz.';
      case 'goodbye':
        return 'Görüşürüz! Maki ve ormanın burada; kaldığın yerden devam edebilirsin.';
      case 'help':
        return 'Bütçe ve borç planı, birikim hedefi, fiş tarama, PDF raporları, kişisel enflasyon, takvim serisi ve Yaşayan Orman konusunda yardımcı olabilirim.';
      case 'debt':
        if (previous?.intent == 'debt' && normalized.contains('hangisi')) {
          return 'Toplam faizi azaltmak önceliğinse en yüksek faizli borçtan başlayan Çığ; hızlı moral kazanmak önceliğinse en küçük bakiyeden başlayan Kar Topu yöntemi daha uygundur. Asgari ödemeleri iki yöntemde de aksatma.';
        }
        return '1. Borçlarının kalan tutarını, faizini ve asgari ödemesini tek yerde topla. 2. Asgarileri aksatmadan ek bütçeyi en yüksek faizli borca yönelt. 3. Borç Kapatma Planı’nda Çığ ve Kar Topu seçeneklerini karşılaştır.';
      case 'emergency':
        return 'İlk hedefi bir haftalık zorunlu gider kadar belirle. Birikimi günlük harcamadan ayrı ve erişilebilir bir yerde tut; düzen oturunca hedefi bir aylık zorunlu gidere doğru büyüt.';
      case 'inflation':
        return 'Kişisel enflasyon ekranı harcama değişimini TÜİK’in resmî oranıyla aynı dönemde karşılaştırır. Sonucu açıp farkın hangi gider gruplarından geldiğini inceleyebilirsin.';
      case 'receipt':
        return 'Fiş Tara ekranında fotoğrafı net ve tam kadraj çek. Maki işletme, tarih ve toplamı önerir; kaydetmeden önce tutarı doğruladığında fiş gider kaydına dönüşür.';
      case 'report':
        return 'Ayarlar > Raporlarım bölümünden günlük, haftalık veya aylık dönem seç. PDF cihazında oluşturulur; ardından indir veya paylaş düğmesini kullanabilirsin.';
      case 'calendar':
        return 'Takvimde her gün en az bir anlamlı finans davranışı seriyi korur. Gelir veya gider kaydı, fiş onayı, günlük kontrol ve hedef katkısı ormanı büyütür.';
      case 'goal':
        return 'Hedef Rotası kartına dokunup aktif hedefini seç. Gelir veya gider kaydederken “hedefi etkilesin” seçeneğini açarsan yalnız seçili hedef ilerler; “Hedef yolunu aç” seni o hedefin haritasına götürür.';
      case 'savings':
        if (previous?.intent == 'savings' && normalized.contains('kadar')) {
          return 'Son dört haftanın zorunlu giderlerden sonraki netine bak. Küçük bir alt sınır ve rahat bir üst sınır seç; katkıyı alt sınırdan başlatıp iki hafta sonra gözden geçir.';
        }
        return 'Birikimi ay sonunda kalana bırakma; gelir geldiğinde küçük bir tutarı ayır. Hedef Rotası’nda amaç ve tarihi belirleyip takvimde haftalık katkını izle.';
      case 'budget':
        return 'Son dört haftayı zorunlu, esnek ve ertelenebilir giderler olarak ayır. Tekrarlayan küçük bir gider seçip bu hafta yalnız onu azalt; farkı aktif hedefe yönlendir.';
      default:
        return 'Bunu doğru anlamak için bir konu seçelim: bütçe, borç, birikim hedefi, fiş, rapor, kişisel enflasyon veya Yaşayan Orman.';
    }
  }
}

final class _LocalCoachMemory {
  const _LocalCoachMemory(this.intent, this.updatedAt);

  final String intent;
  final DateTime updatedAt;
}
