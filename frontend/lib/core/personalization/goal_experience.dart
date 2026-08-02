import 'package:flutter/material.dart';

class GoalExperience {
  const GoalExperience({
    required this.key,
    required this.icon,
    required this.accent,
    required this.speciesTr,
    required this.speciesEn,
    required this.titleTr,
    required this.titleEn,
    required this.routeTr,
    required this.routeEn,
    required this.metricTr,
    required this.metricEn,
    required this.missionTr,
    required this.missionEn,
    required this.coachTr,
    required this.coachEn,
    required this.analysisTr,
    required this.analysisEn,
    required this.tasksTr,
    required this.tasksEn,
  });

  final String key;
  final IconData icon;
  final Color accent;
  final String speciesTr;
  final String speciesEn;
  final String titleTr;
  final String titleEn;
  final String routeTr;
  final String routeEn;
  final String metricTr;
  final String metricEn;
  final String missionTr;
  final String missionEn;
  final String coachTr;
  final String coachEn;
  final String analysisTr;
  final String analysisEn;
  final List<String> tasksTr;
  final List<String> tasksEn;

  bool _isTurkish(Locale locale) => locale.languageCode == 'tr';

  String species(Locale locale) => _isTurkish(locale) ? speciesTr : speciesEn;
  String title(Locale locale) => _isTurkish(locale) ? titleTr : titleEn;
  String route(Locale locale) => _isTurkish(locale) ? routeTr : routeEn;
  String metric(Locale locale) => _isTurkish(locale) ? metricTr : metricEn;
  String mission(Locale locale) => _isTurkish(locale) ? missionTr : missionEn;
  String coach(Locale locale) => _isTurkish(locale) ? coachTr : coachEn;
  String analysis(Locale locale) =>
      _isTurkish(locale) ? analysisTr : analysisEn;
  List<String> tasks(Locale locale) => _isTurkish(locale) ? tasksTr : tasksEn;

  static const all = <GoalExperience>[
    GoalExperience(
      key: 'track_spending',
      icon: Icons.track_changes_rounded,
      accent: Color(0xFF2F7554),
      speciesTr: 'Karayemiş Ağacı',
      speciesEn: 'Laurel cherry',
      titleTr: 'Harcamamı takip etmek',
      titleEn: 'Track my spending',
      routeTr: 'Farkındalık rotası',
      routeEn: 'Awareness route',
      metricTr: 'Takip edilen gün',
      metricEn: 'Days tracked',
      missionTr: 'Bu hafta üç günün harcama ritmini görünür kıl.',
      missionEn: 'Make three days of spending visible this week.',
      coachTr:
          'Bugün yalnızca bir harcama ekle. Düzen, kusursuz olmaktan daha değerlidir.',
      coachEn:
          'Add just one expense today. Consistency matters more than perfection.',
      analysisTr: 'Kategori yoğunluğu ve sıra dışı değişimler',
      analysisEn: 'Category density and unusual changes',
      tasksTr: ['Bir gider kaydet', 'Haftalık sınırı kontrol et'],
      tasksEn: ['Log one expense', 'Check the weekly limit'],
    ),
    GoalExperience(
      key: 'save_goal',
      icon: Icons.savings_rounded,
      accent: Color(0xFF6B8F4E),
      speciesTr: 'Kermes Meşesi',
      speciesEn: 'Kermes oak',
      titleTr: 'Birikim yapmak',
      titleEn: 'Build savings',
      routeTr: 'Hedef rotası',
      routeEn: 'Goal route',
      metricTr: 'Haftalık birikim',
      metricEn: 'Weekly savings',
      missionTr: 'Güvenli bir haftalık katkı seç ve takvimde yerini ayır.',
      missionEn: 'Choose a safe weekly contribution and reserve its day.',
      coachTr:
          'Küçük ama sürdürülebilir bir katkı, büyük ve ertelenen bir plandan iyidir.',
      coachEn:
          'A small sustainable contribution beats a large plan that gets postponed.',
      analysisTr: 'Tasarruf oranı ve hedefe varış projeksiyonu',
      analysisEn: 'Savings rate and goal arrival projection',
      tasksTr: ['Hedefe katkı ayır', 'Varış tarihini gözden geçir'],
      tasksEn: ['Set aside a contribution', 'Review the arrival date'],
    ),
    GoalExperience(
      key: 'pay_debt',
      icon: Icons.trending_down_rounded,
      accent: Color(0xFF176044),
      speciesTr: 'Mersin Ağacı',
      speciesEn: 'Myrtle tree',
      titleTr: 'Borcu azaltmak',
      titleEn: 'Reduce debt',
      routeTr: 'Borçsuzluk rotası',
      routeEn: 'Debt-free route',
      metricTr: 'Sıradaki ödeme',
      metricEn: 'Next payment',
      missionTr: 'Sıradaki ödeme gününü ve güvenli ek ödeme payını belirle.',
      missionEn: 'Set the next payment day and a safe extra-payment amount.',
      coachTr:
          'Önce tabloyu görünür yapalım; hızdan önce sürdürülebilir bir ödeme ritmi gelir.',
      coachEn:
          'First make the picture visible; a sustainable payment rhythm comes before speed.',
      analysisTr: 'İki ödeme yolunun toplam maliyet farkı',
      analysisEn: 'Cost difference between snowball and avalanche',
      tasksTr: ['Ödeme gününü işaretle', 'İki ödeme yolunu karşılaştır'],
      tasksEn: ['Mark the payment day', 'Compare two strategies'],
    ),
    GoalExperience(
      key: 'learn_invest',
      icon: Icons.school_rounded,
      accent: Color(0xFF5E8F72),
      speciesTr: 'Ilgın Ağacı',
      speciesEn: 'Tamarisk tree',
      titleTr: 'Finansı öğrenmek',
      titleEn: 'Learn finance',
      routeTr: 'Bilgi rotası',
      routeEn: 'Learning route',
      metricTr: 'Öğrenme serisi',
      metricEn: 'Learning streak',
      missionTr: 'Bugün tek bir temel kavramı öğren ve kendi bütçende bul.',
      missionEn: 'Learn one core concept and find it in your own budget.',
      coachTr:
          'Bugünün konusu risk ve getiri. Ürün önermek yerine kavramı birlikte anlayacağız.',
      coachEn:
          'Today is about risk and return. We will understand the idea, not recommend a product.',
      analysisTr: 'Kişisel enflasyon ve temel risk kavramları',
      analysisEn: 'Personal inflation and core risk concepts',
      tasksTr: ['3 dakikalık dersi aç', 'Kavramı bütçende bul'],
      tasksEn: ['Open the 3-minute lesson', 'Find the concept in your budget'],
    ),
  ];

  static GoalExperience forKey(String? key) {
    return all.firstWhere(
      (experience) => experience.key == key,
      orElse: () => all.first,
    );
  }
}
