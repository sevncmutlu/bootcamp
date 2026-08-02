enum DailyChallengeTrack { logging, awareness, progress }

final class DailyChallengeTemplate {
  const DailyChallengeTemplate({
    required this.id,
    required this.family,
    required this.track,
    required this.titleTr,
    required this.titleEn,
    required this.descriptionTr,
    required this.descriptionEn,
    required this.xp,
    required this.primaryTarget,
    this.secondaryTarget,
  });

  final String id;
  final String family;
  final DailyChallengeTrack track;
  final String titleTr;
  final String titleEn;
  final String descriptionTr;
  final String descriptionEn;
  final int xp;
  final int primaryTarget;
  final int? secondaryTarget;

  String title(String languageCode) => languageCode == 'tr' ? titleTr : titleEn;

  String description(String languageCode) =>
      languageCode == 'tr' ? descriptionTr : descriptionEn;
}

abstract final class DailyChallengeCatalog {
  static final List<DailyChallengeTemplate> templates = List.unmodifiable([
    ..._loggingTemplates(),
    ..._awarenessTemplates(),
    ..._progressTemplates(),
  ]);

  static final Map<String, DailyChallengeTemplate> _byId = {
    for (final template in templates) template.id: template,
  };

  static DailyChallengeTemplate? fromStorageKey(String key) {
    if (!key.startsWith('catalog:')) return null;
    final parts = key.split(':');
    if (parts.length != 3) return null;
    return _byId[parts[1]];
  }

  static DailyChallengeTemplate? fromChallengeId(String challengeId) {
    if (!challengeId.startsWith('v3_') && !challengeId.startsWith('v4_')) {
      return null;
    }
    for (final template in templates) {
      if (challengeId.contains('_${template.id}_')) return template;
    }
    return null;
  }

  static const Map<String, List<String>> routeFamilies = {
    'track_spending': [
      'log_before',
      'category_budget',
      'receipt_cap',
      'note_length',
      'daily_cap',
      'market_cap',
    ],
    'save_goal': [
      'goal_min',
      'positive_gap',
      'micro_expense',
      'restaurant_cap',
      'entertainment_cap',
      'daily_cap',
    ],
    'pay_debt': [
      'positive_gap',
      'income_min',
      'daily_cap',
      'entertainment_cap',
      'restaurant_cap',
      'goal_min',
    ],
    'learn_invest': [
      'income_min',
      'positive_gap',
      'note_length',
      'category_budget',
      'daily_cap',
      'goal_min',
    ],
  };

  static const _habitFamilies = [
    'log_before',
    'receipt_cap',
    'note_length',
    'micro_expense',
  ];

  static List<DailyChallengeTemplate> selectionForDay(
    DateTime day, {
    String routeKey = 'track_spending',
  }) {
    final seed = day.year * 372 + day.month * 31 + day.day;
    final families =
        routeFamilies[routeKey] ?? routeFamilies['track_spending']!;
    final selected = <DailyChallengeTemplate>[];
    for (var slot = 0; slot < 3; slot++) {
      final family = families[(seed + slot * 5) % families.length];
      final candidates = templates
          .where((item) => item.family == family)
          .toList();
      selected.add(
        candidates[(seed * (slot + 1) + slot * 11) % candidates.length],
      );
    }
    final bonusFamilies = _habitFamilies
        .where((family) => !selected.any((item) => item.family == family))
        .toList(growable: false);
    final bonusFamily = bonusFamilies[(seed * 7 + 11) % bonusFamilies.length];
    final bonusCandidates = templates
        .where((item) => item.family == bonusFamily)
        .toList(growable: false);
    selected.add(bonusCandidates[(seed * 7 + 11) % bonusCandidates.length]);
    return List.unmodifiable(selected);
  }

  static List<DailyChallengeTemplate> _loggingTemplates() => [
    for (var index = 0; index < 25; index++) _logBeforeTemplate(index),
    for (var index = 0; index < 25; index++) _categoryBudgetTemplate(index),
    for (var index = 0; index < 25; index++) _receiptTemplate(index),
    for (var index = 0; index < 25; index++) _noteTemplate(index),
  ];

  static List<DailyChallengeTemplate> _awarenessTemplates() => [
    for (var index = 0; index < 25; index++)
      _spendCapTemplate(
        'daily_cap',
        'Günlük sınır',
        'Daily cap',
        150 + index * 50,
        index,
      ),
    for (var index = 0; index < 25; index++)
      _spendCapTemplate(
        'transport_cap',
        'Ulaşım sınırı',
        'Transport cap',
        20 + index * 10,
        index,
      ),
    for (var index = 0; index < 25; index++)
      _spendCapTemplate(
        'restaurant_cap',
        'Dışarıda yemek sınırı',
        'Dining cap',
        index * 20,
        index,
      ),
    for (var index = 0; index < 25; index++)
      _spendCapTemplate(
        'market_cap',
        'Market sınırı',
        'Groceries cap',
        100 + index * 25,
        index,
      ),
    for (var index = 0; index < 25; index++)
      _spendCapTemplate(
        'entertainment_cap',
        'Eğlence sınırı',
        'Entertainment cap',
        index * 15,
        index,
      ),
  ];

  static List<DailyChallengeTemplate> _progressTemplates() => [
    for (var index = 0; index < 25; index++)
      _minimumTemplate(
        'income_min',
        'Gelir izi',
        'Income footprint',
        100 + index * 100,
        index,
      ),
    for (var index = 0; index < 25; index++)
      _minimumTemplate(
        'positive_gap',
        'Yeşil denge',
        'Positive balance',
        index * 50,
        index,
      ),
    for (var index = 0; index < 25; index++)
      _minimumTemplate(
        'goal_min',
        'Hedefe yaprak',
        'Leaf for a goal',
        20 + index * 20,
        index,
      ),
    for (var index = 0; index < 25; index++) _microTemplate(index),
  ];

  static DailyChallengeTemplate _logBeforeTemplate(int index) {
    const deadlines = [10, 12, 15, 18, 22];
    final count = index % 5 + 1;
    final hour = deadlines[index ~/ 5];
    return DailyChallengeTemplate(
      id: 'log_${count}_before_$hour',
      family: 'log_before',
      track: DailyChallengeTrack.logging,
      titleTr: '$hour.00 öncesi $count kayıt',
      titleEn: '$count records before $hour:00',
      descriptionTr: 'Saat $hour.00 olmadan $count gelir veya gider kaydet.',
      descriptionEn: 'Record $count income or expense items before $hour:00.',
      xp: 10 + count * 3,
      primaryTarget: count,
      secondaryTarget: hour,
    );
  }

  static DailyChallengeTemplate _categoryBudgetTemplate(int index) {
    const caps = [200, 350, 500, 750, 1000];
    final categoryCount = index % 5 + 2;
    final cap = caps[index ~/ 5];
    return DailyChallengeTemplate(
      id: 'categories_${categoryCount}_cap_$cap',
      family: 'category_budget',
      track: DailyChallengeTrack.logging,
      titleTr: '$categoryCount dallı kayıt',
      titleEn: '$categoryCount-branch log',
      descriptionTr:
          '$categoryCount farklı kategoride kayıt tut ve toplam gideri $cap TL altında bırak.',
      descriptionEn:
          'Use $categoryCount categories and keep total expenses below ₺$cap.',
      xp: 15 + categoryCount * 2,
      primaryTarget: categoryCount,
      secondaryTarget: cap,
    );
  }

  static DailyChallengeTemplate _receiptTemplate(int index) {
    final cap = 50 + index * 50;
    return DailyChallengeTemplate(
      id: 'receipt_cap_$cap',
      family: 'receipt_cap',
      track: DailyChallengeTrack.logging,
      titleTr: '$cap TL fiş kâşifi',
      titleEn: '₺$cap receipt explorer',
      descriptionTr:
          'Toplamı $cap TL veya altında olan bir fişi tara ve onayla.',
      descriptionEn: 'Scan and confirm a receipt totaling ₺$cap or less.',
      xp: 18 + index ~/ 5,
      primaryTarget: cap,
    );
  }

  static DailyChallengeTemplate _noteTemplate(int index) {
    final length = index + 3;
    return DailyChallengeTemplate(
      id: 'note_length_$length',
      family: 'note_length',
      track: DailyChallengeTrack.logging,
      titleTr: '$length harflik hafıza',
      titleEn: '$length-character memory',
      descriptionTr:
          'Bir giderine en az $length karakterlik açıklayıcı bir not ekle.',
      descriptionEn:
          'Add a descriptive note of at least $length characters to an expense.',
      xp: 12 + index ~/ 4,
      primaryTarget: length,
    );
  }

  static DailyChallengeTemplate _spendCapTemplate(
    String family,
    String titleTr,
    String titleEn,
    int cap,
    int index,
  ) => DailyChallengeTemplate(
    id: '${family}_$cap',
    family: family,
    track: DailyChallengeTrack.awareness,
    titleTr: '$titleTr · $cap TL',
    titleEn: '$titleEn · ₺$cap',
    descriptionTr: 'Bugün ilgili harcamayı $cap TL sınırında veya altında tut.',
    descriptionEn: 'Keep the related spending at or below ₺$cap today.',
    xp: 18 + (24 - index) ~/ 5,
    primaryTarget: cap,
  );

  static DailyChallengeTemplate _minimumTemplate(
    String family,
    String titleTr,
    String titleEn,
    int target,
    int index,
  ) => DailyChallengeTemplate(
    id: '${family}_$target',
    family: family,
    track: DailyChallengeTrack.progress,
    titleTr: '$titleTr · $target TL',
    titleEn: '$titleEn · ₺$target',
    descriptionTr: switch (family) {
      'income_min' => 'Bugün en az $target TL gelir kaydet.',
      'positive_gap' =>
        'Kayıtlı gelirini giderinden en az $target TL yukarıda tut.',
      _ => 'Bugün bir hedef rotasına en az $target TL katkı ekle.',
    },
    descriptionEn: switch (family) {
      'income_min' => 'Record at least ₺$target of income today.',
      'positive_gap' =>
        'Keep recorded income at least ₺$target above expenses.',
      _ => 'Add at least ₺$target to a goal route today.',
    },
    xp: 18 + index ~/ 4,
    primaryTarget: target,
  );

  static DailyChallengeTemplate _microTemplate(int index) {
    final cap = 20 + index * 5;
    return DailyChallengeTemplate(
      id: 'micro_expense_$cap',
      family: 'micro_expense',
      track: DailyChallengeTrack.progress,
      titleTr: '$cap TL mikro adım',
      titleEn: '₺$cap micro step',
      descriptionTr: '$cap TL veya altında gerçek bir gider kaydet.',
      descriptionEn: 'Record a real expense of ₺$cap or less.',
      xp: 15 + index ~/ 5,
      primaryTarget: cap,
    );
  }
}
