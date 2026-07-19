import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const EdgeInsets screen = EdgeInsets.all(lg);
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: lg);
}

class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

class ForestColors {
  ForestColors._();

  static const Color emerald = Color(0xFF2E7D4D); // Marka yeşili.
  static const Color emeraldDark = Color(0xFF1F5A3A); // Koyu orman tonu.
  static const Color emeraldLight = Color(0xFF5BB55F); // Koyu tema tonu.

  static const Color amber = Color(0xFFF2C15A);
  static const Color amberDark = Color(0xFFD9A431);

  static const Color cream = Color(0xFFF7F2E7);
  static const Color creamSoft = Color(0xFFF7F2E7); // Sayfa zemini.
  static const Color neutral = Color(0xFF686F76);

  static const Color canopy = Color(0xFF1F5A3A);
  static const Color moss = Color(0xFF43A047);
  static const Color sage = Color(0xFFA5D6A7);
  static const Color fern = Color(0xFF2E7D5B);

  static const Color bark = Color(0xFF6D4C2F);
  static const Color soil = Color(0xFF4E342E);
  static const Color sand = Color(0xFFF7F2E7);

  static const Color sky = Color(0xFF7EC8E3);
  static const Color dawn = Color(0xFFF2C15A);
  static const Color sunset = Color(0xFFFF9E7A);

  static const Color night = Color(0xFF0E1512);
  static const Color nightSurface = Color(0xFF15201B);
  static const Color nightElevated = Color(0xFF1C2A23);

  static const Color income = Color(0xFF2E7D4D);
  static const Color expense = Color(0xFFE2703A);
  static const Color warning = Color(0xFFF2C15A);
  static const Color info = Color(0xFF3D8BC4);
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

class AppGradients {
  AppGradients._();

  static const LinearGradient canopy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ForestColors.emeraldDark, ForestColors.emerald],
  );

  static const LinearGradient dawn = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ForestColors.dawn, ForestColors.emeraldLight],
  );

  static const LinearGradient moonlit = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ForestColors.nightElevated, ForestColors.canopy],
  );

  static LinearGradient hero(Brightness brightness) =>
      brightness == Brightness.dark ? moonlit : canopy;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft(Brightness brightness) => [
    BoxShadow(
      color:
          (brightness == Brightness.dark ? Colors.black : ForestColors.canopy)
              .withValues(alpha: brightness == Brightness.dark ? 0.35 : 0.08),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}
