import 'package:flutter/material.dart';
import '../models/models.dart';

/// Container for the app's light and dark themes.
class AppTheme {
  static const Color _seed = Colors.teal;

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.grey.shade50,
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
  );

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF0E1414),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF243030)),
      ),
      color: const Color(0xFF182020),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Color(0xFF0E1414),
    ),
  );
}

/// A pair of colours that adapt to the current brightness:
/// [fg] for text/icons, [bg] for the container background.
class SeverityColors {
  final Color fg;
  final Color bg;
  const SeverityColors(this.fg, this.bg);
}

/// Returns a (foreground, background) pair for each severity level,
/// correct in both light and dark mode.
SeverityColors severityColors(BuildContext context, Severity s) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return switch (s) {
    Severity.critical => SeverityColors(
      isDark ? Colors.red.shade200 : Colors.red.shade900,
      isDark ? Colors.red.shade900.withOpacity(0.25) : Colors.red.shade50,
    ),
    Severity.warning => SeverityColors(
      isDark ? Colors.orange.shade200 : Colors.orange.shade900,
      isDark ? Colors.orange.shade900.withOpacity(0.25) : Colors.orange.shade50,
    ),
    Severity.info => SeverityColors(
      isDark ? Colors.blue.shade200 : Colors.blue.shade900,
      isDark ? Colors.blue.shade900.withOpacity(0.25) : Colors.blue.shade50,
    ),
  };
}

/// Teal accent for recommendation banners, correct in both modes.
SeverityColors accentBanner(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return SeverityColors(
    isDark ? Colors.teal.shade200 : Colors.teal.shade900,
    isDark ? Colors.teal.shade900.withOpacity(0.25) : Colors.teal.shade50,
  );
}

/// Green success banner (e.g. "no alerts — all good"), correct in both modes.
SeverityColors successBanner(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return SeverityColors(
    isDark ? Colors.green.shade200 : Colors.green.shade900,
    isDark ? Colors.green.shade900.withOpacity(0.25) : Colors.green.shade50,
  );
}
