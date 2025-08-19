import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/services/firebase_data_service.dart';
import '../../shared/models/vital_signs.dart';
import 'dart:async';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseDataService _firebaseDataService = FirebaseDataService();
  List<VitalSigns> _historicalData = [];
  VitalSignType _selectedVitalType = VitalSignType.heartRate;
  HistoryPeriod _selectedPeriod = HistoryPeriod.week;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeFirebaseDataService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeFirebaseDataService() async {
    await _firebaseDataService.initialize();
    await _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    setState(() => _isLoading = true);

    try {
      final days = _selectedPeriod == HistoryPeriod.week
          ? 7
          : _selectedPeriod == HistoryPeriod.month
              ? 30
              : 90;

      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      _historicalData = await _firebaseDataService.getHistoricalVitalSigns(
        startDate: startDate,
        endDate: endDate,
        limit: days * 12, // 12 readings per day
      );

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading historical data: $e');
      setState(() => _isLoading = false);
    }
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
            Tab(text: 'Insights'),
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
                _buildInsightsTab(),
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
    return Center(
      child: Text(
        'Trends Analysis - Coming Soon',
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return Center(
      child: Text(
        'Health Summary - Coming Soon',
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    return Center(
      child: Text(
        'Health Insights - Coming Soon',
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textSecondary,
        ),
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
          children: HistoryPeriod.values.map((period) {
            final isSelected = _selectedPeriod == period;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacingS),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedPeriod = period);
                    _loadHistoricalData();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.primary : AppColors.background,
                      borderRadius: AppTheme.mediumRadius,
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      period.displayName,
                      textAlign: TextAlign.center,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected
                            ? AppColors.textInverse
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
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
              final isSelected = _selectedVitalType == type;
              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacingS),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedVitalType = type),
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
      return _buildEmptyState();
    }

    final chartData = _getChartDataForVitalType(_selectedVitalType);

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
                    _selectedVitalType.displayName,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Last ${_selectedPeriod.displayName.toLowerCase()}',
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
                  color: _selectedVitalType.color.withValues(alpha: 0.1),
                  borderRadius: AppTheme.smallRadius,
                ),
                child: Text(
                  _getAverageValue(),
                  style: AppTypography.labelSmall.copyWith(
                    color: _selectedVitalType.color,
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
                    color: _selectedVitalType.color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: chartData.length <= 20,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: _selectedVitalType.color,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _selectedVitalType.color.withValues(alpha: 0.1),
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
            stats['average']!.toStringAsFixed(1),
            _selectedVitalType.unit,
            Icons.analytics,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _buildStatCard(
            'Highest',
            stats['max']!.toStringAsFixed(1),
            _selectedVitalType.unit,
            Icons.trending_up,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _buildStatCard(
            'Lowest',
            stats['min']!.toStringAsFixed(1),
            _selectedVitalType.unit,
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

  Widget _buildEmptyState() {
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
              'No Data Available',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Start monitoring your health to see trends and insights here.',
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
  List<FlSpot> _getChartDataForVitalType(VitalSignType type) {
    final data = <FlSpot>[];
    for (int i = 0; i < _historicalData.length; i++) {
      final vital = _historicalData[i];
      final value = _getValueForVitalType(type, vital);
      if (value != null) {
        data.add(FlSpot(i.toDouble(), value));
      }
    }
    return data;
  }

  double? _getValueForVitalType(VitalSignType type, VitalSigns vital) {
    switch (type) {
      case VitalSignType.heartRate:
        return vital.heartRate;
      case VitalSignType.oxygenSaturation:
        return vital.oxygenSaturation;
      case VitalSignType.temperature:
        return vital.temperature;
      case VitalSignType.glucose:
        return vital.glucose;
    }
  }

  Map<String, double> _calculateQuickStats() {
    final values = _historicalData
        .map((vital) => _getValueForVitalType(_selectedVitalType, vital))
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

  String _getAverageValue() {
    final stats = _calculateQuickStats();
    return '${stats['average']!.toStringAsFixed(1)} ${_selectedVitalType.unit}';
  }

  double _getGridInterval() {
    final stats = _calculateQuickStats();
    final range = stats['max']! - stats['min']!;
    return range / 5; // 5 grid lines
  }

  void _exportData() {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

// Enums and extensions
enum VitalSignType {
  heartRate,
  oxygenSaturation,
  temperature,
  glucose,
}

enum HistoryPeriod {
  week,
  month,
  quarter,
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
      case VitalSignType.glucose:
        return 'Glucose';
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
      case VitalSignType.glucose:
        return 'mg/dL';
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
      case VitalSignType.glucose:
        return PhosphorIcons.pulse();
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
      case VitalSignType.glucose:
        return AppColors.glucose;
    }
  }
}

extension HistoryPeriodExtension on HistoryPeriod {
  String get displayName {
    switch (this) {
      case HistoryPeriod.week:
        return 'Week';
      case HistoryPeriod.month:
        return 'Month';
      case HistoryPeriod.quarter:
        return '3 Months';
    }
  }
}
