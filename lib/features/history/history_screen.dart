import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/services/firebase_data_service.dart';
import '../../shared/models/vital_signs.dart';
import 'dart:async';
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  final FirebaseDataService _firebaseDataService = FirebaseDataService();

  late TabController _tabController;
  String _selectedPeriod = '7D';
  String _selectedVitalSign = 'heartRate';
  bool _isLoading = false;

  // Real IoT data
  List<VitalSigns> _historicalData = [];
  Map<String, dynamic> _dataStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    setState(() => _isLoading = true);

    try {
      final days = _selectedPeriod == '24H'
          ? 1
          : _selectedPeriod == '7D'
              ? 7
              : 30;

      print('🔄 Loading real IoT data for last $days days...');

      // Load real IoT data
      final data = await _firebaseDataService.getHistoricalIoTData(days: days);
      final stats = await _firebaseDataService.getIoTDataStats(days: days);

      print('📊 History screen loaded ${data.length} IoT readings');

      if (mounted) {
        setState(() {
          _historicalData = data;
          _dataStats = stats;
          _isLoading = false;
        });

        if (data.isNotEmpty) {
          print('✅ History screen using real IoT data');
        } else {
          print('⚠️ History screen: No IoT data available');
        }
      }
    } catch (e) {
      print('❌ Error loading historical data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Health History',
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
            icon:
                Icon(PhosphorIcons.downloadSimple(), color: AppColors.primary),
            onPressed: () => _exportData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Charts'),
            Tab(text: 'Trends'),
            Tab(text: 'Summary'),
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
                _buildChartsTab(),
                _buildTrendsTab(),
                _buildSummaryTab(),
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
            'Loading your health data...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_historicalData.isEmpty) {
      return _buildEmptyState('Charts', 'No data available for charts');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildControlsSection(),
          const SizedBox(height: AppTheme.spacingL),
          _buildMainChart(),
          const SizedBox(height: AppTheme.spacingL),
          _buildQuickStatsSection(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    if (_historicalData.isEmpty) {
      return _buildEmptyState('Trends', 'No data available for trend analysis');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Analysis',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Overall Health Trend
          _buildTrendCard(
            'Overall Health',
            _calculateOverallTrend(),
            'Based on all vital signs',
            AppColors.primary,
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Individual Vital Sign Trends
          Text(
            'Vital Sign Trends',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),

          _buildVitalSignTrendCard('Heart Rate', 'heartRate'),
          _buildVitalSignTrendCard('Oxygen Saturation', 'oxygenSaturation'),
          _buildVitalSignTrendCard('Temperature', 'temperature'),
          _buildVitalSignTrendCard('Glucose', 'glucose'),

          const SizedBox(height: AppTheme.spacingL),

          // Pattern Recognition
          _buildPatternSection(),
        ],
      ),
    );
  }

  Widget _buildTrendCard(
      String title, String trend, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.trendUp(),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  trend,
                  style: AppTypography.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
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

  Widget _buildVitalSignTrendCard(String vitalName, String vitalType) {
    final trend = _calculateVitalSignTrend(vitalType);
    final color = _getTrendColor(trend);
    final icon = _getTrendIcon(trend);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vitalName,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  trend,
                  style: AppTypography.bodySmall.copyWith(
                    color: color,
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

  Widget _buildPatternSection() {
    if (_historicalData.length < 3) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pattern Recognition',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildPatternCard(
          'Daily Variation',
          _analyzeDailyPattern(),
          PhosphorIcons.clock(),
          AppColors.secondary,
        ),
        _buildPatternCard(
          'Stability Score',
          _calculateStabilityScore(),
          PhosphorIcons.shieldCheck(),
          AppColors.success,
        ),
      ],
    );
  }

  Widget _buildPatternCard(
      String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: AppTheme.smallRadius,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
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

  Widget _buildSummaryTab() {
    if (_historicalData.isEmpty) {
      return _buildEmptyState(
          'Summary', 'No data available for health summary');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Summary',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Overall Health Score
          _buildHealthScoreCard(),

          const SizedBox(height: AppTheme.spacingM),

          // Vital Signs Overview
          _buildVitalSignsOverview(),

          const SizedBox(height: AppTheme.spacingM),

          // Health Insights
          _buildHealthInsights(),

          const SizedBox(height: AppTheme.spacingM),

          // Recommendations
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    final healthScore = _calculateOverallHealthScore();
    final color = _getHealthScoreColor(healthScore);
    final status = _getHealthScoreStatus(healthScore);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.largeRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Column(
        children: [
          Text(
            'Overall Health Score',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                healthScore.toString(),
                style: AppTypography.displaySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            status,
            style: AppTypography.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSignsOverview() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vital Signs Overview',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildVitalSignSummaryRow(
              'Heart Rate',
              double.parse(_getAverageValueForVital('heartRate')),
              'bpm',
              AppColors.heartRate),
          _buildVitalSignSummaryRow(
              'Oxygen Saturation',
              double.parse(_getAverageValueForVital('oxygenSaturation')),
              '%',
              AppColors.oxygenSaturation),
          _buildVitalSignSummaryRow(
              'Temperature',
              double.parse(_getAverageValueForVital('temperature')),
              '°C',
              AppColors.temperature),
          // _buildVitalSignSummaryRow(
          //     'Glucose',
          //     double.parse(_getAverageValueForVital('glucose')),
          //     'mg/dL',
          //     AppColors.glucose),
        ],
      ),
    );
  }

  Widget _buildVitalSignSummaryRow(
      String name, double value, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
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
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              name,
              style: AppTypography.bodyMedium,
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInsights() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Insights',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInsightRow(
            'Data Coverage',
            '${_historicalData.length} readings over ${_getDataCoveragePeriod()}',
            PhosphorIcons.calendar(),
            AppColors.primary,
          ),
          _buildInsightRow(
            'Monitoring Frequency',
            _getMonitoringFrequency(),
            PhosphorIcons.clock(),
            AppColors.secondary,
          ),
          _buildInsightRow(
            'Data Quality',
            _getDataQuality(),
            PhosphorIcons.checkCircle(),
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
      String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
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

  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildRecommendationRow(
            'Continue Monitoring',
            'Keep tracking your vital signs regularly for better health insights.',
            PhosphorIcons.eye(),
            AppColors.primary,
          ),
          _buildRecommendationRow(
            'Share with Doctor',
            'Share this data with your healthcare provider during your next visit.',
            PhosphorIcons.share(),
            AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationRow(
      String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
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

  Widget _buildControlsSection() {
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
            'View Options',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildPeriodSelection(),
          const SizedBox(height: AppTheme.spacingM),
          _buildVitalSignSelection(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Period',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacingS),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedPeriod = '24H');
                    _loadHistoricalData();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == '24H'
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: AppTheme.mediumRadius,
                      border: Border.all(
                        color: _selectedPeriod == '24H'
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '24H',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelMedium.copyWith(
                        color: _selectedPeriod == '24H'
                            ? AppColors.textInverse
                            : AppColors.textSecondary,
                        fontWeight: _selectedPeriod == '24H'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppTheme.spacingS),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedPeriod = '7D');
                    _loadHistoricalData();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == '7D'
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: AppTheme.mediumRadius,
                      border: Border.all(
                        color: _selectedPeriod == '7D'
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '7D',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelMedium.copyWith(
                        color: _selectedPeriod == '7D'
                            ? AppColors.textInverse
                            : AppColors.textSecondary,
                        fontWeight: _selectedPeriod == '7D'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppTheme.spacingS),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedPeriod = '30D');
                    _loadHistoricalData();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == '30D'
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: AppTheme.mediumRadius,
                      border: Border.all(
                        color: _selectedPeriod == '30D'
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '30D',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelMedium.copyWith(
                        color: _selectedPeriod == '30D'
                            ? AppColors.textInverse
                            : AppColors.textSecondary,
                        fontWeight: _selectedPeriod == '30D'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalSignSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vital Sign',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: VitalSignType.values.map((type) {
              final isSelected = _selectedVitalSign == type.name;
              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacingS),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedVitalSign = type.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? type.color.withValues(alpha: 0.1)
                          : AppColors.background,
                      borderRadius: AppTheme.mediumRadius,
                      border: Border.all(
                        color: isSelected ? type.color : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type.icon,
                          size: 16,
                          color:
                              isSelected ? type.color : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        Text(
                          type.displayName,
                          style: AppTypography.labelMedium.copyWith(
                            color: isSelected
                                ? type.color
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMainChart() {
    if (_historicalData.isEmpty) {
      return _buildEmptyState(
          'Chart', 'No data available for the selected period');
    }

    final chartData = _getChartDataForVitalType(_selectedVitalSign);

    return Container(
      height: 300,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getSelectedVitalSignType().displayName,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Last ${_selectedPeriod.toLowerCase()}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingS,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      _getSelectedVitalSignType().color.withValues(alpha: 0.1),
                  borderRadius: AppTheme.smallRadius,
                ),
                child: Text(
                  _getAverageValue(),
                  style: AppTypography.labelSmall.copyWith(
                    color: _getSelectedVitalSignType().color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getGridInterval(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.3),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (_historicalData.length / 6).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _historicalData.length) {
                          final date = _historicalData[index].timestamp;
                          return Text(
                            '${date.month}/${date.day}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: VitalSignType.values
                        .firstWhere((type) => type.name == _selectedVitalSign)
                        .color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: chartData.length <= 20,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: VitalSignType.values
                            .firstWhere(
                                (type) => type.name == _selectedVitalSign)
                            .color,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: VitalSignType.values
                          .firstWhere((type) => type.name == _selectedVitalSign)
                          .color
                          .withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    final stats = _calculateQuickStats();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Average',
            (stats['average'] ?? 0.0).toStringAsFixed(1),
            VitalSignType.values
                .firstWhere((type) => type.name == _selectedVitalSign)
                .unit,
            Icons.analytics,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _buildStatCard(
            'Highest',
            (stats['max'] ?? 0.0).toStringAsFixed(1),
            VitalSignType.values
                .firstWhere((type) => type.name == _selectedVitalSign)
                .unit,
            Icons.trending_up,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _buildStatCard(
            'Lowest',
            (stats['min'] ?? 0.0).toStringAsFixed(1),
            VitalSignType.values
                .firstWhere((type) => type.name == _selectedVitalSign)
                .unit,
            Icons.trending_down,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.elevation1,
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
            unit,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
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

  Widget _buildEmptyState(String title, String message) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.largeRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.chartLine(),
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  List<FlSpot> _getChartDataForVitalType(String typeName) {
    final data = <FlSpot>[];
    for (int i = 0; i < _historicalData.length; i++) {
      final vital = _historicalData[i];
      final value = _getValueForVitalType(typeName, vital);
      if (value != null) {
        data.add(FlSpot(i.toDouble(), value));
      }
    }
    return data;
  }

  double? _getValueForVitalType(String typeName, VitalSigns vital) {
    switch (typeName) {
      case 'heartRate':
        return vital.heartRate;
      case 'oxygenSaturation':
        return vital.oxygenSaturation;
      case 'temperature':
        return vital.temperature;
      case 'glucose':
        return vital.glucose;
      default:
        return null; // Return null for unknown vital sign types
    }
  }

  Map<String, double> _calculateQuickStats() {
    final values = _historicalData
        .map((vital) => _getValueForVitalType(_selectedVitalSign, vital))
        .where((value) => value != null)
        .cast<double>()
        .toList();

    if (values.isEmpty) {
      return {'average': 0, 'max': 0, 'min': 0};
    }

    return {
      'average': values.reduce((a, b) => a + b) / values.length,
      'max': values.reduce((a, b) => a > b ? a : b),
      'min': values.reduce((a, b) => a < b ? a : b),
    };
  }

  VitalSignType _getSelectedVitalSignType() {
    return VitalSignType.values.firstWhere(
      (type) => type.name == _selectedVitalSign,
      orElse: () => VitalSignType.heartRate,
    );
  }

  String _getAverageValue() {
    final stats = _calculateQuickStats();
    final vitalType = _getSelectedVitalSignType();
    return '${(stats['average'] ?? 0.0).toStringAsFixed(1)} ${vitalType.unit}';
  }

  double _getGridInterval() {
    final stats = _calculateQuickStats();
    final range = (stats['max'] ?? 0.0) - (stats['min'] ?? 0.0);
    return range / 5; // 5 grid lines
  }

  void _exportData() {
    if (_historicalData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data available to export'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Show export options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Health Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Export ${_historicalData.length} health readings'),
            const SizedBox(height: AppTheme.spacingM),
            Text('Data period: ${_getDataCoveragePeriod()}'),
            const SizedBox(height: AppTheme.spacingM),
            Text('Vital signs: Heart Rate, SpO2, Temperature, Glucose'),
            const SizedBox(height: AppTheme.spacingM),
            const Text('Choose export format:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportToCSV();
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('Export CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportToJSON();
            },
            icon: const Icon(Icons.code),
            label: const Text('Export JSON'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.textInverse,
            ),
          ),
        ],
      ),
    );
  }

  void _exportToCSV() {
    final csvData = _generateCSVData();
    _showExportSuccess('CSV', csvData);
  }

  void _exportToJSON() {
    final jsonData = _generateJSONData();
    _showExportSuccess('JSON', jsonData);
  }

  String _generateCSVData() {
    final StringBuffer csv = StringBuffer();

    // CSV header
    csv.writeln(
        'Timestamp,Heart Rate (BPM),Oxygen Saturation (%),Temperature (°C),Glucose (mg/dL)');

    // CSV data rows
    for (final vital in _historicalData) {
      csv.writeln(
          '${vital.timestamp.toIso8601String()},${vital.heartRate ?? 0},${vital.oxygenSaturation ?? 0},${vital.temperature ?? 0},${vital.glucose ?? 0}');
    }

    return csv.toString();
  }

  String _generateJSONData() {
    final List<Map<String, dynamic>> jsonData = _historicalData
        .map((vital) => {
              'timestamp': vital.timestamp.toIso8601String(),
              'heartRate': vital.heartRate,
              'oxygenSaturation': vital.oxygenSaturation,
              'temperature': vital.temperature,
              'glucose': vital.glucose,
              'source': vital.source,
              'isSynced': vital.isSynced,
            })
        .toList();

    return JsonEncoder.withIndent('  ').convert({
      'exportDate': DateTime.now().toIso8601String(),
      'totalReadings': _historicalData.length,
      'dataPeriod': _getDataCoveragePeriod(),
      'vitalSigns': jsonData,
    });
  }

  void _showExportSuccess(String format, String data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Health data exported successfully as $format! ${_historicalData.length} readings saved.'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'View',
          textColor: AppColors.textInverse,
          onPressed: () {
            // In a real app, this would open the exported file
            print('📊 Exported $format data:\n$data');
          },
        ),
      ),
    );
  }

  String _calculateOverallTrend() {
    if (_historicalData.length < 2) {
      return 'Not enough data for trend analysis';
    }

    final firstValue = _historicalData.first.timestamp;
    final lastValue = _historicalData.last.timestamp;

    final differenceInDays = lastValue.difference(firstValue).inDays;

    if (differenceInDays == 0) {
      return 'No trend data available';
    }

    final averageChange = ((_historicalData.last.heartRate ?? 0.0) -
            (_historicalData.first.heartRate ?? 0.0)) /
        differenceInDays;

    if (averageChange > 0) {
      return 'Heart Rate is increasing by ${averageChange.toStringAsFixed(1)} bpm/day';
    } else if (averageChange < 0) {
      return 'Heart Rate is decreasing by ${averageChange.abs().toStringAsFixed(1)} bpm/day';
    } else {
      return 'Heart Rate is stable';
    }
  }

  String _calculateVitalSignTrend(String vitalType) {
    if (_historicalData.length < 2) {
      return 'Not enough data for trend analysis';
    }

    final firstValue = _historicalData.first;
    final lastValue = _historicalData.last;

    final valueChange = (_getValueForVitalType(vitalType, lastValue) ?? 0.0) -
        (_getValueForVitalType(vitalType, firstValue) ?? 0.0);
    final differenceInDays = _historicalData.last.timestamp
        .difference(_historicalData.first.timestamp)
        .inDays;

    if (differenceInDays == 0) {
      return 'No trend data available';
    }

    final averageChange = valueChange / differenceInDays;

    final vitalTypeEnum = VitalSignType.values.firstWhere(
      (type) => type.name == vitalType,
      orElse: () => VitalSignType.heartRate,
    );

    if (averageChange > 0) {
      return '${vitalTypeEnum.displayName} is increasing by ${averageChange.toStringAsFixed(1)} ${vitalTypeEnum.unit}/day';
    } else if (averageChange < 0) {
      return '${vitalTypeEnum.displayName} is decreasing by ${averageChange.abs().toStringAsFixed(1)} ${vitalTypeEnum.unit}/day';
    } else {
      return '${vitalTypeEnum.displayName} is stable';
    }
  }

  IconData _getTrendIcon(String trend) {
    if (trend.contains('increasing')) {
      return PhosphorIcons.trendUp();
    } else if (trend.contains('decreasing')) {
      return PhosphorIcons.trendDown();
    } else {
      return PhosphorIcons.minus();
    }
  }

  Color _getTrendColor(String trend) {
    if (trend.contains('increasing')) {
      return AppColors.warning;
    } else if (trend.contains('decreasing')) {
      return AppColors.success;
    } else {
      return AppColors.textSecondary;
    }
  }

  String _analyzeDailyPattern() {
    if (_historicalData.length < 2) {
      return 'Not enough data for pattern analysis';
    }

    final firstValue = _historicalData.first;
    final lastValue = _historicalData.last;

    final heartRateChange =
        (lastValue.heartRate ?? 0.0) - (firstValue.heartRate ?? 0.0);
    final oxygenSaturationChange = (lastValue.oxygenSaturation ?? 0.0) -
        (firstValue.oxygenSaturation ?? 0.0);
    final temperatureChange =
        (lastValue.temperature ?? 0.0) - (firstValue.temperature ?? 0.0);
    final glucoseChange =
        (lastValue.glucose ?? 0.0) - (firstValue.glucose ?? 0.0);

    final differenceInDays = _historicalData.last.timestamp
        .difference(_historicalData.first.timestamp)
        .inDays;

    if (differenceInDays == 0) {
      return 'No pattern data available';
    }

    final averageDailyChange = <String, double>{
      'heartRate': heartRateChange / differenceInDays,
      'oxygenSaturation': oxygenSaturationChange / differenceInDays,
      'temperature': temperatureChange / differenceInDays,
      'glucose': glucoseChange / differenceInDays,
    };

    final StringBuffer patternDescription = StringBuffer();
    patternDescription.write('Daily Pattern: ');

    if ((averageDailyChange['heartRate'] ?? 0.0) > 0) {
      patternDescription.write(
          'Heart Rate increases by ${(averageDailyChange['heartRate'] ?? 0.0).toStringAsFixed(1)} bpm/day, ');
    } else if ((averageDailyChange['heartRate'] ?? 0.0) < 0) {
      patternDescription.write(
          'Heart Rate decreases by ${(averageDailyChange['heartRate'] ?? 0.0).abs().toStringAsFixed(1)} bpm/day, ');
    }

    if ((averageDailyChange['oxygenSaturation'] ?? 0.0) > 0) {
      patternDescription.write(
          'SpO2 increases by ${(averageDailyChange['oxygenSaturation'] ?? 0.0).toStringAsFixed(1)} %/day, ');
    } else if ((averageDailyChange['oxygenSaturation'] ?? 0.0) < 0) {
      patternDescription.write(
          'SpO2 decreases by ${(averageDailyChange['oxygenSaturation'] ?? 0.0).abs().toStringAsFixed(1)} %/day, ');
    }

    if ((averageDailyChange['temperature'] ?? 0.0) > 0) {
      patternDescription.write(
          'Temperature increases by ${(averageDailyChange['temperature'] ?? 0.0).toStringAsFixed(1)} °C/day, ');
    } else if ((averageDailyChange['temperature'] ?? 0.0) < 0) {
      patternDescription.write(
          'Temperature decreases by ${(averageDailyChange['temperature'] ?? 0.0).abs().toStringAsFixed(1)} °C/day, ');
    }

    if ((averageDailyChange['glucose'] ?? 0.0) > 0) {
      patternDescription.write(
          'Glucose increases by ${(averageDailyChange['glucose'] ?? 0.0).toStringAsFixed(1)} mg/dL/day, ');
    } else if ((averageDailyChange['glucose'] ?? 0.0) < 0) {
      patternDescription.write(
          'Glucose decreases by ${(averageDailyChange['glucose'] ?? 0.0).abs().toStringAsFixed(1)} %/day, ');
    }

    return patternDescription.toString().trim();
  }

  String _calculateStabilityScore() {
    if (_historicalData.length < 3) {
      return 'Not enough data for stability analysis';
    }

    final firstValue = _historicalData.first;
    final lastValue = _historicalData.last;

    final heartRateChange =
        (lastValue.heartRate ?? 0.0) - (firstValue.heartRate ?? 0.0);
    final oxygenSaturationChange = (lastValue.oxygenSaturation ?? 0.0) -
        (firstValue.oxygenSaturation ?? 0.0);
    final temperatureChange =
        (lastValue.temperature ?? 0.0) - (firstValue.temperature ?? 0.0);
    final glucoseChange =
        (lastValue.glucose ?? 0.0) - (firstValue.glucose ?? 0.0);

    final differenceInDays = _historicalData.last.timestamp
        .difference(_historicalData.first.timestamp)
        .inDays;

    if (differenceInDays == 0) {
      return 'No stability data available';
    }

    final averageDailyChange = <String, double>{
      'heartRate': heartRateChange / differenceInDays,
      'oxygenSaturation': oxygenSaturationChange / differenceInDays,
      'temperature': temperatureChange / differenceInDays,
      'glucose': glucoseChange / differenceInDays,
    };

    final double stabilityScore = averageDailyChange.values
            .map((change) => change.abs())
            .reduce((a, b) => a + b) /
        averageDailyChange.length;

    if (stabilityScore < 0.5) {
      return 'High Stability (Score: ${stabilityScore.toStringAsFixed(1)})';
    } else if (stabilityScore < 1.0) {
      return 'Moderate Stability (Score: ${stabilityScore.toStringAsFixed(1)})';
    } else {
      return 'Low Stability (Score: ${stabilityScore.toStringAsFixed(1)})';
    }
  }

  double _calculateOverallHealthScore() {
    if (_historicalData.length < 2) {
      return 0.0;
    }

    final firstValue = _historicalData.first;
    final lastValue = _historicalData.last;

    final heartRateChange =
        (lastValue.heartRate ?? 0.0) - (firstValue.heartRate ?? 0.0);
    final oxygenSaturationChange = (lastValue.oxygenSaturation ?? 0.0) -
        (firstValue.oxygenSaturation ?? 0.0);
    final temperatureChange =
        (lastValue.temperature ?? 0.0) - (firstValue.temperature ?? 0.0);
    final glucoseChange =
        (lastValue.glucose ?? 0.0) - (firstValue.glucose ?? 0.0);

    final differenceInDays = _historicalData.last.timestamp
        .difference(_historicalData.first.timestamp)
        .inDays;

    if (differenceInDays == 0) {
      return 0.0;
    }

    final averageDailyChange = <String, double>{
      'heartRate': heartRateChange / differenceInDays,
      'oxygenSaturation': oxygenSaturationChange / differenceInDays,
      'temperature': temperatureChange / differenceInDays,
      'glucose': glucoseChange / differenceInDays,
    };

    final double stabilityScore = averageDailyChange.values
            .map((change) => change.abs())
            .reduce((a, b) => a + b) /
        averageDailyChange.length;

    // Simple scoring: 0-20% = 0, 21-40% = 1, 41-60% = 2, 61-80% = 3, 81-100% = 4
    // This is a very basic scoring, a real health score would be more complex
    // and consider multiple factors.
    if (stabilityScore < 0.2) {
      return 0.0;
    } else if (stabilityScore < 0.4) {
      return 1.0;
    } else if (stabilityScore < 0.6) {
      return 2.0;
    } else if (stabilityScore < 0.8) {
      return 3.0;
    } else {
      return 4.0;
    }
  }

  Color _getHealthScoreColor(double score) {
    if (score < 0.2) {
      return AppColors.error;
    } else if (score < 0.4) {
      return AppColors.warning;
    } else if (score < 0.6) {
      return AppColors.secondary;
    } else if (score < 0.8) {
      return AppColors.success;
    } else {
      return AppColors.primary;
    }
  }

  String _getHealthScoreStatus(double score) {
    if (score < 0.2) {
      return 'Poor Health Status';
    } else if (score < 0.4) {
      return 'Fair Health Status';
    } else if (score < 0.6) {
      return 'Good Health Status';
    } else if (score < 0.8) {
      return 'Very Good Health Status';
    } else {
      return 'Excellent Health Status';
    }
  }

  String _getAverageValueForVital(String vitalType) {
    final values = _historicalData
        .map((vital) => _getValueForVitalType(vitalType, vital))
        .where((value) => value != null)
        .cast<double>()
        .toList();

    if (values.isEmpty) {
      return '0';
    }
    return '${values.reduce((a, b) => a + b) / values.length}';
  }

  String _getDataCoveragePeriod() {
    final firstValue = _historicalData.first;
    final lastValue = _historicalData.last;
    final differenceInDays =
        lastValue.timestamp.difference(firstValue.timestamp).inDays;
    return differenceInDays == 0 ? '1 day' : '$differenceInDays days';
  }

  String _getMonitoringFrequency() {
    final firstValue = _historicalData.first;
    final lastValue = _historicalData.last;
    final differenceInDays =
        lastValue.timestamp.difference(firstValue.timestamp).inDays;
    return differenceInDays == 0
        ? 'Every 1 minute'
        : 'Every ${differenceInDays == 0 ? '1 minute' : '${(differenceInDays / 60).ceil()} minutes'}';
  }

  String _getDataQuality() {
    // This is a placeholder. In a real app, you'd analyze data points for anomalies,
    // missing values, or consistency.
    return 'High Quality';
  }
}

// Enums and extensions
enum VitalSignType {
  heartRate,
  oxygenSaturation,
  temperature,
  // glucose,
}

extension VitalSignTypeExtension on VitalSignType {
  String get displayName {
    switch (this) {
      case VitalSignType.heartRate:
        return 'Heart Rate';
      case VitalSignType.oxygenSaturation:
        return 'SpO2';
      case VitalSignType.temperature:
        return 'Temperature';
      // case VitalSignType.glucose:
      //   return 'Glucose';
      default:
        return 'Unknown';
    }
  }

  String get unit {
    switch (this) {
      case VitalSignType.heartRate:
        return 'bpm';
      case VitalSignType.oxygenSaturation:
        return '%';
      case VitalSignType.temperature:
        return '°C';
      // case VitalSignType.glucose:
      //   return 'mg/dL';
      default:
        return '';
    }
  }

  IconData get icon {
    switch (this) {
      case VitalSignType.heartRate:
        return PhosphorIcons.heartbeat();
      case VitalSignType.oxygenSaturation:
        return PhosphorIcons.drop();
      case VitalSignType.temperature:
        return PhosphorIcons.thermometer();
      // case VitalSignType.glucose:
      //   return PhosphorIcons.pulse();
      default:
        return PhosphorIcons.question();
    }
  }

  Color get color {
    switch (this) {
      case VitalSignType.heartRate:
        return AppColors.heartRate;
      case VitalSignType.oxygenSaturation:
        return AppColors.oxygenSaturation;
      case VitalSignType.temperature:
        return AppColors.temperature;
      // case VitalSignType.glucose:
      //   return AppColors.glucose;
      default:
        return AppColors.textSecondary;
    }
  }
}
