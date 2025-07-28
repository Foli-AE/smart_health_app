import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';

/// Individual vital sign card with beautiful design
class VitalSignCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final VitalSignStatus status;
  final String? trend; // "up", "down", "stable"
  final VoidCallback? onTap;

  const VitalSignCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.status,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: AppTheme.largeRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.largeRadius,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            borderRadius: AppTheme.largeRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                color.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and trend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon with colored background
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: AppTheme.smallRadius,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  
                  // Trend indicator
                  if (trend != null) _buildTrendIndicator(),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingM),
              
              // Value
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: AppTypography.vitalSignValue.copyWith(
                      color: color,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    unit,
                    style: AppTypography.vitalSignUnit,
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingS),
              
              // Label and status
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      label,
                      style: AppTypography.vitalSignLabel,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: _buildStatusIndicator(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().slideX(
      begin: 0.3,
      duration: AppTheme.mediumAnimation,
      curve: AppTheme.emphasizedCurve,
    ).fadeIn(
      duration: AppTheme.longAnimation,
    );
  }

  Widget _buildTrendIndicator() {
    IconData trendIcon;
    Color trendColor;

    switch (trend) {
      case 'up':
        trendIcon = PhosphorIcons.trendUp();
        trendColor = AppColors.success;
        break;
      case 'down':
        trendIcon = PhosphorIcons.trendDown();
        trendColor = AppColors.error;
        break;
      case 'stable':
      default:
        trendIcon = PhosphorIcons.minus();
        trendColor = AppColors.textTertiary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        trendIcon,
        size: 16,
        color: trendColor,
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.displayName,
        style: AppTypography.labelSmall.copyWith(
          color: status.color,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Compact vital sign widget for smaller spaces
class CompactVitalSign extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final VitalSignStatus status;

  const CompactVitalSign({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
        borderRadius: AppTheme.smallRadius,
        border: Border.all(
                        color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      value,
                      style: AppTypography.titleMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      unit,
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vital sign status levels
enum VitalSignStatus {
  optimal,
  normal,
  warning,
  critical,
  unknown,
}

extension VitalSignStatusExtension on VitalSignStatus {
  Color get color {
    switch (this) {
      case VitalSignStatus.optimal:
        return AppColors.success;
      case VitalSignStatus.normal:
        return AppColors.primary;
      case VitalSignStatus.warning:
        return AppColors.warning;
      case VitalSignStatus.critical:
        return AppColors.critical;
      case VitalSignStatus.unknown:
        return AppColors.textTertiary;
    }
  }

  String get displayName {
    switch (this) {
      case VitalSignStatus.optimal:
        return 'Optimal';
      case VitalSignStatus.normal:
        return 'Normal';
      case VitalSignStatus.warning:
        return 'Caution';
      case VitalSignStatus.critical:
        return 'Critical';
      case VitalSignStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Predefined vital sign configurations
class VitalSignConfigs {
  static VitalSignCard heartRate({
    required double value,
    String? trend,
    VoidCallback? onTap,
  }) {
    VitalSignStatus status;
    if (value >= 60 && value <= 100) {
      status = VitalSignStatus.optimal;
    } else if (value >= 50 && value <= 120) {
      status = VitalSignStatus.normal;
    } else if (value >= 40 && value <= 140) {
      status = VitalSignStatus.warning;
    } else {
      status = VitalSignStatus.critical;
    }

    return VitalSignCard(
      label: 'Heart Rate',
      value: value.toInt().toString(),
      unit: 'BPM',
      icon: PhosphorIcons.heart(),
      color: AppColors.heartRate,
      status: status,
      trend: trend,
      onTap: onTap,
    );
  }

  static VitalSignCard oxygenSaturation({
    required double value,
    String? trend,
    VoidCallback? onTap,
  }) {
    VitalSignStatus status;
    if (value >= 95) {
      status = VitalSignStatus.optimal;
    } else if (value >= 90) {
      status = VitalSignStatus.normal;
    } else if (value >= 85) {
      status = VitalSignStatus.warning;
    } else {
      status = VitalSignStatus.critical;
    }

    return VitalSignCard(
      label: 'Oxygen Saturation',
      value: value.toInt().toString(),
      unit: '%',
      icon: PhosphorIcons.drop(),
      color: AppColors.oxygenSaturation,
      status: status,
      trend: trend,
      onTap: onTap,
    );
  }

  static VitalSignCard temperature({
    required double value,
    String? trend,
    VoidCallback? onTap,
  }) {
    VitalSignStatus status;
    if (value >= 36.1 && value <= 37.2) {
      status = VitalSignStatus.optimal;
    } else if (value >= 35.5 && value <= 37.8) {
      status = VitalSignStatus.normal;
    } else if (value >= 35.0 && value <= 38.5) {
      status = VitalSignStatus.warning;
    } else {
      status = VitalSignStatus.critical;
    }

    return VitalSignCard(
      label: 'Temperature',
      value: value.toStringAsFixed(1),
      unit: '°C',
      icon: PhosphorIcons.thermometer(),
      color: AppColors.temperature,
      status: status,
      trend: trend,
      onTap: onTap,
    );
  }

  static VitalSignCard bloodPressure({
    required double systolic,
    required double diastolic,
    String? trend,
    VoidCallback? onTap,
  }) {
    VitalSignStatus status;
    if (systolic >= 90 && systolic <= 120 && diastolic >= 60 && diastolic <= 80) {
      status = VitalSignStatus.optimal;
    } else if (systolic >= 80 && systolic <= 140 && diastolic >= 50 && diastolic <= 90) {
      status = VitalSignStatus.normal;
    } else if (systolic >= 70 && systolic <= 160 && diastolic >= 40 && diastolic <= 100) {
      status = VitalSignStatus.warning;
    } else {
      status = VitalSignStatus.critical;
    }

    return VitalSignCard(
      label: 'Blood Pressure',
      value: '${systolic.toInt()}/${diastolic.toInt()}',
      unit: 'mmHg',
      icon: PhosphorIcons.heartbeat(),
      color: AppColors.bloodPressure,
      status: status,
      trend: trend,
      onTap: onTap,
    );
  }

  static VitalSignCard glucose({
    required double value,
    String? trend,
    VoidCallback? onTap,
  }) {
    VitalSignStatus status;
    if (value >= 70 && value <= 140) {
      status = VitalSignStatus.optimal;
    } else if (value >= 60 && value <= 180) {
      status = VitalSignStatus.normal;
    } else if (value >= 50 && value <= 200) {
      status = VitalSignStatus.warning;
    } else {
      status = VitalSignStatus.critical;
    }

    return VitalSignCard(
      label: 'Blood Glucose',
      value: value.toInt().toString(),
      unit: 'mg/dL',
      icon: PhosphorIcons.testTube(),
      color: AppColors.glucose,
      status: status,
      trend: trend,
      onTap: onTap,
    );
  }
} 