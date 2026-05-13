import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Color tokens ─────────────────────────────────────────────────────────────

class AppColors {
  // Brand
  static const brandBlue = Color(0xFF2563EB);
  static const brandBlueSoft = Color(0xFFEFF6FF);
  static const brandBlueDeep = Color(0xFF1D4ED8);
  static const brandBlueBorder = Color(0xFFDBEAFE);
  static const blueShadow = Color(0x592563EB); // rgba(37,99,235,0.35)

  // Macros
  static const calories = Color(0xFFEF4444);
  static const protein = Color(0xFF22C55E);
  static const carbs = Color(0xFF06B6D4);
  static const fat = Color(0xFFEAB308);

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF374151);
  static const textMuted = Color(0xFF9CA3AF);
  static const textHint = Color(0xFF6B7280);

  // Surfaces
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF9FAFB);
  static const surfaceTint = Color(0xFFF3F4F6);
  static const borderStrong = Color(0xFFE5E7EB);

  // Gradient stops (for LinearGradient)
  static const coralStart = Color(0xFFF97316);
  static const coralEnd = Color(0xFFF43F5E);
  static const violetStart = Color(0xFF8B5CF6);
  static const violetEnd = Color(0xFF6366F1);
  static const graphStart = Color(0xFF1F2937);
  static const graphEnd = Color(0xFF374151);
  static const cyanStart = Color(0xFF06B6D4);
  static const cyanEnd = Color(0xFF0284C7);
  static const avatarStart = Color(0xFF2563EB);
  static const avatarEnd = Color(0xFF7C3AED);

  // Semantic
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
}

// ── Gradients ─────────────────────────────────────────────────────────────────

class AppGradients {
  static const coral = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.coralStart, AppColors.coralEnd],
  );
  static const violet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.violetStart, AppColors.violetEnd],
  );
  static const graph = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.graphStart, AppColors.graphEnd],
  );
  static const cyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cyanStart, AppColors.cyanEnd],
  );
  static const avatar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.avatarStart, AppColors.avatarEnd],
  );
  static const calViolet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.violetStart, AppColors.violetEnd],
  );
  static const calCoral = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.coralStart, AppColors.coralEnd],
  );
  static const btnCoral = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.coralStart, AppColors.coralEnd],
  );
}

// ── Radii ─────────────────────────────────────────────────────────────────────

class AppRadius {
  static const double button = 16;
  static const double card = 14;
  static const double trainingCard = 18;
  static const double chip = 999;
  static const double appBarAction = 19;
  static const double chatBubble = 18;
  static const double bottomSheet = 28;
  static const double iconBg = 10;
  static const double setCircle = 22;
  static const double liveImg = 22;
}

// ── Typography ────────────────────────────────────────────────────────────────

class AppText {
  static TextStyle heroKcal({Color color = AppColors.textPrimary}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle appBarTitle({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: color,
      );

  static TextStyle sectionHead({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle cardTitle({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle bodyName({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle meta({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(fontSize: 11, color: color);

  static TextStyle meta12({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(fontSize: 12, color: color);

  static TextStyle labelCaps({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: color,
      ).copyWith(fontFeatures: [const FontFeature.enable('smcp')]);

  static TextStyle labelCaps11({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color,
      );

  static TextStyle counter({Color color = AppColors.textPrimary}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle monoNums({Color color = AppColors.textPrimary}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle mealKcal({Color color = AppColors.textPrimary}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle monoSmall({Color color = AppColors.textMuted}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle monoCount({Color color = AppColors.textMuted}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle btn({Color color = Colors.white}) =>
      GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle onboardingH1({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: color,
      );
}

// ── Theme ─────────────────────────────────────────────────────────────────────

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: GoogleFonts.inter().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppText.appBarTitle(),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderStrong,
      thickness: 0.5,
    ),
  );
}
