import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/pregnancy_timeline.dart';
import '../../shared/models/health_recommendation.dart';
import '../contacts/call_doctor_screen.dart';
import '../testing/firebase_test_screen.dart';
import '../testing/ble_test_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final MockDataService _mockDataService = MockDataService();
  PregnancyTimeline? _pregnancyTimeline;
  List<HealthRecommendation> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    _pregnancyTimeline = _mockDataService.generatePregnancyTimeline();
    _recommendations = _mockDataService.generateHealthRecommendations();
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
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
            icon: Icon(PhosphorIcons.gear(), color: AppColors.primary),
            onPressed: () => _tabController.animateTo(3),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Pregnancy'),
            Tab(text: 'Health'),
            Tab(text: 'Settings'),
          ],
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.labelMedium,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
        ),
      ),
      body: _isLoading 
          ? _buildLoadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildPregnancyTab(),
                _buildHealthTab(),
                _buildSettingsTab(),
              ],
            ),
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
            'Loading profile...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Quick Actions
            _buildQuickActions(),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Personal Information
            _buildPersonalInformation(),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Medical Information
            _buildMedicalInformation(),
            
            // Add bottom padding for scroll
            const SizedBox(height: AppTheme.spacingXxl),
          ],
        ),
      ),
    );
  }

  Widget _buildPregnancyTab() {
    if (_pregnancyTimeline == null) {
      return const Center(child: Text('Loading pregnancy data...'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Week Card
          _buildCurrentWeekCard(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Progress Timeline
          _buildProgressTimeline(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Milestones
          _buildMilestones(),
          
          const SizedBox(height: AppTheme.spacingXxl),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Summary
          _buildHealthSummary(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Active Recommendations
          _buildActiveRecommendations(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Emergency Contacts Quick Access
          _buildEmergencyQuickAccess(),
          
          const SizedBox(height: AppTheme.spacingXxl),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Firebase Test Section (Development)
          _buildFirebaseTestSection(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // App Preferences
          _buildAppPreferences(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Notification Settings
          _buildNotificationSettings(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Privacy & Security
          _buildPrivacySettings(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Device & Data
          _buildDeviceSettings(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Support & About
          _buildSupportSettings(),
          
          const SizedBox(height: AppTheme.spacingXxl),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.largeRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surface,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Name and Title
          Text(
            'Foli Ezekiel',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Expecting Mother',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Pregnancy Status
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.heartRate.withValues(alpha: 0.1),
              borderRadius: AppTheme.mediumRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pregnant_woman,
                  color: AppColors.heartRate,
                  size: 16,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Week ${_pregnancyTimeline?.currentWeek ?? 28} • Due in ${_pregnancyTimeline?.daysUntilDue ?? 84} days',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.heartRate,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
            'Quick Actions',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Call Doctor',
                  PhosphorIcons.phone(),
                  AppColors.critical,
                  () => _navigateToCallDoctor(),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildQuickActionButton(
                  'Appointments',
                  PhosphorIcons.calendar(),
                  AppColors.primary,
                  () => _showAppointments(),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildQuickActionButton(
                  'Share Data',
                  PhosphorIcons.shareNetwork(),
                  AppColors.secondary,
                  () => _shareHealthData(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.mediumRadius,
      child: Container(
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
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInformation() {
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
            'Personal Information',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          _buildInfoRow('Full Name', 'Amina Mensah', Icons.person),
          _buildInfoRow('Date of Birth', 'March 15, 1995', Icons.cake),
          _buildInfoRow('Phone', '+233 24 123 4567', Icons.phone),
          _buildInfoRow('Email', 'amina.mensah@email.com', Icons.email),
          _buildInfoRow('Address', 'Accra, Ghana', Icons.location_on),
          _buildInfoRow('Emergency Contact', 'Kwame Mensah (Husband)', Icons.emergency),
        ],
      ),
    );
  }

  Widget _buildMedicalInformation() {
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
            'Medical Information',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          _buildInfoRow('Blood Type', 'O+', Icons.bloodtype),
          _buildInfoRow('Height', '165 cm', Icons.height),
          _buildInfoRow('Pre-pregnancy Weight', '65 kg', Icons.monitor_weight),
          _buildInfoRow('Current Weight', '72 kg', Icons.monitor_weight),
          _buildInfoRow('Primary Doctor', 'Dr. Akosua Mensah', Icons.medical_services),
          _buildInfoRow('Allergies', 'None known', Icons.warning),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            color: AppColors.textTertiary,
            onPressed: () => _editInfo(label),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeekCard() {
    if (_pregnancyTimeline == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _pregnancyTimeline!.currentTrimester.color.withValues(alpha: 0.1),
            _pregnancyTimeline!.currentTrimester.color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.largeRadius,
        border: Border.all(
          color: _pregnancyTimeline!.currentTrimester.color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: _pregnancyTimeline!.currentTrimester.color.withValues(alpha: 0.2),
                  borderRadius: AppTheme.smallRadius,
                ),
                child: Icon(
                  Icons.pregnant_woman,
                  color: _pregnancyTimeline!.currentTrimester.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week ${_pregnancyTimeline!.currentWeek}',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _pregnancyTimeline!.currentTrimester.color,
                      ),
                    ),
                    Text(
                      _pregnancyTimeline!.currentTrimester.displayName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Baby Size
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.8),
              borderRadius: AppTheme.mediumRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Baby This Week',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  children: [
                    const Icon(
                      Icons.child_care,
                      color: AppColors.heartRate,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      '${_pregnancyTimeline!.babySizeComparison} (${_pregnancyTimeline!.estimatedBabyWeight.toInt()}g)',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pregnancy Progress',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(_pregnancyTimeline!.pregnancyProgress * 100).toInt()}%',
                    style: AppTypography.labelMedium.copyWith(
                      color: _pregnancyTimeline!.currentTrimester.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              LinearProgressIndicator(
                value: _pregnancyTimeline!.pregnancyProgress,
                backgroundColor: AppColors.border.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _pregnancyTimeline!.currentTrimester.color,
                ),
                minHeight: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline() {
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
            'Trimester Progress',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          ...PregnancyTrimester.values.map((trimester) {
            final isCurrent = _pregnancyTimeline?.currentTrimester == trimester;
            final isPast = _pregnancyTimeline != null && 
                          trimester.weekRange.end < _pregnancyTimeline!.currentWeek;
            
            return _buildTrimesterRow(trimester, isCurrent, isPast);
          }),
        ],
      ),
    );
  }

  Widget _buildTrimesterRow(PregnancyTrimester trimester, bool isCurrent, bool isPast) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isCurrent 
            ? trimester.color.withValues(alpha: 0.1)
            : isPast 
                ? AppColors.success.withValues(alpha: 0.05)
                : AppColors.backgroundSecondary,
        borderRadius: AppTheme.mediumRadius,
        border: Border.all(
          color: isCurrent 
              ? trimester.color.withValues(alpha: 0.5)
              : isPast 
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrent 
                  ? trimester.color 
                  : isPast 
                      ? AppColors.success 
                      : AppColors.textTertiary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPast 
                  ? Icons.check 
                  : isCurrent 
                      ? Icons.circle 
                      : Icons.circle_outlined,
              color: AppColors.textInverse,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trimester.displayName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? trimester.color : null,
                  ),
                ),
                Text(
                  'Weeks ${trimester.weekRange.start}-${trimester.weekRange.end}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  trimester.description,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones() {
    if (_pregnancyTimeline == null) return const SizedBox.shrink();
    
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
            'Pregnancy Milestones',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          ..._pregnancyTimeline!.milestones.take(5).map((milestone) {
            return _buildMilestoneCard(milestone);
          }),
          
          if (_pregnancyTimeline!.milestones.length > 5)
            TextButton(
              onPressed: () => _showAllMilestones(),
              child: const Text('View All Milestones'),
            ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(PregnancyMilestone milestone) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: milestone.isCompleted 
            ? AppColors.success.withValues(alpha: 0.05)
            : milestone.type.color.withValues(alpha: 0.05),
        borderRadius: AppTheme.mediumRadius,
        border: Border.all(
          color: milestone.isCompleted 
              ? AppColors.success.withValues(alpha: 0.3)
              : milestone.type.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: milestone.isCompleted 
                  ? AppColors.success.withValues(alpha: 0.1)
                  : milestone.type.color.withValues(alpha: 0.1),
              borderRadius: AppTheme.smallRadius,
            ),
            child: Icon(
              milestone.isCompleted 
                  ? Icons.check_circle 
                  : milestone.type.icon,
              color: milestone.isCompleted 
                  ? AppColors.success 
                  : milestone.type.color,
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
                    Text(
                      'Week ${milestone.week}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (milestone.isCompleted) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified,
                        size: 12,
                        color: AppColors.success,
                      ),
                    ],
                  ],
                ),
                Text(
                  milestone.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  milestone.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSummary() {
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
            'Health Summary',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          Row(
            children: [
              Expanded(
                child: _buildHealthMetric(
                  'Overall Health',
                  'Excellent',
                  AppColors.success,
                  Icons.favorite,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildHealthMetric(
                  'Last Check-up',
                  '3 days ago',
                  AppColors.primary,
                  Icons.event,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingS),
          
          Row(
            children: [
              Expanded(
                child: _buildHealthMetric(
                  'Active Alerts',
                  '2',
                  AppColors.warning,
                  Icons.notifications,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildHealthMetric(
                  'Data Points',
                  '1,247',
                  AppColors.secondary,
                  Icons.analytics,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppTheme.mediumRadius,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRecommendations() {
    final activeRecs = _recommendations.where((r) => r.isActive).take(3).toList();
    
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Recommendations',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _showAllRecommendations(),
                child: const Text('View All'),
              ),
            ],
          ),
          
          if (activeRecs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Text(
                  'No active recommendations. You\'re doing great!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...activeRecs.map((rec) => _buildRecommendationItem(rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(HealthRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: recommendation.type.color.withValues(alpha: 0.05),
        borderRadius: AppTheme.mediumRadius,
        border: Border.all(
          color: recommendation.type.color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            recommendation.type.icon,
            color: recommendation.type.color,
            size: 20,
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
                Text(
                  recommendation.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildEmergencyQuickAccess() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.critical.withValues(alpha: 0.05),
        borderRadius: AppTheme.largeRadius,
        border: Border.all(
          color: AppColors.critical.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emergency,
                color: AppColors.critical,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                'Emergency Access',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.critical,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToCallDoctor(),
                  icon: Icon(PhosphorIcons.phone()),
                  label: const Text('Call Doctor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.critical,
                    foregroundColor: AppColors.textInverse,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callEmergencyServices(),
                  icon: const Icon(Icons.local_hospital),
                  label: const Text('Emergency'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.critical,
                    side: const BorderSide(color: AppColors.critical),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferences() {
    return _buildSettingsSection(
      'App Preferences',
      [
        _buildToggleSetting(
          'Dark Mode',
          'Use dark theme throughout the app',
          false,
          (value) {},
        ),
        _buildToggleSetting(
          'Haptic Feedback',
          'Vibration for button presses and alerts',
          true,
          (value) {},
        ),
        _buildActionSetting(
          'Language',
          'English',
          Icons.language,
          () => _showLanguageOptions(),
        ),
        _buildActionSetting(
          'Units',
          'Metric (kg, cm, °C)',
          Icons.straighten,
          () => _showUnitOptions(),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsSection(
      'Notifications',
      [
        _buildToggleSetting(
          'Push Notifications',
          'Receive health alerts and reminders',
          true,
          (value) {},
        ),
        _buildToggleSetting(
          'Sound Alerts',
          'Play sound for critical notifications',
          true,
          (value) {},
        ),
        _buildToggleSetting(
          'Vibration',
          'Vibrate for important alerts',
          true,
          (value) {},
        ),
        _buildActionSetting(
          'Quiet Hours',
          '10:00 PM - 7:00 AM',
          Icons.bedtime,
          () => _showQuietHours(),
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return _buildSettingsSection(
      'Privacy & Security',
      [
        _buildToggleSetting(
          'Data Sharing',
          'Share anonymized data for research',
          false,
          (value) {},
        ),
        _buildToggleSetting(
          'Location Services',
          'Allow location access for emergencies',
          true,
          (value) {},
        ),
        _buildActionSetting(
          'Data Export',
          'Download your health data',
          Icons.download,
          () => _exportData(),
        ),
        _buildActionSetting(
          'Privacy Policy',
          'Review our privacy practices',
          Icons.policy,
          () => _showPrivacyPolicy(),
        ),
      ],
    );
  }

  Widget _buildDeviceSettings() {
    return _buildSettingsSection(
      'Device & Data',
      [
        _buildActionSetting(
          'Connected Device',
          'Health Monitor Pro - Connected',
          Icons.bluetooth_connected,
          () => _showDeviceSettings(),
        ),
        _buildActionSetting(
          'Sync Settings',
          'Auto-sync when connected',
          Icons.sync,
          () => _showSyncSettings(),
        ),
        _buildActionSetting(
          'Storage',
          '2.1 GB used of 5 GB',
          Icons.storage,
          () => _showStorageSettings(),
        ),
      ],
    );
  }

  Widget _buildSupportSettings() {
    return _buildSettingsSection(
      'Support & About',
      [
        _buildActionSetting(
          'Help Center',
          'Get help and tutorials',
          Icons.help,
          () => _showHelp(),
        ),
        _buildActionSetting(
          'Contact Support',
          'Get assistance from our team',
          Icons.support_agent,
          () => _contactSupport(),
        ),
        _buildActionSetting(
          'About',
          'App version 1.0.0',
          Icons.info,
          () => _showAbout(),
        ),
        _buildActionSetting(
          'Terms of Service',
          'Review terms and conditions',
          Icons.description,
          () => _showTerms(),
        ),
        _buildActionSetting(
          'Sign Out',
          'Sign out of your account',
          Icons.logout,
          () => _signOut(),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
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
            title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleSetting(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
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

  Widget _buildActionSetting(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.mediumRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
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

  Widget _buildFirebaseTestSection() {
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
            'Firebase Test (Development)',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Test Firebase connectivity and operations',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FirebaseTestScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Test Firebase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textInverse,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppTheme.mediumRadius,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BLETestScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bluetooth),
                  label: const Text('Test BLE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textInverse,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppTheme.mediumRadius,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Action methods
  void _navigateToCallDoctor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CallDoctorScreen()),
    );
  }

  void _showAppointments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointments feature - Coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _shareHealthData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Health data sharing - Coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _editInfo(String field) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit $field - Coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showAllMilestones() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All milestones view - Coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showAllRecommendations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All recommendations view - Coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _callEmergencyServices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Call'),
        content: const Text('Call emergency services (999) immediately?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement emergency call
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
            ),
            child: const Text('Call 999'),
          ),
        ],
      ),
    );
  }

  // Settings action methods (placeholders)
  void _showLanguageOptions() => _showComingSoon('Language settings');
  void _showUnitOptions() => _showComingSoon('Unit preferences');
  void _showQuietHours() => _showComingSoon('Quiet hours');
  void _exportData() => _showComingSoon('Data export');
  void _showPrivacyPolicy() => _showComingSoon('Privacy policy');
  void _showDeviceSettings() => _showComingSoon('Device settings');
  void _showSyncSettings() => _showComingSoon('Sync settings');
  void _showStorageSettings() => _showComingSoon('Storage settings');
  void _showHelp() => _showComingSoon('Help center');
  void _contactSupport() => _showComingSoon('Contact support');
  void _showAbout() => _showComingSoon('About page');
  void _showTerms() => _showComingSoon('Terms of service');

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.signOut();
        // Navigation will be handled by auth state listener
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
} 