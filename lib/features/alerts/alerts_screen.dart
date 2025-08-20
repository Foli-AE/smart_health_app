import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/vital_signs.dart';
import '../../shared/models/alert.dart';
import '../../shared/models/health_recommendation.dart';
import '../../shared/services/firebase_data_service.dart';
import 'dart:async';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with TickerProviderStateMixin {
  final FirebaseDataService _firebaseDataService = FirebaseDataService();
  late TabController _tabController;
  bool _isLoading = false;

  // Real IoT data
  List<VitalSigns> _recentVitals = [];
  List<Alert> _alerts = [];
  List<HealthRecommendation> _recommendations = [];

  // Filter state
  bool _showOnlyUnread = false;
  AlertSeverity? _filterSeverity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load recent IoT data to generate alerts
      final recentData =
          await _firebaseDataService.getHistoricalIoTData(days: 1);
      print('📊 Alerts screen loaded ${recentData.length} recent IoT readings');

      if (mounted) {
        setState(() {
          _recentVitals = recentData;
          _alerts = _generateAlertsFromIoTData(recentData);
          _recommendations = _generateRecommendationsFromIoTData(recentData);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading alerts data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Alert> _generateAlertsFromIoTData(List<VitalSigns> vitals) {
    final alerts = <Alert>[];

    if (vitals.isEmpty) return alerts;

    // Get the latest reading
    final latest = vitals.last;
    final now = DateTime.now();

    // Check heart rate alerts
    if (latest.heartRate != null) {
      if (latest.heartRate! > 120) {
        alerts.add(Alert(
          id: 'hr_high_${now.millisecondsSinceEpoch}',
          title: 'High Heart Rate Alert',
          message:
              'Your heart rate is elevated (${latest.heartRate!.toInt()} BPM). Consider resting and monitoring.',
          type: AlertType.vitalSigns,
          severity: AlertSeverity.warning,
          timestamp: now,

        ));
      } else if (latest.heartRate! < 50) {
        alerts.add(Alert(
          id: 'hr_low_${now.millisecondsSinceEpoch}',
          title: 'Low Heart Rate Alert',
          message:
              'Your heart rate is below normal (${latest.heartRate!.toInt()} BPM). Contact your healthcare provider if this persists.',
          type: AlertType.vitalSigns,
          severity: AlertSeverity.warning,
          timestamp: now,

        ));
      }
    }

    // Check oxygen saturation alerts
    if (latest.oxygenSaturation != null) {
      if (latest.oxygenSaturation! < 95) {
        alerts.add(Alert(
          id: 'spo2_low_${now.millisecondsSinceEpoch}',
          title: 'Low Oxygen Saturation',
          message:
              'Your oxygen level is below normal (${latest.oxygenSaturation!.toInt()}%). Seek medical attention if breathing difficulties occur.',
          type: AlertType.vitalSigns,
          severity: AlertSeverity.critical,
          timestamp: now,

        ));
      }
    }

    // Check temperature alerts
    if (latest.temperature != null) {
      if (latest.temperature! > 37.5) {
        alerts.add(Alert(
          id: 'temp_high_${now.millisecondsSinceEpoch}',
          title: 'Elevated Temperature',
          message:
              'Your temperature is above normal (${latest.temperature!.toStringAsFixed(1)}°C). Monitor for other symptoms.',
          type: AlertType.vitalSigns,
          severity: AlertSeverity.warning,
          timestamp: now,

        ));
      }
    }

    // Check glucose alerts (if available)
    if (latest.glucose != null) {
      if (latest.glucose! > 140) {
        alerts.add(Alert(
          id: 'glucose_high_${now.millisecondsSinceEpoch}',
          title: 'High Glucose Level',
          message:
              'Your glucose level is elevated (${latest.glucose!.toInt()} mg/dL). Consider dietary adjustments.',
          type: AlertType.vitalSigns,
          severity: AlertSeverity.warning,
          timestamp: now,

        ));
      } else if (latest.glucose! < 70) {
        alerts.add(Alert(
          id: 'glucose_low_${now.millisecondsSinceEpoch}',
          title: 'Low Glucose Level',
          message:
              'Your glucose level is below normal (${latest.glucose!.toInt()} mg/dL). Consider having a snack.',
          type: AlertType.vitalSigns,
          severity: AlertSeverity.warning,
          timestamp: now,

        ));
      }
    }

    // Add trend-based alerts if we have multiple readings
    if (vitals.length >= 2) {
      final previous = vitals[vitals.length - 2];

      // Check for rapid changes
      if (latest.heartRate != null && previous.heartRate != null) {
        final change = (latest.heartRate! - previous.heartRate!).abs();
        if (change > 20) {
          alerts.add(Alert(
            id: 'hr_change_${now.millisecondsSinceEpoch}',
            title: 'Rapid Heart Rate Change',
            message:
                'Your heart rate changed by ${change.toInt()} BPM in a short time. This may indicate stress or activity.',
            type: AlertType.vitalSigns,
            severity: AlertSeverity.info,
            timestamp: now,

          ));
        }
      }
    }

    // Add general health status alert
    if (alerts.isEmpty) {
      alerts.add(Alert(
        id: 'status_good_${now.millisecondsSinceEpoch}',
        title: 'All Vitals Normal',
        message:
            'Your vital signs are within healthy ranges. Keep up the good work!',
        type: AlertType.achievement,
        severity: AlertSeverity.info,
        timestamp: now,

      ));
    }

    return alerts;
  }

  List<HealthRecommendation> _generateRecommendationsFromIoTData(
      List<VitalSigns> vitals) {
    final recommendations = <HealthRecommendation>[];

    if (vitals.isEmpty) return recommendations;

    final latest = vitals.last;
    final now = DateTime.now();

    // Heart rate recommendations
    if (latest.heartRate != null) {
      if (latest.heartRate! > 100) {
        recommendations.add(HealthRecommendation(
          id: 'hr_rest_${now.millisecondsSinceEpoch}',
          title: 'Rest and Relaxation',
          description:
              'Your heart rate is elevated. Take deep breaths, rest, and avoid strenuous activities.',
          type: RecommendationType.rest,
          priority: RecommendationPriority.medium,
          createdAt: now,
        ));
      } else if (latest.heartRate! < 60) {
        recommendations.add(HealthRecommendation(
          id: 'hr_activity_${now.millisecondsSinceEpoch}',
          title: 'Gentle Activity',
          description:
              'Your heart rate is on the lower side. Consider light walking or gentle exercises.',
          type: RecommendationType.exercise,
          priority: RecommendationPriority.low,
          createdAt: now,
        ));
      }
    }

    // Oxygen saturation recommendations
    if (latest.oxygenSaturation != null && latest.oxygenSaturation! < 98) {
      recommendations.add(HealthRecommendation(
        id: 'spo2_breathing_${now.millisecondsSinceEpoch}',
        title: 'Deep Breathing Exercise',
        description:
            'Practice deep breathing exercises to improve oxygen levels. Sit upright and take slow, deep breaths.',
        type: RecommendationType.mindfulness,
        priority: RecommendationPriority.medium,
        createdAt: now,
      ));
    }

    // Temperature recommendations
    if (latest.temperature != null && latest.temperature! > 37.0) {
      recommendations.add(HealthRecommendation(
        id: 'temp_hydration_${now.millisecondsSinceEpoch}',
        title: 'Stay Hydrated',
        description:
            'Your temperature is slightly elevated. Drink plenty of water and rest in a cool environment.',
        type: RecommendationType.hydration,
        priority: RecommendationPriority.medium,
        createdAt: now,
      ));
    }

    // General pregnancy recommendations
    recommendations.add(HealthRecommendation(
      id: 'prenatal_${now.millisecondsSinceEpoch}',
      title: 'Regular Prenatal Check-ups',
      description:
          'Continue with your scheduled prenatal appointments to monitor your health and your baby\'s development.',
      type: RecommendationType.appointment,
      priority: RecommendationPriority.high,
      createdAt: now,
    ));

    recommendations.add(HealthRecommendation(
      id: 'nutrition_${now.millisecondsSinceEpoch}',
      title: 'Balanced Nutrition',
      description:
          'Maintain a balanced diet rich in fruits, vegetables, lean proteins, and whole grains.',
      type: RecommendationType.nutrition,
      priority: RecommendationPriority.medium,
      createdAt: now,
    ));

    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Alerts & Notifications',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.sliders(), color: AppColors.primary),
            onPressed: () => _showFilterOptions(),
          ),
          IconButton(
            icon: Icon(PhosphorIcons.phone(), color: AppColors.critical),
            onPressed: () => _navigateToCallDoctor(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active, size: 16),
                  const SizedBox(width: 4),
                  const Text('Alerts'),
                  if (_getUnreadCount() > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.critical,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _getUnreadCount().toString(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textInverse,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Recommendations'),
            const Tab(text: 'Settings'),
          ],
          labelStyle:
              AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.labelMedium,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAlertsTab(),
                _buildRecommendationsTab(),
                _buildSettingsTab(),
              ],
            ),
      floatingActionButton: _buildQuickAccessFAB(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Loading alerts...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    final filteredAlerts = _getFilteredAlerts();

    if (filteredAlerts.isEmpty) {
      return _buildEmptyAlertsState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primary,
      child: Column(
        children: [
          // Summary Cards
          _buildAlertsSummary(),

          // Alerts List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              itemCount: filteredAlerts.length,
              itemBuilder: (context, index) {
                final alert = filteredAlerts[index];
                return _buildAlertCard(alert);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    final activeRecommendations =
        _recommendations.where((r) => r.isActive).toList();

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primary,
      child: activeRecommendations.isEmpty
          ? _buildEmptyRecommendationsState()
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              itemCount: activeRecommendations.length,
              itemBuilder: (context, index) {
                final recommendation = activeRecommendations[index];
                return _buildRecommendationCard(recommendation);
              },
            ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Preferences
          _buildNotificationPreferences(),

          const SizedBox(height: AppTheme.spacingL),

          // Emergency Settings
          _buildEmergencySettings(),

          const SizedBox(height: AppTheme.spacingL),

          // Alert Thresholds
          _buildAlertThresholds(),
        ],
      ),
    );
  }

  Widget _buildAlertsSummary() {
    final criticalCount =
        _alerts.where((a) => a.severity == AlertSeverity.critical).length;
    final warningCount =
        _alerts.where((a) => a.severity == AlertSeverity.warning).length;
    final unreadCount = _alerts.where((a) => !a.isRead).length;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Critical',
              criticalCount.toString(),
              AppColors.critical,
              Icons.warning,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: _buildSummaryCard(
              'Warnings',
              warningCount.toString(),
              AppColors.warning,
              Icons.info,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: _buildSummaryCard(
              'Unread',
              unreadCount.toString(),
              AppColors.primary,
              Icons.mark_email_unread,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppTheme.mediumRadius,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            count,
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Card(
        elevation: alert.isRead ? 1 : 3,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.mediumRadius,
          side: BorderSide(
            color: alert.severity.color
                .withValues(alpha: alert.isRead ? 0.2 : 0.5),
            width: alert.isRead ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: () => _markAsRead(alert),
          borderRadius: AppTheme.mediumRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: alert.severity.color.withValues(alpha: 0.1),
                        borderRadius: AppTheme.smallRadius,
                      ),
                      child: Icon(
                        alert.type.icon,
                        color: alert.severity.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  alert.title,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: alert.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!alert.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: alert.severity.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            _formatDateTime(alert.timestamp),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingS),

                // Message
                Text(
                  alert.message,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                // Action Button
                if (alert.actionText != null) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _handleAlertAction(alert),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alert.severity.color,
                        foregroundColor: AppColors.textInverse,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                      ),
                      child: Text(alert.actionText!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(HealthRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Card(
        elevation: 2,
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.mediumRadius,
        ),
        child: InkWell(
          onTap: () => _showRecommendationDetails(recommendation),
          borderRadius: AppTheme.mediumRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: recommendation.type.color.withValues(alpha: 0.1),
                        borderRadius: AppTheme.smallRadius,
                      ),
                      child: Icon(
                        recommendation.type.icon,
                        color: recommendation.type.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.title,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: recommendation.priority.color
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  recommendation.priority.displayName,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: recommendation.priority.color,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                recommendation.type.displayName,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingS),

                // Description
                Text(
                  recommendation.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                // Action Button
                if (recommendation.actionText != null) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () =>
                          _handleRecommendationAction(recommendation),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: recommendation.type.color,
                        side: BorderSide(color: recommendation.type.color),
                      ),
                      child: Text(recommendation.actionText!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationPreferences() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.largeRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Preferences',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildToggleOption(
            'Push Notifications',
            'Receive notifications on your device',
            true,
            (value) {},
          ),
          _buildToggleOption(
            'Sound Alerts',
            'Play sound for critical alerts',
            true,
            (value) {},
          ),
          _buildToggleOption(
            'Email Notifications',
            'Send alerts to your email',
            false,
            (value) {},
          ),
          _buildToggleOption(
            'SMS Alerts',
            'Send critical alerts via SMS',
            true,
            (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySettings() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.largeRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Settings',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildActionOption(
            'Emergency Contacts',
            'Manage who gets notified in emergencies',
            Icons.contacts,
            () => _navigateToCallDoctor(),
          ),
          _buildActionOption(
            'Auto-Call Emergency Services',
            'Automatically call 999 for critical alerts',
            Icons.emergency,
            () => _showAutoCallSettings(),
          ),
          _buildActionOption(
            'Location Sharing',
            'Share location during emergencies',
            Icons.location_on,
            () => _showLocationSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertThresholds() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.largeRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert Thresholds',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildThresholdOption(
            'Heart Rate',
            'High: >110 bpm, Low: <60 bpm',
            AppColors.heartRate,
          ),
          _buildThresholdOption(
            'Glucose',
            'High: >140/90 mmHg, Low: <90/60 mmHg',
            AppColors.glucose,
          ),
          _buildThresholdOption(
            'Oxygen Saturation',
            'Low: <95%',
            AppColors.oxygenSaturation,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionOption(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.mediumRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdOption(String title, String values, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  values,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            color: AppColors.textTertiary,
            onPressed: () => _editThreshold(title),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAlertsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.bell(),
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'All Clear!',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'No alerts at this time. Your health monitoring is working smoothly.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendationsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.lightbulb(),
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No Recommendations',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'You\'re doing great! Check back later for personalized health tips.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessFAB() {
    return FloatingActionButton(
      onPressed: () => _navigateToCallDoctor(),
      backgroundColor: AppColors.critical,
      foregroundColor: AppColors.textInverse,
      child: Icon(PhosphorIcons.phone()),
    );
  }

  // Helper methods
  List<Alert> _getFilteredAlerts() {
    var filtered = _alerts.where((alert) {
      if (_showOnlyUnread && alert.isRead) return false;
      if (_filterSeverity != null && alert.severity != _filterSeverity)
        return false;
      return true;
    }).toList();

    // Sort by timestamp (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  int _getUnreadCount() {
    return _alerts.where((a) => !a.isRead).length;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  void _markAsRead(Alert alert) {
    setState(() {
      final index = _alerts.indexOf(alert);
      if (index != -1) {
        _alerts[index] = alert.copyWith(isRead: true);
      }
    });
  }

  void _handleAlertAction(Alert alert) {
    switch (alert.type) {
      case AlertType.emergency:
        _navigateToCallDoctor();
        break;
      case AlertType.vitalSigns:
        // Navigate to dashboard or vital details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening vital signs details...'),
            backgroundColor: AppColors.primary,
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alert action: ${alert.actionText}'),
            backgroundColor: AppColors.primary,
          ),
        );
    }
  }

  void _handleRecommendationAction(HealthRecommendation recommendation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recommendation action: ${recommendation.actionText}'),
        backgroundColor: recommendation.type.color,
      ),
    );
  }

  void _showRecommendationDetails(HealthRecommendation recommendation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(AppTheme.spacingM),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppTheme.largeRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: recommendation.type.color.withValues(alpha: 0.1),
                    borderRadius: AppTheme.mediumRadius,
                  ),
                  child: Icon(
                    recommendation.type.icon,
                    color: recommendation.type.color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.title,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        recommendation.type.displayName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Description
            Text(
              recommendation.description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Action Button
            if (recommendation.actionText != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleRecommendationAction(recommendation);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: recommendation.type.color,
                  ),
                  child: Text(recommendation.actionText!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Alerts',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Unread filter
            CheckboxListTile(
              title: const Text('Show only unread'),
              value: _showOnlyUnread,
              onChanged: (value) {
                setState(() => _showOnlyUnread = value ?? false);
                Navigator.pop(context);
              },
            ),

            // Severity filter
            Text(
              'Filter by Severity',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            ...AlertSeverity.values
                .map((severity) => RadioListTile<AlertSeverity?>(
                      title: Text(severity.displayName),
                      value: severity,
                      groupValue: _filterSeverity,
                      onChanged: (value) {
                        setState(() => _filterSeverity = value);
                        Navigator.pop(context);
                      },
                    )),
            RadioListTile<AlertSeverity?>(
              title: const Text('All Severities'),
              value: null,
              groupValue: _filterSeverity,
              onChanged: (value) {
                setState(() => _filterSeverity = null);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCallDoctor() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency call feature - Coming soon'),
        backgroundColor: AppColors.critical,
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _showAutoCallSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Auto-call settings - Coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showLocationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location sharing settings - Coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _editThreshold(String vitalType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit $vitalType thresholds - Coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
