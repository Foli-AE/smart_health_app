import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Maternal Guardian Typography System
/// Designed for accessibility and low-literacy users
class AppTypography {
  AppTypography._();

  // Base font families
  static const String primaryFontFamily = 'NunitoSans';
  static const String secondaryFontFamily = 'SourceSansPro';

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Display styles - Large, prominent text
  static final TextStyle displayLarge = GoogleFonts.nunitoSans(
    fontSize: 40,
    fontWeight: bold,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static final TextStyle displayMedium = GoogleFonts.nunitoSans(
    fontSize: 32,
    fontWeight: bold,
    letterSpacing: -0.25,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static final TextStyle displaySmall = GoogleFonts.nunitoSans(
    fontSize: 28,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // Headline styles - For section headers
  static final TextStyle headlineLarge = GoogleFonts.nunitoSans(
    fontSize: 26,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static final TextStyle headlineMedium = GoogleFonts.nunitoSans(
    fontSize: 22,
    fontWeight: semiBold,
    letterSpacing: 0.15,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static final TextStyle headlineSmall = GoogleFonts.nunitoSans(
    fontSize: 20,
    fontWeight: medium,
    letterSpacing: 0.15,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // Title styles - For card headers and important content
  static final TextStyle titleLarge = GoogleFonts.sourceSans3(
    fontSize: 18,
    fontWeight: semiBold,
    letterSpacing: 0.15,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static final TextStyle titleMedium = GoogleFonts.sourceSans3(
    fontSize: 16,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static final TextStyle titleSmall = GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // Body styles - For general content
  static final TextStyle bodyLarge = GoogleFonts.sourceSans3(
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyMedium = GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.25,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodySmall = GoogleFonts.sourceSans3(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // Label styles - For buttons and small UI elements
  static final TextStyle labelLarge = GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static final TextStyle labelMedium = GoogleFonts.sourceSans3(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static final TextStyle labelSmall = GoogleFonts.sourceSans3(
    fontSize: 10,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // Special styles for vital signs and health data
  static final TextStyle vitalSignValue = GoogleFonts.nunitoSans(
    fontSize: 24,
    fontWeight: bold,
    letterSpacing: -0.5,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static final TextStyle vitalSignUnit = GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static final TextStyle vitalSignLabel = GoogleFonts.sourceSans3(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  // Status text styles
  static final TextStyle statusNormal = GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: semiBold,
    letterSpacing: 0.25,
    height: 1.4,
    color: AppColors.success,
  );

  static final TextStyle statusWarning = GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: semiBold,
    letterSpacing: 0.25,
    height: 1.4,
    color: AppColors.warning,
  );

  static final TextStyle statusCritical = GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: semiBold,
    letterSpacing: 0.25,
    height: 1.4,
    color: AppColors.critical,
  );

  // Button text styles
  static final TextStyle buttonLarge = GoogleFonts.sourceSans3(
    fontSize: 16,
    fontWeight: semiBold,
    letterSpacing: 0.5,
    height: 1.25,
    color: AppColors.textInverse,
  );

  static final TextStyle buttonMedium = GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: semiBold,
    letterSpacing: 0.25,
    height: 1.25,
    color: AppColors.textInverse,
  );

  // Helper methods
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Creates a text theme for the app
  static TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
} 