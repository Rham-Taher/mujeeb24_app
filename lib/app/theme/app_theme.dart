import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

/// Design tokens derived from Mujeeb24 Blue Primary Brand Identity

/// Ensures ScreenUtil has a fallback configuration in standalone/testing environments
void ensureScreenUtilInitialized([Size designSize = const Size(390, 844)]) {
  try {
    10.sp;
    10.h;
    10.w;
  } catch (_) {
    ScreenUtil.configure(
      data: MediaQueryData(size: designSize),
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: true,
    );
  }
}

class AppColors {
  // --- Mujeeb24 Master Blue Brand Palette ---
  static const Color primaryBlue = Color(0xFF0866D9);
  static const Color primaryBlueDark = Color(0xFF064DA8);
  static const Color primaryBlueLight = Color(0xFFE8F2FF);
  static const Color primaryBlueSurface = Color(0xFFF3F8FF);
  static const Color background = Color(0xFFF7FAFF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color navyText = Color(0xFF102B50);
  static const Color secondaryText = Color(0xFF71839B);
  static const Color border = Color(0xFFDCE9FA);
  static const Color successGreen = Color(0xFF12A76A);
  static const Color errorRed = Color(0xFFE5484D);
  static const Color warningAmber = Color(0xFFE9A23B);

  // Core Semantic Aliases & Material 3 Roles
  static const Color primary = primaryBlue;
  static const Color primaryDark = primaryBlueDark;
  static const Color primaryLight = primaryBlueLight;
  static const Color primarySurface = primaryBlueSurface;
  static const Color primaryContainer = primaryBlueLight;
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = primaryBlueDark;
  static const Color primaryFixed = primaryBlueLight;

  static const Color secondary = primaryBlueDark;
  static const Color secondaryFixed = primaryBlueLight;
  static const Color onSecondaryFixed = primaryBlueDark;
  static const Color secondaryContainer = primaryBlueLight;

  static const Color surface = background;
  static const Color surfaceCanvas = cardWhite;
  static const Color lightBlueBackground = background;
  static const Color surfaceContainerLow = primaryBlueSurface;
  static const Color surfaceContainer = primaryBlueLight;
  static const Color surfaceContainerHigh = border;
  static const Color surfaceSubtle = primaryBlueSurface;
  static const Color surfaceMuted = primaryBlueSurface;

  static const Color headingNavy = navyText;
  static const Color onSurface = navyText;
  static const Color onSurfaceVariant = secondaryText;
  static const Color textMuted = secondaryText;
  static const Color textPrimary = navyText;
  static const Color textSecondary = secondaryText;

  static const Color outline = secondaryText;
  static const Color outlineVariant = border;
  static const Color borderHairline = border;
  static const Color borderLightBlue = border;

  // Status Colors
  static const Color statusSuccess = successGreen;
  static const Color statusSuccessContainer = Color(0xFFE8F8F0);
  static const Color statusError = errorRed;
  static const Color statusErrorContainer = Color(0xFFFFECEE);
  static const Color statusWarning = warningAmber;
  static const Color statusWarningContainer = Color(0xFFFFF7EB);
  static const Color success = successGreen;
  static const Color error = errorRed;
  static const Color warning = warningAmber;

  // Disabled States
  static const Color disabledBackground = Color(0xFFF1F5F9);
  static const Color disabledText = Color(0xFF94A3B8);
  static const Color disabledBorder = Color(0xFFE2E8F0);

  // AI & Authentic External Platform Channels
  static const Color aiSuggested = Color(0xFF7C3AED);
  static const Color aiSuggestedContainer = Color(0xFFF5F3FF);
  static const Color channelWhatsapp = Color(0xFF25D366);
  static const Color channelInstagram = Color(0xFFE1306C);
  static const Color channelFacebook = Color(0xFF1877F2);
  static const Color channelTelegram = Color(0xFF229ED9);
  static const Color presenceOnline = Color(0xFF10B981);
  static const Color presenceOffline = Color(0xFF94A3B8);
}

/// Typography scale matching Mujeeb24 Design System for Arabic and Latin content
class AppTypography {
  static const TextStyle pageTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.headingNavy,
    letterSpacing: -0.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.headingNavy,
    letterSpacing: -0.1,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.headingNavy,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.4,
  );

  static const TextStyle secondaryText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
  );

  static const TextStyle numericHighlight = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryBlue,
    letterSpacing: -0.5,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Exact Stitch Reference System Aliases
  static const TextStyle displayLg = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.headingNavy,
    letterSpacing: -0.5,
  );

  static const TextStyle statLg = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.headingNavy,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMd = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.headingNavy,
    letterSpacing: -0.2,
  );

  static const TextStyle headlineSm = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.headingNavy,
    letterSpacing: -0.1,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.headingNavy,
    height: 1.4,
  );

  static const TextStyle bodyBase = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.4,
  );

  static const TextStyle labelCaps = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.2,
  );

  static const TextStyle captionSm = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.3,
  );

  static const TextStyle codeMono = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    fontFamily: 'monospace',
  );

  /// Helper to convert any TextStyle to responsive font size using flutter_screenutil (.sp)
  static TextStyle responsive(TextStyle style) {
    ensureScreenUtilInitialized();
    if (style.fontSize == null) return style;
    return style.copyWith(fontSize: style.fontSize!.sp);
  }
}

/// Spacing tokens matching Mujeeb24 Design System
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;

  // Responsive distances and paddings via flutter_screenutil
  static double get rXs { ensureScreenUtilInitialized(); return xs.r; }
  static double get rSm { ensureScreenUtilInitialized(); return sm.r; }
  static double get rMd { ensureScreenUtilInitialized(); return md.r; }
  static double get rLg { ensureScreenUtilInitialized(); return lg.r; }
  static double get rXl { ensureScreenUtilInitialized(); return xl.r; }
  static double get rXxl { ensureScreenUtilInitialized(); return xxl.r; }
}

/// Border radius tokens matching Mujeeb24 Design System
class AppRadius {
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 14.0;
  static const double xl = 16.0;
  static const double xxl = 20.0;
  static const double full = 999.0;

  // Responsive corner radii via flutter_screenutil
  static double get rSm { ensureScreenUtilInitialized(); return sm.r; }
  static double get rMd { ensureScreenUtilInitialized(); return md.r; }
  static double get rLg { ensureScreenUtilInitialized(); return lg.r; }
  static double get rXl { ensureScreenUtilInitialized(); return xl.r; }
  static double get rXxl { ensureScreenUtilInitialized(); return xxl.r; }
}

/// Elevation shadow tokens matching Mujeeb24 Design System
class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x060866D9),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x040866D9),
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x0D0866D9),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}

/// Animation & Motion tokens matching Phase 10 specifications
class AppMotion {
  static const Duration pressFeedback = Duration(milliseconds: 140);
  static const Duration shortTransition = Duration(milliseconds: 180);
  static const Duration pageTransition = Duration(milliseconds: 240);
  static const Duration listEntrance = Duration(milliseconds: 200);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve smooth = Curves.easeInOut;
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
        surface: AppColors.cardWhite,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.headingNavy,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.cardWhite,
          foregroundColor: AppColors.primary,
          elevation: 0,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardWhite,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondaryText,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
