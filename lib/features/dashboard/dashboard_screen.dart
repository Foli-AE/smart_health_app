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
import '../../core/navigation/main_navigation.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final FirebaseDataService _firebaseDataService = FirebaseDataService();
  StreamSubscription<List<VitalSigns>>? _vitalSignsSubscription;
  StreamSubscription<List<VitalSigns>>? _historicalDataSubscription;

  // Current vitals data from IoT
  VitalSigns _currentVitals = VitalSigns(
    id: 'initial',
    heartRate: 75, // Realistic fallback values
    oxygenSaturation: 98,
    temperature: 36.8,
    glucose: 95,
    timestamp: DateTime.now(),
  );

  // Historical data for trends
  List<VitalSigns> _historicalData = [];
  Map<String, dynamic> _dataStats = {};

  // Connection status
  DeviceConnectionStatus _connectionStatus =
      DeviceConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseService();

    // Set up periodic refresh to ensure we always have the latest IoT data
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted && _connectionStatus == DeviceConnectionStatus.connected) {
        _loadLatestVitals();
      }
    });
  }

  Future<void> _initializeFirebaseService() async {
    try {
      // Initialize the Firebase data service first
      await _firebaseDataService.initialize();
      print('✅ Firebase Data Service initialized successfully');

      // Set up real-time data streams immediately
      _initializeDataStream();

      // Load initial data
      await _loadInitialData();
    } catch (e) {
      print('❌ Error initializing Firebase service: $e');
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // Load latest vitals first
      await _loadLatestVitals();

      // Then load historical data and stats
      await _loadHistoricalData();
      await _loadDataStats();

      print('✅ Initial data loaded successfully');
    } catch (e) {
      print('❌ Error loading initial data: $e');
    }
  }

  @override
  void dispose() {
    _vitalSignsSubscription?.cancel();
    _historicalDataSubscription?.cancel();
    super.dispose();
  }

  void _initializeDataStream() {
    print('🔄 Setting up real-time data streams in dashboard...');

    // Listen to real-time vital signs updates from IoT (latest readings)
    _vitalSignsSubscription =
        _firebaseDataService.getRealTimeHistoricalData(days: 1).listen(
      (historicalData) {
        print(
            '📊 Dashboard received real-time data: ${historicalData.length} readings');
        if (historicalData.isNotEmpty && mounted) {
          final latest = historicalData.last;
          print(
              '📈 Latest real-time reading: HR=${latest.heartRate}, SpO2=${latest.oxygenSaturation}, Temp=${latest.temperature}, Glucose=${latest.glucose}');

          setState(() {
            _currentVitals = latest;
            _connectionStatus = DeviceConnectionStatus.connected;
          });

          // Also update historical data with the latest reading
          if (_historicalData.isNotEmpty) {
            final updatedHistory = List<VitalSigns>.from(_historicalData);
            // Add new reading if it's not already in the list
            if (!updatedHistory.any((vital) => vital.id == latest.id)) {
              updatedHistory.add(latest);
              // Keep only the last 100 readings to prevent memory issues
              if (updatedHistory.length > 100) {
                updatedHistory.removeRange(0, updatedHistory.length - 100);
              }
              setState(() {
                _historicalData = updatedHistory;
              });
            }
          }
        }
      },
      onError: (error) {
        print('❌ Dashboard error in real-time vital signs stream: $error');
        if (mounted) {
          setState(() {
            _connectionStatus = DeviceConnectionStatus.error;
          });
        }
      },
    );

    // Listen to historical data for trends and charts
    _historicalDataSubscription =
        _firebaseDataService.getRealTimeHistoricalData(days: 7).listen(
      (historicalData) {
        print(
            '📊 Dashboard received 7-day historical data: ${historicalData.length} readings');
        if (mounted) {
          setState(() {
            _historicalData = historicalData;
          });
        }
      },
      onError: (error) {
        print('❌ Dashboard error in historical data stream: $error');
      },
    );
  }

  Future<void> _loadHistoricalData() async {
    print('🔄 Loading historical IoT data...');
    try {
      final data = await _firebaseDataService.getHistoricalIoTData(days: 7);
      print('📊 Loaded ${data.length} historical readings');

      if (data.isNotEmpty) {
        print('✅ Using real IoT data for dashboard');
        if (mounted) {
          setState(() {
            _historicalData = data;
            // Update current vitals with the latest real data if not already set
            if (data.isNotEmpty && _currentVitals.id == 'initial') {
              _currentVitals = data.last;
              _connectionStatus = DeviceConnectionStatus.connected;
              print('📈 Set initial current vitals from historical data');
            }
          });
        }
      } else {
        print('⚠️ No IoT data found, generating realistic test data...');
        final testData = _generateRealisticTestData();
        if (mounted) {
          setState(() {
            _historicalData = testData;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading historical data: $e');
      // Generate test data as fallback
      final testData = _generateRealisticTestData();
      if (mounted) {
        setState(() {
          _historicalData = testData;
        });
      }
    }
  }

  Future<void> _loadLatestVitals() async {
    print('🔄 Loading latest IoT vitals...');
    try {
      final latest = await _firebaseDataService.getLatestIoTReading();
      if (latest != null && mounted) {
        print(
            '✅ Updated current vitals with latest IoT data: HR=${latest.heartRate}, SpO2=${latest.oxygenSaturation}, Temp=${latest.temperature}, Glucose=${latest.glucose}');
        setState(() {
          _currentVitals = latest;
          _connectionStatus = DeviceConnectionStatus.connected;
        });

        // Also update historical data if this is a new reading
        if (_historicalData.isEmpty ||
            !_historicalData.any((vital) => vital.id == latest.id)) {
          final updatedHistory = List<VitalSigns>.from(_historicalData);
          updatedHistory.add(latest);
          setState(() {
            _historicalData = updatedHistory;
          });
        }
      } else {
        print('⚠️ No latest IoT vitals available');
      }
    } catch (e) {
      print('❌ Error loading latest vitals: $e');
    }
  }

  List<VitalSigns> _generateRealisticTestData() {
    final now = DateTime.now();
    final data = <VitalSigns>[];

    for (int i = 6; i >= 0; i--) {
      for (int hour = 0; hour < 24; hour += 2) {
        final timestamp = now.subtract(Duration(days: i, hours: hour));

        // Generate realistic variations
        final heartRate =
            75 + (DateTime.now().millisecond % 20) - 10; // 65-85 BPM
        final oxygenSaturation =
            98 + (DateTime.now().millisecond % 4) - 2; // 96-100%
        final temperature =
            36.8 + (DateTime.now().millisecond % 10) / 10 - 0.5; // 36.3-37.3°C
        final glucose =
            95 + (DateTime.now().millisecond % 20) - 10; // 85-105 mg/dL

        data.add(VitalSigns(
          id: 'test_${timestamp.millisecondsSinceEpoch}',
          heartRate: heartRate.toDouble(),
          oxygenSaturation: oxygenSaturation.toDouble(),
          temperature: temperature,
          glucose: glucose.toDouble(),
          timestamp: timestamp,
          source: 'test_device',
          isSynced: true,
        ));
      }
    }

    print('📊 Generated ${data.length} realistic test readings');
    return data;
  }

  Future<void> _loadDataStats() async {
    print('🔄 Loading IoT data statistics...');
    try {
      final stats = await _firebaseDataService.getIoTDataStats(days: 7);
      print('📊 Loaded stats: $stats');

      if (stats.isNotEmpty && (stats['heartRate']?['avg'] ?? 0) > 0) {
        print('✅ Using real IoT stats for dashboard');
        if (mounted) {
          setState(() {
            _dataStats = stats;
          });
        }
      } else {
        print('⚠️ No IoT stats available, generating realistic test stats...');
        final testStats = _generateRealisticTestStats();
        if (mounted) {
          setState(() {
            _dataStats = testStats;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading data stats: $e');
      // Generate test stats as fallback
      final testStats = _generateRealisticTestStats();
      if (mounted) {
        setState(() {
          _dataStats = testStats;
        });
      }
    }
  }

  Map<String, dynamic> _generateRealisticTestStats() {
    return {
      'heartRate': {
        'avg': 75.0,
        'min': 65.0,
        'max': 85.0,
      },
      'oxygenSaturation': {
        'avg': 98.0,
        'min': 96.0,
        'max': 100.0,
      },
      'temperature': {
        'avg': 36.8,
        'min': 36.3,
        'max': 37.3,
      },
      'glucose': {
        'avg': 95.0,
        'min': 85.0,
        'max': 105.0,
      },
    };
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
                Text(
                  'Last IoT Update: ${_getLastUpdateTime()}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textInverse.withValues(alpha: 0.7),
                    fontSize: 10,
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
                    //make it heartrate mines 80
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
                  child: VitalSignConfigs.glucose(
                    value: _currentVitals.glucose ?? 0,
                    trend: _getTrend('glucose'),
                    onTap: () => _showVitalDetails('Glucose'),
                  ).animate().slideX(
                        begin: 0.5,
                        duration: const Duration(milliseconds: 700),
                        delay: const Duration(milliseconds: 400),
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
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
    if (_historicalData.length < 2) {
      return 'stable';
    }

    // Get the last 2 readings for trend calculation
    final recent = _historicalData.last;
    final previous = _historicalData[_historicalData.length - 2];

    double currentValue = 0;
    double previousValue = 0;

    switch (vitalType.toLowerCase()) {
      case 'heart rate':
        currentValue = recent.heartRate ?? 0;
        previousValue = previous.heartRate ?? 0;
        break;
      case 'oxygen saturation':
      case 'spo2':
        currentValue = recent.oxygenSaturation ?? 0;
        previousValue = previous.oxygenSaturation ?? 0;
        break;
      case 'temperature':
        currentValue = recent.temperature ?? 0;
        previousValue = previous.temperature ?? 0;
        break;
      case 'glucose':
        currentValue = recent.glucose ?? 0;
        previousValue = previous.glucose ?? 0;
        break;
      default:
        return 'stable';
    }

    if (previousValue == 0) return 'stable';

    final changePercent =
        ((currentValue - previousValue) / previousValue) * 100;

    if (changePercent > 5) {
      return 'up';
    } else if (changePercent < -5) {
      return 'down';
    } else {
      return 'stable';
    }
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
      _connectionStatus = DeviceConnectionStatus.connecting;
    });

    try {
      // Reload real IoT data efficiently
      await _loadLatestVitals();
      await _loadHistoricalData();
      await _loadDataStats();

      print('✅ Dashboard refreshed with latest IoT data');
    } catch (e) {
      print('❌ Error refreshing dashboard data: $e');
    }

    setState(() {
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
    // Navigate to alerts screen which has emergency call functionality
    // Since we're using bottom navigation, we need to find the parent and switch tabs
    final mainNavigation =
        context.findAncestorStateOfType<MainNavigationScreenState>();
    if (mainNavigation != null) {
      mainNavigation.currentIndex = 2; // Alerts tab index
    }
  }

  void _viewHistory() {
    // Navigate to history screen using bottom navigation
    final mainNavigation =
        context.findAncestorStateOfType<MainNavigationScreenState>();
    if (mainNavigation != null) {
      mainNavigation.currentIndex = 1; // History tab index
    }
  }

  void _manageDeviceConnection() {
    if (_connectionStatus == DeviceConnectionStatus.connected) {
      // Show disconnect confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disconnect IoT Device'),
          content: const Text(
            'Are you sure you want to disconnect from the IoT device? This will stop real-time monitoring.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _connectionStatus = DeviceConnectionStatus.disconnected;
                });
                // Stop data streams
                _vitalSignsSubscription?.cancel();
                _historicalDataSubscription?.cancel();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
              ),
              child: const Text('Disconnect'),
            ),
          ],
        ),
      );
    } else {
      // Reconnect
      setState(() {
        _connectionStatus = DeviceConnectionStatus.connecting;
      });
      _initializeDataStream();
      _loadInitialData();
    }
  }

  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Emergency SOS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will send an emergency alert with your current vital signs to emergency contacts.',
            ),
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppColors.critical.withValues(alpha: 0.1),
                borderRadius: AppTheme.smallRadius,
                border: Border.all(
                    color: AppColors.critical.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Vitals:',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.critical,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                      'Heart Rate: ${_currentVitals.heartRate?.toInt() ?? 0} BPM'),
                  Text(
                      'SpO2: ${_currentVitals.oxygenSaturation?.toInt() ?? 0}%'),
                  Text(
                      'Temperature: ${_currentVitals.temperature?.toStringAsFixed(1) ?? '0.0'}°C'),
                  Text(
                      'Glucose: ${_currentVitals.glucose?.toInt() ?? 0} mg/dL'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendEmergencyAlert();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
            ),
            child: const Text('🚨 Send SOS Alert'),
          ),
        ],
      ),
    );
  }

  void _sendEmergencyAlert() {
    // Show emergency alert sent confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🚨 Emergency SOS alert sent!'),
        backgroundColor: AppColors.critical,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          textColor: AppColors.textInverse,
          onPressed: () {
            // Navigate to alerts screen to see the emergency alert
            final mainNavigation =
                context.findAncestorStateOfType<MainNavigationScreenState>();
            if (mainNavigation != null) {
              mainNavigation.currentIndex = 2; // Alerts tab index
            }
          },
        ),
      ),
    );

    // In a real app, this would:
    // 1. Send push notification to emergency contacts
    // 2. Send SMS to emergency numbers
    // 3. Log emergency event to Firebase
    // 4. Trigger emergency protocols
    print('🚨 Emergency SOS alert triggered with vitals: $_currentVitals');
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),

        // Real-time Status Indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: _connectionStatus == DeviceConnectionStatus.connected
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.warning.withValues(alpha: 0.1),
            borderRadius: AppTheme.mediumRadius,
            border: Border.all(
              color: _connectionStatus == DeviceConnectionStatus.connected
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _connectionStatus == DeviceConnectionStatus.connected
                    ? PhosphorIcons.checkCircle()
                    : PhosphorIcons.warning(),
                color: _connectionStatus == DeviceConnectionStatus.connected
                    ? AppColors.success
                    : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _connectionStatus == DeviceConnectionStatus.connected
                          ? 'IoT Device Connected'
                          : 'IoT Device Disconnected',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _connectionStatus ==
                                DeviceConnectionStatus.connected
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                    Text(
                      _connectionStatus == DeviceConnectionStatus.connected
                          ? 'Receiving real-time sensor data'
                          : 'Check device connection and try refreshing',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingM),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: PhosphorIcons.phone(),
                label: 'Call Doctor',
                color: AppColors.secondary,
                onTap: () => _callDoctor(),
              ).animate().slideX(
                    begin: -0.5,
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 700),
                  ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _buildActionButton(
                icon: PhosphorIcons.chartLine(),
                label: 'View History',
                color: AppColors.success,
                onTap: () => _viewHistory(),
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
            icon: _connectionStatus == DeviceConnectionStatus.connected
                ? PhosphorIcons.checkCircle()
                : PhosphorIcons.bluetooth(),
            label: _connectionStatus == DeviceConnectionStatus.connected
                ? 'Device Connected'
                : 'Connect Device',
            color: _connectionStatus == DeviceConnectionStatus.connected
                ? AppColors.success
                : AppColors.warning,
            onTap: () => _manageDeviceConnection(),
          ).animate().slideY(
                begin: 0.5,
                duration: const Duration(milliseconds: 700),
                delay: const Duration(milliseconds: 900),
              ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
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
