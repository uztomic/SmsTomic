import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gul do'koni SMS ilovasining yagona dizayn manbasi. Rang, shrift,
/// yumaloqlik va komponent uslublari shu yerda belgilanadi — ekranlar
/// bevosita rang yozmaydi, faqat shu tema orqali foydalanadi.
abstract class AppColors {
  static const rose = Color(0xFFC24875);
  static const roseDark = Color(0xFF8E2F55);
  static const roseLight = Color(0xFFF6DCE6);
  static const leaf = Color(0xFF5C8A66);
  static const cream = Color(0xFFFBF5F2);
  static const ink = Color(0xFF241922);
  static const charcoal = Color(0xFF17111A);
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.rose,
      brightness: brightness,
      primary: isDark ? const Color(0xFFF3A8C4) : AppColors.rose,
      secondary: AppColors.leaf,
      surface: isDark ? AppColors.charcoal : AppColors.cream,
    );

    final baseText = GoogleFonts.plusJakartaSansTextTheme();
    final textTheme = baseText.copyWith(
      headlineSmall: baseText.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: baseText.bodyLarge?.copyWith(height: 1.4),
      bodyMedium: baseText.bodyMedium?.copyWith(height: 1.4),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme.apply(
        bodyColor: isDark ? Colors.white : AppColors.ink,
        displayColor: isDark ? Colors.white : AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: isDark ? Colors.white : AppColors.ink,
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.ink),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.roseLight,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.roseLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.roseLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: isDark ? AppColors.ink : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.roseLight,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: isDark ? Colors.white : AppColors.roseDark,
          fontSize: 12,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.charcoal : Colors.white,
        indicatorColor: AppColors.roseLight,
        elevation: 3,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelLarge?.copyWith(
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? AppColors.roseDark
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.roseDark
                : (isDark ? Colors.white70 : Colors.black45),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.roseLight,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isDark ? Colors.white : AppColors.ink,
        contentTextStyle: TextStyle(color: isDark ? AppColors.ink : Colors.white),
      ),
    );
  }
}
