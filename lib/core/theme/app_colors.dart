import 'package:flutter/material.dart';

/// Maternal Guardian Color Palette
/// Designed for calm, reassuring, and accessible user experience
class AppColors {
  AppColors._();

  // Primary Colors - Calming and Medical
  static const Color primary = Color(0xFF4CAF50); // Calming green for normal status
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primaryDark = Color(0xFF388E3C);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF2196F3); // Soft blue for information
  static const Color secondaryLight = Color(0xFF64B5F6);
  static const Color secondaryDark = Color(0xFF1976D2);
  
  // Status Colors - Carefully chosen to be informative but not alarming
  static const Color success = Color(0xFF4CAF50); // Same as primary for consistency
  static const Color warning = Color(0xFFFF9800); // Warm amber for caution
  static const Color error = Color(0xFFE57373); // Gentle red, less alarming than typical red
  static const Color critical = Color(0xFFF44336); // For true emergencies only
  
  // Neutral Colors - High contrast for accessibility
  static const Color textPrimary = Color(0xFF212121); // High contrast dark gray
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textInverse = Color(0xFFFFFFFF);
  
  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFFAFAFA);
  static const Color backgroundTertiary = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  
  // Status Ring Colors - Central element colors
  static const Color statusNormal = Color(0xFF4CAF50);
  static const Color statusGood = Color(0xFF8BC34A);
  static const Color statusCaution = Color(0xFFFF9800);
  static const Color statusWarning = Color(0xFFFF5722);
  static const Color statusCritical = Color(0xFFF44336);
  
  // Vital Signs Colors - Distinct but harmonious
  static const Color heartRate = Color(0xFFE91E63); // Pink for heart
  static const Color oxygenSaturation = Color(0xFF2196F3); // Blue for oxygen
  static const Color temperature = Color(0xFFFF9800); // Orange for temperature
  static const Color bloodPressure = Color(0xFF9C27B0); // Purple for BP
  static const Color glucose = Color(0xFF607D8B); // Blue-gray for glucose
  
  // Gradient Colors for depth and visual interest
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface, backgroundSecondary],
  );
  
  // Shadow Colors
  static const Color shadowLight = Color(0x0D000000); // 5% opacity
  static const Color shadowMedium = Color(0x1A000000); // 10% opacity
  static const Color shadowDark = Color(0x26000000); // 15% opacity
  
  // Accessibility helpers
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  /// Returns appropriate text color for given background
  static Color getTextColorForBackground(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? textInverse : textPrimary;
  }
  
  /// Status color based on health level (0-100)
  static Color getStatusColor(double healthLevel) {
    if (healthLevel >= 90) return statusNormal;
    if (healthLevel >= 75) return statusGood;
    if (healthLevel >= 60) return statusCaution;
    if (healthLevel >= 40) return statusWarning;
    return statusCritical;
  }
} 