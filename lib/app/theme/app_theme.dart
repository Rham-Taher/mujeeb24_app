import 'package:flutter/material.dart';

/// Design tokens derived from Stitch Mujeeb 24 Mobile Design System
class AppColors {
  static const Color primary = Color(0xFF087FF5);
  static const Color primaryContainer = Color(0xFF0073E0);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFEFCFF);
  static const Color primaryFixed = Color(0xFFD6E3FF);

  static const Color secondary = Color(0xFF18B8F2);
  static const Color secondaryFixed = Color(0xFFDBE1FF);
  static const Color onSecondaryFixed = Color(0xFF001849);

  static const Color background = Color(0xFFFAF8FF);
  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceCanvas = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  static const Color onSurface = Color(0xFF131B2E);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color textMuted = Color(0xFF64748B);

  static const Color outline = Color(0xFF717785);
  static const Color outlineVariant = Color(0xFFC1C6D6);
  static const Color borderHairline = Color(0xFFE2E8F0);

  // Status Colors
  static const Color statusSuccess = Color(0xFF059669);
  static const Color statusSuccessContainer = Color(0xFFECFDF5);
  static const Color statusError = Color(0xFFEF4444);
  static const Color statusErrorContainer = Color(0xFFFEF2F2);
  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusWarningContainer = Color(0xFFFFFBEB);

  // AI & Channels
  static const Color aiSuggested = Color(0xFF7C3AED);
  static const Color aiSuggestedContainer = Color(0xFFF5F3FF);
  static const Color channelWhatsapp = Color(0xFF25D366);
  static const Color channelInstagram = Color(0xFFE1306C);
  static const Color channelFacebook = Color(0xFF1877F2);
  static const Color channelTelegram = Color(0xFF229ED9);
  static const Color presenceOnline = Color(0xFF10B981);

  // Design system aliases
  static const Color success = statusSuccess;
  static const Color error = statusError;
  static const Color warning = statusWarning;
  static const Color textPrimary = onSurface;
  static const Color textSecondary = textMuted;
  static const Color border = borderHairline;
  static const Color secondaryContainer = secondaryFixed;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        error: AppColors.statusError,
        onError: Colors.white,
        errorContainer: AppColors.statusErrorContainer,
        onErrorContainer: AppColors.statusError,
        surface: AppColors.surfaceCanvas,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceCanvas,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCanvas,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderHairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCanvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.statusError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.statusError, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
