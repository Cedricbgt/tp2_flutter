import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette de l'application. Les écrans n'utilisent que ces constantes.
abstract final class AppColors {
  static const ink = Color(0xFF111318);
  static const background = Color(0xFFF4F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const accent = Color(0xFFC6F432);

  /// Variante foncée de l'accent, lisible sur fond clair (point du logo).
  static const accentOnLight = Color(0xFF6B8E00);
  static const textSecondary = Color(0xFF5B606B);
  static const textOnDark = Color(0xFFA9AEB8);
  static const placeholder = Color(0xFF8A8F99);
  static const border = Color(0xFFE3E5EA);
  static const readonlyFill = Color(0xFFECEEF1);
  static const darkInput = Color(0xFF1A1D24);
  static const darkBorder = Color(0xFF2E323C);
  static const darkTile = Color(0xFF2A2E37);
  static const danger = Color(0xFFB42318);
}

/// Rayons communs.
abstract final class AppRadius {
  static const input = 14.0;
  static const inputLarge = 16.0;
  static const tile = 20.0;
  static const card = 24.0;
  static const cardLarge = 28.0;
  static const sheet = 32.0;
}

abstract final class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.surface,
      secondary: AppColors.accent,
      onSecondary: AppColors.ink,
      error: AppColors.danger,
      onError: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
    );

    final base = GoogleFonts.plusJakartaSansTextTheme();
    TextStyle? style(
      TextStyle? s,
      double size,
      FontWeight weight, {
      double letterSpacing = 0,
      double? height,
    }) => s?.copyWith(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: AppColors.ink,
    );

    final textTheme = base.copyWith(
      displaySmall: style(
        base.displaySmall,
        40,
        FontWeight.w800,
        letterSpacing: -1.5,
        height: 1.05,
      ),
      headlineMedium: style(
        base.headlineMedium,
        30,
        FontWeight.w800,
        letterSpacing: -1,
        height: 1.1,
      ),
      headlineSmall: style(
        base.headlineSmall,
        22,
        FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: style(
        base.titleLarge,
        20,
        FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleMedium: style(
        base.titleMedium,
        18,
        FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleSmall: style(base.titleSmall, 15, FontWeight.w800),
      bodyLarge: style(base.bodyLarge, 16, FontWeight.w500),
      bodyMedium: style(base.bodyMedium, 14, FontWeight.w500),
      bodySmall: style(base.bodySmall, 13, FontWeight.w500),
      labelLarge: style(base.labelLarge, 16, FontWeight.w800),
      labelMedium: style(base.labelMedium, 12, FontWeight.w600),
    );

    OutlineInputBorder inputBorder(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.placeholder),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        disabledBorder: inputBorder(Colors.transparent),
        focusedBorder: inputBorder(AppColors.ink, width: 1.5),
        errorBorder: inputBorder(AppColors.danger),
        focusedErrorBorder: inputBorder(AppColors.danger, width: 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.ink.withValues(alpha: 0.6),
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.surface,
          minimumSize: const Size(44, 56),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surface,
          minimumSize: const Size(44, 44),
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
          textStyle: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
      ),
    );
  }
}
