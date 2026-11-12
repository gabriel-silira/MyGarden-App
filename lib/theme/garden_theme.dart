import 'package:flutter/material.dart';

abstract final class GardenTheme {
  static const forest = Color(0xFF002519);
  static const green = Color(0xFF187510);
  static const lime = Color(0xFFB4F25B);
  static const mist = Color(0xFFE5F6D9);
  static const paper = Color(0xFFF4FAEF);
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(seedColor: green, brightness: brightness).copyWith(
          primary: dark ? lime : green,
          onPrimary: dark ? forest : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF155C21)
              : const Color(0xFFD4F6B4),
          onPrimaryContainer: dark
              ? const Color(0xFFD8FFA6)
              : const Color(0xFF124F0D),
          secondary: dark ? const Color(0xFF9EDC79) : const Color(0xFF387B26),
          surface: dark ? const Color(0xFF001B11) : paper,
          onSurface: dark ? const Color(0xFFF2F9EF) : const Color(0xFF132416),
          onSurfaceVariant: dark
              ? const Color(0xFFBBD1C0)
              : const Color(0xFF46604A),
          surfaceContainerLow: dark
              ? const Color(0xFF042D1D)
              : const Color(0xFFF8FFF2),
          surfaceContainerHighest: dark
              ? const Color(0xFF12452E)
              : const Color(0xFFE3F4D6),
          outline: dark ? const Color(0xFF7DAD88) : const Color(0xFF66855D),
          outlineVariant: dark
              ? const Color(0xFF24513A)
              : const Color(0xFFCDDEC4),
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge!.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -.9,
        ),
        headlineMedium: base.textTheme.headlineMedium!.copyWith(
          fontSize: 27,
          fontWeight: FontWeight.w700,
          letterSpacing: -.7,
        ),
        titleLarge: base.textTheme.titleLarge!.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -.4,
        ),
        titleMedium: base.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge!.copyWith(
          fontSize: 15,
          height: 1.4,
        ),
        bodyMedium: base.textTheme.bodyMedium!.copyWith(
          fontSize: 14,
          height: 1.4,
        ),
        bodySmall: base.textTheme.bodySmall!.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        elevation: 0,
        titleTextStyle: base.textTheme.titleLarge!.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .7),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
    );
  }
}
