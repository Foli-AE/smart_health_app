import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/vital_signs.dart';
import '../../shared/widgets/vital_sign_card.dart';
import '../../shared/services/firebase_data_service.dart';
import 'vital_sign_detail_screen.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseDataService _firebaseDataService = FirebaseDataService();
  StreamSubscription<VitalSigns>? _vitalSignsSubscription;
  
  // Current vital signs data
  VitalSigns _currentVitals = VitalSigns(
    id: 'initial',
    timestamp: DateTime.now(),
    heartRate: 78,
    oxygenSaturation: 98,
    temperature: 36.7,
    systolicBP: 110,
    diastolicBP: 70,
    glucose: 95,
    source: 'device',
  );

  DeviceConnectionStatus _connectionStatus = DeviceConnectionStatus.connected;
  // bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseDataService();
  }

  Future<void> _initializeFirebaseDataService() async {
    await _firebaseDataService.initialize();
    _initializeDataStream();
  }

  @override
  void dispose() {
    _vitalSignsSubscription?.cancel();
    super.dispose();
  }

  void _initializeDataStream() {
    // Listen to real-time vital signs updates
    _vitalSignsSubscription = _firebaseDataService.vitalSignsStream.listen(
      (vitalSigns) {
        if (mounted) {
          setState(() {
            _currentVitals = vitalSigns;
            _connectionStatus = DeviceConnectionStatus.connected;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _connectionStatus = DeviceConnectionStatus.error;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.primary,
          child: SingleChildScrollView(
      
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(),
                
                const SizedBox(height: AppTheme.spacingM),
                
                // Status Ring Section
                _buildStatusSection(),
                
                const SizedBox(height: AppTheme.spacingM),
                
                // Vital Signs Section
                _buildVitalSignsSection(),
                
                const SizedBox(height: AppTheme.spacingM),
                
                // Quick Actions Section
                _buildQuickActionsSection(),
                
                const SizedBox(height: AppTheme.spacingXxl),
              ],
            ),
          ),
        ),
      ),
      
      // Emergency SOS Button
      floatingActionButton: _buildSOSButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppTheme.largeRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textInverse.withValues(alpha: 0.2),
              border: Border.all(
                color: AppColors.textInverse.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              PhosphorIcons.user(),
              color: AppColors.textInverse,
              size: 30,
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingM),
          
          // Greeting and Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_getTimeOfDayGreeting()}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textInverse.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Foli Ezekiel',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Week 28 • ${_getLastUpdateTime()}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textInverse.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          
          // Connection Status
          _buildConnectionIndicator(),
        ],
      ),
    ).animate().slideY(
      begin: -0.3,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.largeRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Column(
        children: [
          // Main Status Ring (Simplified)
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _getStatusColor().withValues(alpha: 0.2),
                  _getStatusColor().withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: _getStatusColor(),
                width: 4,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 500),
                    style: AppTypography.displaySmall.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                    child: Text('${_currentVitals.healthScore.toInt()}'),
                  ),
                  Text(
                    _currentVitals.status.displayName,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().scale(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Status Message
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.1),
              borderRadius: AppTheme.mediumRadius,
              border: Border.all(
                color: _getStatusColor().withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _currentVitals.status == HealthStatus.excellent
                      ? PhosphorIcons.checkCircle()
                      : PhosphorIcons.info(),
                  color: _getStatusColor(),
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    _getStatusMessage(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideX(
      begin: 0.3,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
    );
  }

  Widget _buildVitalSignsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          'Live Vital Signs',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().slideX(
          begin: -0.3,
          duration: const Duration(milliseconds: 600),
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        // Vital Signs Grid - With staggered animations and flexible layout
        Column(
          children: [
            Row(
              children: [
                Flexible(
                  child: VitalSignConfigs.heartRate(
                    value: _currentVitals.heartRate ?? 0,
                    trend: _getTrend('heartRate'),
                    onTap: () => _showVitalDetails('Heart Rate'),
                  ).animate().slideX(
                    begin: -0.5,
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 100),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingXs),
                Flexible(
                  child: VitalSignConfigs.oxygenSaturation(
                    value: _currentVitals.oxygenSaturation ?? 0,
                    trend: _getTrend('oxygen'),
                    onTap: () => _showVitalDetails('Oxygen Saturation'),
                  ).animate().slideX(
                    begin: 0.5,
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 200),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            
            Row(
              children: [
                Flexible(
                  child: VitalSignConfigs.temperature(
                    value: _currentVitals.temperature ?? 0,
                    trend: _getTrend('temperature'),
                    onTap: () => _showVitalDetails('Temperature'),
                  ).animate().slideX(
                    begin: -0.5,
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 300),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingXs),
                Flexible(
                  child: VitalSignConfigs.bloodPressure(
                    systolic: _currentVitals.systolicBP ?? 0,
                    diastolic: _currentVitals.diastolicBP ?? 0,
                    trend: _getTrend('bloodPressure'),
                    onTap: () => _showVitalDetails('Blood Pressure'),
                  ).animate().slideX(
                    begin: 0.5,
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 400),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Glucose as a full-width card
            VitalSignConfigs.glucose(
              value: _currentVitals.glucose ?? 0,
              trend: _getTrend('glucose'),
              onTap: () => _showVitalDetails('Blood Glucose'),
            ).animate().slideY(
              begin: 0.5,
              duration: const Duration(milliseconds: 700),
              delay: const Duration(milliseconds: 500),
            ),
          ],
        ),
      ],
    );
  }

  // Helper Methods
  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  String _getLastUpdateTime() {
    final now = DateTime.now();
    final diff = now.difference(_currentVitals.timestamp);
    
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }

  String _getTrend(String vitalType) {
    // Simple trend simulation - in real app this would be calculated from historical data
    final trends = ['up', 'down', 'stable'];
    return trends[_currentVitals.timestamp.second % 3];
  }

  Color _getStatusColor() {
    switch (_currentVitals.status) {
      case HealthStatus.excellent:
        return AppColors.success;
      case HealthStatus.good:
        return AppColors.primary;
      case HealthStatus.fair:
        return AppColors.warning;
      case HealthStatus.poor:
        return AppColors.error;
      case HealthStatus.critical:
        return AppColors.critical;
    }
  }

  String _getStatusMessage() {
    switch (_currentVitals.status) {
      case HealthStatus.excellent:
        return 'All your vitals look great! Keep up the good work.';
      case HealthStatus.good:
        return 'Your vitals are in healthy ranges.';
      case HealthStatus.fair:
        return 'Some vitals need attention. Consider consulting your doctor.';
      case HealthStatus.poor:
        return 'Multiple vitals are concerning. Please contact your healthcare provider.';
      case HealthStatus.critical:
        return 'Immediate medical attention may be needed.';
    }
  }

  Widget _buildConnectionIndicator() {
    final isConnected = _connectionStatus == DeviceConnectionStatus.connected;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            _connectionStatus.displayName,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _refreshData() async {
    setState(() {
      // _isConnecting = true;
      _connectionStatus = DeviceConnectionStatus.connecting;
    });
    
    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      // _isConnecting = false;
      _connectionStatus = DeviceConnectionStatus.connected;
    });
  }

  void _showVitalDetails(String vitalType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VitalSignDetailScreen(
          vitalType: vitalType,
          currentVitals: _currentVitals,
        ),
      ),
    );
  }

  void _callDoctor() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling your healthcare provider...'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening health history...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _manageDeviceConnection() {
    setState(() {
      if (_connectionStatus == DeviceConnectionStatus.connected) {
        _connectionStatus = DeviceConnectionStatus.disconnected;
        // Firebase service handles connection automatically
      } else {
        _connectionStatus = DeviceConnectionStatus.connecting;
        _initializeDataStream();
      }
    });
  }

  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'This will send an emergency alert with your location and vital signs to your emergency contacts and healthcare provider.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert sent!'),
                  backgroundColor: AppColors.critical,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          'Quick Actions',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().slideX(
          begin: -0.3,
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 600),
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Call Doctor',
                PhosphorIcons.phone(),
                AppColors.secondary,
                () => _callDoctor(),
              ).animate().slideX(
                begin: -0.5,
                duration: const Duration(milliseconds: 700),
                delay: const Duration(milliseconds: 700),
              ),
            ),
            
            const SizedBox(width: AppTheme.spacingM),
            
            Expanded(
              child: _buildActionButton(
                'View History',
                PhosphorIcons.chartLine(),
                AppColors.primary,
                () => _viewHistory(),
              ).animate().slideX(
                begin: 0.5,
                duration: const Duration(milliseconds: 700),
                delay: const Duration(milliseconds: 800),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        // Device Connection Button
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            _connectionStatus == DeviceConnectionStatus.connected
                ? 'Device Connected'
                : 'Connect Device',
            _connectionStatus == DeviceConnectionStatus.connected
                ? PhosphorIcons.checkCircle()
                : PhosphorIcons.bluetooth(),
            _connectionStatus == DeviceConnectionStatus.connected
                ? AppColors.success
                : AppColors.warning,
            () => _manageDeviceConnection(),
          ).animate().slideY(
            begin: 0.5,
            duration: const Duration(milliseconds: 700),
            delay: const Duration(milliseconds: 900),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.textInverse,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingM,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.mediumRadius,
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildSOSButton() {
    return FloatingActionButton.extended(
      onPressed: _triggerSOS,
      backgroundColor: AppColors.critical,
      foregroundColor: AppColors.textInverse,
      icon: Icon(PhosphorIcons.warning(), size: 24),
      label: Text(
        'SOS',
        style: AppTypography.buttonLarge.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 4,
    ).animate().scale(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      delay: const Duration(milliseconds: 1000),
    );
  }
} 