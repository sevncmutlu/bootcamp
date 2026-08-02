import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 36;
  static const double xxxl = 52;

  static const EdgeInsets screen = EdgeInsets.all(lg);
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: lg);
}

class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

class ForestColors {
  ForestColors._();

  // Maki's core palette is taken from Mediterranean woodland rather than
  // generic neon fintech greens.
  static const Color emerald = Color(0xFF0E4B36);
  static const Color emeraldDark = Color(0xFF082F24);
  static const Color emeraldLight = Color(0xFF69B86D);

  static const Color amber = Color(0xFFD7A84A);
  static const Color amberDark = Color(0xFFB78328);

  static const Color cream = Color(0xFFE5ECE5);
  static const Color creamSoft = Color(0xFFF3F6F1);
  static const Color paper = Color(0xFFFCFDF9);
  static const Color neutral = Color(0xFF5A685F);

  static const Color canopy = Color(0xFF1D5B40);
  static const Color moss = Color(0xFF73976B);
  static const Color sage = Color(0xFFC9D8B5);
  static const Color fern = Color(0xFF397A57);
  static const Color lichen = Color(0xFFDCE5CF);

  static const Color bark = Color(0xFF6D4C2F);
  static const Color soil = Color(0xFF4E342E);
  static const Color sand = Color(0xFFF1EFE6);

  static const Color sky = Color(0xFF7EC8E3);
  static const Color dawn = Color(0xFFF2C15A);
  static const Color sunset = Color(0xFFFF9E7A);

  static const Color night = Color(0xFF071A14);
  static const Color nightSurface = Color(0xFF0B211A);
  static const Color nightElevated = Color(0xFF123026);

  static const Color income = Color(0xFF3E9B62);
  static const Color expense = Color(0xFFC8623F);
  static const Color warning = Color(0xFFD7A84A);
  static const Color info = Color(0xFF3F7698);
}

class BrandAccent {
  const BrandAccent(this.key, this.color);

  final String key;
  final Color color;
}

class BrandAccents {
  BrandAccents._();

  static const BrandAccent forest = BrandAccent('forest', ForestColors.emerald);
  static const BrandAccent navy = BrandAccent('navy', Color(0xFF21386E));
  static const BrandAccent amber = BrandAccent('amber', ForestColors.amber);
  static const BrandAccent purple = BrandAccent('purple', Color(0xFF7E57C2));
  static const BrandAccent pink = BrandAccent('pink', Color(0xFFE5779B));

  static const List<BrandAccent> all = [forest, navy, amber, purple, pink];

  static const BrandAccent defaultAccent = forest;

  static Color colorForKey(String? key) {
    return all
        .firstWhere((a) => a.key == key, orElse: () => defaultAccent)
        .color;
  }
}

@immutable
class MakiPalette extends ThemeExtension<MakiPalette> {
  const MakiPalette({
    required this.heroStart,
    required this.heroEnd,
    required this.onHero,
    required this.onHeroMuted,
    required this.income,
    required this.expense,
    required this.warning,
    required this.info,
    required this.shadow,
  });

  final Color heroStart;
  final Color heroEnd;
  final Color onHero;
  final Color onHeroMuted;
  final Color income;
  final Color expense;
  final Color warning;
  final Color info;
  final Color shadow;

  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [heroStart, heroEnd],
  );

  static MakiPalette fromSeed(Color seed, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final start = _heroTone(seed, isDark ? 0.16 : 0.19);
    final end = _heroTone(seed, isDark ? 0.31 : 0.35);

    return MakiPalette(
      heroStart: start,
      heroEnd: end,
      onHero: Colors.white,
      onHeroMuted: Colors.white.withValues(alpha: 0.78),
      income: isDark ? const Color(0xFF74D49A) : ForestColors.income,
      expense: isDark ? const Color(0xFFFFB59D) : ForestColors.expense,
      warning: isDark ? const Color(0xFFF2C96D) : ForestColors.warning,
      info: isDark ? const Color(0xFF8AC8EE) : ForestColors.info,
      shadow: Color.alphaBlend(
        seed.withValues(alpha: isDark ? 0.16 : 0.22),
        Colors.black,
      ),
    );
  }

  static Color _heroTone(Color color, double lightness) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(lightness)
        .withSaturation(hsl.saturation.clamp(0.42, 0.78))
        .toColor();
  }

  @override
  MakiPalette copyWith({
    Color? heroStart,
    Color? heroEnd,
    Color? onHero,
    Color? onHeroMuted,
    Color? income,
    Color? expense,
    Color? warning,
    Color? info,
    Color? shadow,
  }) {
    return MakiPalette(
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      onHero: onHero ?? this.onHero,
      onHeroMuted: onHeroMuted ?? this.onHeroMuted,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  MakiPalette lerp(covariant MakiPalette? other, double t) {
    if (other == null) return this;
    return MakiPalette(
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension MakiThemeData on ThemeData {
  MakiPalette get makiPalette =>
      extension<MakiPalette>() ??
      MakiPalette.fromSeed(colorScheme.primary, brightness);
}

class AppGradients {
  AppGradients._();

  static const LinearGradient canopy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ForestColors.emeraldDark,
      ForestColors.emerald,
      ForestColors.canopy,
    ],
    stops: [0, 0.62, 1],
  );

  static const LinearGradient dawn = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ForestColors.amberDark, ForestColors.amber],
  );

  static const LinearGradient moonlit = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ForestColors.nightElevated, ForestColors.canopy],
  );

  static LinearGradient hero(MakiPalette palette) => palette.heroGradient;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft(Brightness brightness, Color accent) => [
    BoxShadow(
      color: (brightness == Brightness.dark ? Colors.black : accent).withValues(
        alpha: brightness == Brightness.dark ? 0.28 : 0.07,
      ),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> dock(Brightness brightness, Color accent) => [
    BoxShadow(
      color: (brightness == Brightness.dark ? Colors.black : accent).withValues(
        alpha: brightness == Brightness.dark ? 0.42 : 0.12,
      ),
      blurRadius: 32,
      offset: const Offset(0, 14),
    ),
  ];
}
