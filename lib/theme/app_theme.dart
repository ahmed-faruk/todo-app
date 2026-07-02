import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Builds the app's light and dark [ThemeData] from a single vivid
/// electric-violet seed, per the design-token spec (v3 addendum) at
/// projects/todo-app/designs/ui-revamp-design-tokens.md (ops fork).
class AppTheme {
  AppTheme._();

  static const seedColor = Color(0xFF6D28D9);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  /// Two-stop gradient for the hero header: seed color to a darker
  /// variant of the same hue, per the "Soft Gradients 2.0" spec.
  static List<Color> headerGradient(Brightness brightness) {
    final hsl = HSLColor.fromColor(seedColor);
    final darker = hsl
        .withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0))
        .toColor();
    return [seedColor, darker];
  }

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      // FAB and the selected filter segment use the raw seed color (not
      // colorScheme.primary) deliberately: M3's tonal algorithm pales
      // `primary` in dark mode for text/icon accessibility, which is right
      // for body content but produces a washed-out FAB/segment that no
      // longer reads as the same "hyper-saturated accent" as the header
      // gradient. Keeping these three elements pinned to the literal seed
      // keeps the accent visually consistent across the whole screen.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: colorScheme.primary,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? seedColor : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : colorScheme.onSurface,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : null,
        ),
      ),
    );
  }
}
