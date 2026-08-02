import 'package:flutter/material.dart';
import 'package:maki_app/core/theme/app_tokens.dart';

class AppTheme {
  AppTheme._();

  static const Color primarySeedColor = ForestColors.emerald;
  static const double cardBorderRadius = AppRadius.lg;

  static ThemeData get lightTheme => light();
  static ThemeData get darkTheme => dark();

  static ThemeData light([Color? accent]) =>
      _build(Brightness.light, accent ?? primarySeedColor);

  static ThemeData dark([Color? accent]) =>
      _build(Brightness.dark, accent ?? primarySeedColor);

  static Color _surfaceTone(Color seed, Brightness brightness, int elevation) {
    final isDark = brightness == Brightness.dark;
    final base = isDark
        ? switch (elevation) {
            0 => const Color(0xFF080D0B),
            1 => const Color(0xFF0C1210),
            2 => const Color(0xFF111815),
            3 => const Color(0xFF161F1B),
            _ => const Color(0xFF1B2721),
          }
        : switch (elevation) {
            0 => const Color(0xFFFBFCFA),
            1 => const Color(0xFFFFFFFF),
            2 => const Color(0xFFF6F8F5),
            3 => const Color(0xFFEEF2ED),
            _ => const Color(0xFFE6ECE7),
          };
    final opacity = isDark
        ? switch (elevation) {
            0 => 0.12,
            1 => 0.14,
            2 => 0.17,
            3 => 0.20,
            _ => 0.24,
          }
        : switch (elevation) {
            0 => 0.035,
            1 => 0.025,
            2 => 0.055,
            3 => 0.08,
            _ => 0.11,
          };
    return Color.alphaBlend(seed.withValues(alpha: opacity), base);
  }

  static ThemeData _build(Brightness brightness, Color seed) {
    final isDark = brightness == Brightness.dark;
    final generated = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final scheme = generated.copyWith(
      surface: _surfaceTone(seed, brightness, 0),
      surfaceContainerLowest: _surfaceTone(seed, brightness, 1),
      surfaceContainerLow: _surfaceTone(seed, brightness, 2),
      surfaceContainer: _surfaceTone(seed, brightness, 3),
      surfaceContainerHigh: _surfaceTone(seed, brightness, 4),
      surfaceContainerHighest: _surfaceTone(seed, brightness, 5),
      error: isDark ? const Color(0xFFFFB59D) : ForestColors.expense,
      onError: isDark ? const Color(0xFF5A1B0A) : Colors.white,
      errorContainer: isDark
          ? const Color(0xFF7C2E18)
          : const Color(0xFFFFDBCF),
      onErrorContainer: isDark
          ? const Color(0xFFFFDBCF)
          : const Color(0xFF3B0A00),
    );
    final palette = MakiPalette.fromSeed(seed, brightness);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'MakiSans',
    );

    final textTheme = base.textTheme
        .copyWith(
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontFamily: 'MakiDisplay',
            fontWeight: FontWeight.w800,
            letterSpacing: -2.2,
            height: 0.96,
          ),
          displayMedium: base.textTheme.displayMedium?.copyWith(
            fontFamily: 'MakiDisplay',
            fontWeight: FontWeight.w800,
            letterSpacing: -1.7,
            height: 1,
          ),
          displaySmall: base.textTheme.displaySmall?.copyWith(
            fontFamily: 'MakiDisplay',
            fontWeight: FontWeight.w800,
            letterSpacing: -1.15,
            height: 1.04,
          ),
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontFamily: 'MakiDisplay',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.9,
            height: 1.08,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontFamily: 'MakiDisplay',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            height: 1.1,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontFamily: 'MakiDisplay',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.12,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.35,
            height: 1.18,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            height: 1.45,
            letterSpacing: -0.05,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            height: 1.45,
            letterSpacing: -0.02,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
          ),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.card,
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[palette],
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 68,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0.35,
        shadowColor: palette.shadow.withValues(alpha: 0.13),
        color: scheme.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(
            color: scheme.outlineVariant.withValues(
              alpha: isDark ? 0.42 : 0.58,
            ),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 23 : 22,
            color: selected
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant.withValues(alpha: 0.68),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: scheme.primaryContainer,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: scheme.onPrimaryContainer,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: textTheme.titleMedium,
        unselectedLabelStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          textStyle: textTheme.titleMedium,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 52),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          textStyle: textTheme.titleMedium,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
          textStyle: textTheme.titleMedium,
          minimumSize: const Size(64, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.card),
          ),
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primary.withValues(alpha: 0.06),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.25)),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.primary),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      searchViewTheme: SearchViewThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.72),
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer.withValues(alpha: 0.7),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: outline(Colors.transparent, 0),
        enabledBorder: outline(scheme.outline.withValues(alpha: 0.12)),
        focusedBorder: outline(scheme.primary, 1.5),
        errorBorder: outline(scheme.error, 1.2),
        focusedErrorBorder: outline(scheme.error, 1.5),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}
