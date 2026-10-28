// lib/core/theme/app_theme.dart
//
// MoolParakh design system.
// Palette: Deep Indigo (primary) + Saffron/Amber (accent) — reflects the
// Mool (root/trust) + Parakh (gold assay) brand metaphor.
//
// Trust-score colour semantics (used across the whole app):
//   Green  ≥ 80  → Excellent
//   Amber  50–79 → Watch
//   Red    < 50  → High Risk

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF3730A3); // Indigo-700
  static const primaryLight = Color(0xFF6366F1); // Indigo-500
  static const accent = Color(0xFFF59E0B); // Amber-500 (saffron)
  static const surface = Color(0xFFF8F9FE);
  static const surfaceCard = Color(0xFFFFFFFF);

  // Trust-score semantics
  static const trustExcellent = Color(0xFF16A34A); // Green-600
  static const trustWatch = Color(0xFFF59E0B); // Amber-500
  static const trustHighRisk = Color(0xFFDC2626); // Red-600

  // Status
  static const verified = Color(0xFF16A34A);
  static const pending = Color(0xFFF59E0B);
  static const failed = Color(0xFFDC2626);

  // Risk levels (match backend RiskLevel enum)
  static const riskLow = Color(0xFF16A34A);
  static const riskMedium = Color(0xFFF59E0B);
  static const riskHigh = Color(0xFFEA580C);
  static const riskCritical = Color(0xFFDC2626);

  // Neutral
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);
  static const shimmer = Color(0xFFE5E7EB);
  static const shimmerHighlight = Color(0xFFF9FAFB);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE0E7FF),
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFEF3C7),
      onSecondaryContainer: Color(0xFF92400E),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.failed,
      onError: Colors.white,
    );

    final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surface,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.failed),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.divider, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEEF2FF),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide.none,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Returns the right colour for a 0–100 trust score.
  static Color trustColor(int score) {
    if (score >= 80) return AppColors.trustExcellent;
    if (score >= 50) return AppColors.trustWatch;
    return AppColors.trustHighRisk;
  }

  /// Returns the right colour for a backend RiskLevel string.
  static Color riskColor(String level) {
    switch (level.toUpperCase()) {
      case 'LOW':
        return AppColors.riskLow;
      case 'MEDIUM':
        return AppColors.riskMedium;
      case 'HIGH':
        return AppColors.riskHigh;
      case 'CRITICAL':
        return AppColors.riskCritical;
      default:
        return AppColors.riskMedium;
    }
  }

  /// Returns the right colour for a backend VerificationStatus string.
  static Color verificationColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return AppColors.verified;
      case 'PENDING':
        return AppColors.pending;
      case 'FAILED':
        return AppColors.failed;
      default:
        return AppColors.pending;
    }
  }
}
