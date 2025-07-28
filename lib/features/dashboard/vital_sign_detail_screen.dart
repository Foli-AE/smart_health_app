import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/vital_signs.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/widgets/vital_sign_card.dart';
import 'dart:async';

class VitalSignDetailScreen extends StatefulWidget {
  final String vitalType;
  final VitalSigns currentVitals;

  const VitalSignDetailScreen({
    super.key,
    required this.vitalType,
    required this.currentVitals,
  });

  @override
  State<VitalSignDetailScreen> createState() => _VitalSignDetailScreenState();
}

class _VitalSignDetailScreenState extends State<VitalSignDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final MockDataService _mockDataService = MockDataService();
  StreamSubscription<VitalSigns>? _vitalSignsSubscription;
  List<VitalSigns> _historicalData = [];
  late VitalSigns _currentVitals;
  bool _isLoading = true;
  String _selectedPeriod = '24H';

  @override
  void initState() {
    super.initState();
    _currentVitals = widget.currentVitals;
    _tabController = TabController(length: 4, vsync: this);
    _loadHistoricalData();
    _initializeDataStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vitalSignsSubscription?.cancel();
    super.dispose();
  }

  void _initializeDataStream() {
    _vitalSignsSubscription = _mockDataService.vitalSignsStream.listen(
      (vitalSigns) {
        if (mounted) {
          setState(() => _currentVitals = vitalSigns);
        }
      },
    );
  }

  Future<void> _loadHistoricalData() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final days = _selectedPeriod == '24H' ? 1 : _selectedPeriod == '7D' ? 7 : 30;
    _historicalData = _mockDataService.generateHistoricalData(
      days: days,
      readingsPerDay: _selectedPeriod == '24H' ? 24 : 12,
    );
    
    setState(() => _isLoading = false);
  }

  VitalSignConfig get _config => _getVitalConfig();
  
  VitalSignConfig _getVitalConfig() {
    switch (widget.vitalType.toLowerCase()) {
      case 'heart rate':
        return VitalSignConfig(
          name: 'Heart Rate',
          unit: 'BPM',
          icon: PhosphorIcons.heart(),
          color: AppColors.heartRate,
          normalRange: '60-100',
          optimalRange: '60-90',
          getValue: (vitals) => vitals.heartRate?.toDouble() ?? 0,
          tips: [
            'Stay hydrated and get adequate rest',
            'Practice deep breathing exercises',
            'Avoid excessive caffeine',
            'Regular gentle exercise helps maintain healthy heart rate',
          ],
          warningThreshold: 100,
          criticalThreshold: 120,
        );
      case 'oxygen saturation':
        return VitalSignConfig(
          name: 'Oxygen Saturation',
          unit: '%',
          icon: PhosphorIcons.drop(),
          color: AppColors.oxygenSaturation,
          normalRange: '95-100%',
          optimalRange: '98-100%',
          getValue: (vitals) => vitals.oxygenSaturation?.toDouble() ?? 0,
          tips: [
            'Practice deep breathing exercises',
            'Ensure good posture while resting',
            'Get fresh air when possible',
            'Report any breathing difficulties immediately',
          ],
          warningThreshold: 95,
          criticalThreshold: 90,
        );
      case 'temperature':
        return VitalSignConfig(
          name: 'Body Temperature',
          unit: '°C',
          icon: PhosphorIcons.thermometer(),
          color: AppColors.temperature,
          normalRange: '36.1-37.2°C',
          optimalRange: '36.5-37.0°C',
          getValue: (vitals) => vitals.temperature?.toDouble() ?? 0,
          tips: [
            'Stay hydrated with water',
            'Dress in comfortable, breathable clothing',
            'Rest in a well-ventilated room',
            'Contact doctor if fever persists',
          ],
          warningThreshold: 37.5,
          criticalThreshold: 38.5,
        );
      case 'blood pressure':
        return VitalSignConfig(
          name: 'Blood Pressure',
          unit: 'mmHg',
          icon: PhosphorIcons.heartbeat(),
          color: AppColors.bloodPressure,
          normalRange: '90-120/60-80',
          optimalRange: '100-110/65-75',
          getValue: (vitals) => vitals.systolicBP?.toDouble() ?? 0,
          tips: [
            'Limit sodium intake',
            'Practice relaxation techniques',
            'Maintain healthy weight',
            'Get adequate sleep and rest',
          ],
          warningThreshold: 140,
          criticalThreshold: 160,
        );
      case 'blood glucose':
        return VitalSignConfig(
          name: 'Blood Glucose',
          unit: 'mg/dL',
          icon: PhosphorIcons.testTube(),
          color: AppColors.glucose,
          normalRange: '70-140',
          optimalRange: '80-120',
          getValue: (vitals) => vitals.glucose?.toDouble() ?? 0,
          tips: [
            'Eat balanced meals regularly',
            'Monitor carbohydrate intake',
            'Stay physically active as recommended',
            'Follow your dietary plan',
          ],
          warningThreshold: 140,
          criticalThreshold: 180,
        );
      default:
        return VitalSignConfig(
          name: 'Unknown',
          unit: '',
          icon: PhosphorIcons.question(),
          color: AppColors.primary,
          normalRange: 'Unknown',
          optimalRange: 'Unknown',
          getValue: (vitals) => 0,
          tips: [],
          warningThreshold: 0,
          criticalThreshold: 0,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
        ],
        body: Column(
          children: [
            // Current Value Card
            _buildCurrentValueCard(),
            
            // Tab Bar
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Chart'),
                  Tab(text: 'Trends'),
                  Tab(text: 'Insights'),
                  Tab(text: 'Tips'),
                ],
                labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTypography.labelMedium,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChartTab(),
                  _buildTrendsTab(),
                  _buildInsightsTab(),
                  _buildTipsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: _config.color,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _config.name,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textInverse,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _config.color,
                _config.color.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(PhosphorIcons.arrowLeft(), color: AppColors.textInverse),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(PhosphorIcons.shareNetwork(), color: AppColors.textInverse),
          onPressed: () => _shareData(),
        ),
      ],
    );
  }

  Widget _buildCurrentValueCard() {
    final currentValue = _config.getValue(_currentVitals);
    final status = _getStatus(currentValue);
    
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.largeRadius,
        boxShadow: AppTheme.elevation2,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _config.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _config.icon,
              color: _config.color,
              size: 28,
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingM),
          
          // Value and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.vitalType.toLowerCase() == 'blood pressure' 
                          ? '${_currentVitals.systolicBP?.toInt()}/${_currentVitals.diastolicBP?.toInt()}'
                          : widget.vitalType.toLowerCase() == 'temperature'
                              ? currentValue.toStringAsFixed(1)
                              : currentValue.toInt().toString(),
                      style: AppTypography.displayMedium.copyWith(
                        color: _config.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      _config.unit,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingXs),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.displayName,
                    style: AppTypography.labelMedium.copyWith(
                      color: status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingXs),
                
                Text(
                  'Normal: ${_config.normalRange}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          
          // Trend Indicator
          _buildTrendIndicator(),
        ],
      ),
    ).animate().slideY(
      begin: -0.3,
      duration: const Duration(milliseconds: 600),
    );
  }

  Widget _buildChartTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: _config.color),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          _buildPeriodSelector(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Chart
          Container(
            height: 300,
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppTheme.mediumRadius,
              boxShadow: AppTheme.elevation1,
            ),
            child: _buildLineChart(),
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Statistics
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
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
          
          // Trend Cards
          _buildTrendCard('Today', '↗️ +2.3%', 'Slight increase from yesterday', AppColors.success),
          _buildTrendCard('This Week', '→ Stable', 'Consistent readings within normal range', AppColors.primary),
          _buildTrendCard('This Month', '↘️ -1.8%', 'Gradual improvement overall', AppColors.success),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Pattern Recognition
          _buildPatternSection(),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Insights',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Current Status Insight
          _buildInsightCard(
            'Current Status',
            _getStatusInsight(),
            _getStatus(_config.getValue(_currentVitals)).color,
            PhosphorIcons.lightbulb(),
          ),
          
          // Pregnancy Specific Insights
          _buildInsightCard(
            'Pregnancy Context',
            _getPregnancyInsight(),
            AppColors.primary,
            PhosphorIcons.baby(),
          ),
          
          // Recommendations
          _buildInsightCard(
            'Recommendations',
            _getRecommendations(),
            AppColors.secondary,
            PhosphorIcons.clipboardText(),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Tips',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // General Tips
          ..._config.tips.map((tip) => _buildTipCard(tip)),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // When to Contact Doctor
          _buildEmergencyCard(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: ['24H', '7D', '30D'].map((period) {
        final isSelected = _selectedPeriod == period;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedPeriod = period);
              _loadHistoricalData();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
              decoration: BoxDecoration(
                color: isSelected ? _config.color : AppColors.surface,
                borderRadius: AppTheme.smallRadius,
                border: Border.all(
                  color: isSelected ? _config.color : AppColors.border,
                ),
              ),
              child: Text(
                period,
                textAlign: TextAlign.center,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChart() {
    if (_historicalData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final spots = _historicalData.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = _config.getValue(entry.value);
      return FlSpot(index, value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getChartInterval(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _getChartInterval(),
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
              interval: spots.length > 10 ? spots.length / 5 : 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _historicalData.length) {
                  final time = _historicalData[value.toInt()].timestamp;
                  return Text(
                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _config.color,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _config.color.withValues(alpha: 0.3),
                  _config.color.withValues(alpha: 0.1),
                ],
              ),
            ),
            dotData: FlDotData(
              show: spots.length <= 20,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: _config.color,
                strokeWidth: 2,
                strokeColor: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    if (_historicalData.isEmpty) return const SizedBox();

    final values = _historicalData.map(_config.getValue).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(child: _buildStatCard('Average', avg.toStringAsFixed(1), AppColors.primary)),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(child: _buildStatCard('Minimum', min.toStringAsFixed(1), AppColors.success)),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(child: _buildStatCard('Maximum', max.toStringAsFixed(1), AppColors.warning)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppTheme.smallRadius,
      ),
      child: Column(
        children: [
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
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(String period, String trend, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
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
                Row(
                  children: [
                    Text(
                      period,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      trend,
                      style: AppTypography.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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

  Widget _buildPatternSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pattern Recognition',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        
        _buildPatternCard(
          'Daily Pattern',
          'Values tend to be higher in the afternoon',
          PhosphorIcons.clock(),
          AppColors.primary,
        ),
        
        _buildPatternCard(
          'Weekly Trend',
          'Stable readings throughout the week',
          PhosphorIcons.calendar(),
          AppColors.success,
        ),
      ],
    );
  }

  Widget _buildPatternCard(String title, String description, IconData icon, Color color) {
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

  Widget _buildInsightCard(String title, String content, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.elevation1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            content,
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.smallRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.checkCircle(),
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              tip,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppColors.critical.withValues(alpha: 0.1),
        borderRadius: AppTheme.mediumRadius,
        border: Border.all(color: AppColors.critical.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.warning(),
                color: AppColors.critical,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'When to Contact Your Doctor',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.critical,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            _getEmergencyGuidelines(),
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _callDoctor(),
              icon: Icon(PhosphorIcons.phone()),
              label: const Text('Call Doctor Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.critical,
                foregroundColor: AppColors.textInverse,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final trend = _calculateTrend();
    IconData icon;
    Color color;
    
    if (trend > 2) {
      icon = PhosphorIcons.trendUp();
      color = AppColors.warning;
    } else if (trend < -2) {
      icon = PhosphorIcons.trendDown();
      color = AppColors.success;
    } else {
      icon = PhosphorIcons.minus();
      color = AppColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // Helper Methods
  VitalSignStatus _getStatus(double value) {
    if (value >= _config.criticalThreshold) return VitalSignStatus.critical;
    if (value >= _config.warningThreshold) return VitalSignStatus.warning;
    return VitalSignStatus.optimal;
  }

  double _getChartInterval() {
    switch (widget.vitalType.toLowerCase()) {
      case 'heart rate': return 20;
      case 'oxygen saturation': return 5;
      case 'temperature': return 1;
      case 'blood pressure': return 20;
      case 'blood glucose': return 20;
      default: return 10;
    }
  }

  double _calculateTrend() {
    if (_historicalData.length < 2) return 0;
    
    final recent = _config.getValue(_historicalData.last);
    final previous = _config.getValue(_historicalData[_historicalData.length - 2]);
    
    return ((recent - previous) / previous) * 100;
  }

  String _getStatusInsight() {
    final status = _getStatus(_config.getValue(_currentVitals));
    switch (status) {
      case VitalSignStatus.optimal:
        return 'Your ${_config.name.toLowerCase()} is in the optimal range. This indicates excellent health status for your stage of pregnancy.';
      case VitalSignStatus.normal:
        return 'Your ${_config.name.toLowerCase()} is within normal limits. Continue monitoring as recommended.';
      case VitalSignStatus.warning:
        return 'Your ${_config.name.toLowerCase()} requires attention. Please follow up with your healthcare provider.';
      case VitalSignStatus.critical:
        return 'Your ${_config.name.toLowerCase()} is concerning. Contact your healthcare provider immediately.';
      default:
        return 'Unable to assess current status.';
    }
  }

  String _getPregnancyInsight() {
    switch (widget.vitalType.toLowerCase()) {
      case 'heart rate':
        return 'During pregnancy, your heart rate may be 10-20 BPM higher than normal due to increased blood volume and cardiac output.';
      case 'blood pressure':
        return 'Blood pressure typically decreases in the second trimester and gradually returns to pre-pregnancy levels in the third trimester.';
      case 'temperature':
        return 'Slight temperature elevation can be normal during pregnancy due to hormonal changes and increased metabolism.';
      default:
        return 'This vital sign is important for monitoring your health and your baby\'s well-being throughout pregnancy.';
    }
  }

  String _getRecommendations() {
    final status = _getStatus(_config.getValue(_currentVitals));
    switch (status) {
      case VitalSignStatus.optimal:
        return 'Continue your current lifestyle habits. Maintain regular prenatal appointments and follow your healthcare provider\'s guidance.';
      case VitalSignStatus.warning:
        return 'Consider lifestyle modifications and more frequent monitoring. Schedule a check-up with your healthcare provider within the next few days.';
      case VitalSignStatus.critical:
        return 'Immediate medical evaluation is recommended. Contact your healthcare provider or seek emergency care if symptoms worsen.';
      default:
        return 'Follow your healthcare provider\'s recommendations for monitoring and care.';
    }
  }

  String _getEmergencyGuidelines() {
    switch (widget.vitalType.toLowerCase()) {
      case 'heart rate':
        return 'Contact your doctor if heart rate is consistently above 120 BPM or below 50 BPM, especially with symptoms like dizziness, chest pain, or shortness of breath.';
      case 'blood pressure':
        return 'Seek immediate care if systolic pressure is above 160 or diastolic above 110, especially with headache, vision changes, or upper abdominal pain.';
      case 'temperature':
        return 'Contact your doctor if temperature is above 38.5°C (101.3°F) or if you have persistent fever with other symptoms.';
      case 'oxygen saturation':
        return 'Seek immediate care if oxygen saturation falls below 95% or if you experience difficulty breathing.';
      default:
        return 'Contact your healthcare provider if you have concerns about any changes in your vital signs.';
    }
  }

  void _shareData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${_config.name} data...'),
        backgroundColor: _config.color,
      ),
    );
  }

  void _callDoctor() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Calling your healthcare provider...'),
        backgroundColor: AppColors.critical,
        action: SnackBarAction(
          label: 'Cancel',
          textColor: AppColors.textInverse,
          onPressed: () {},
        ),
      ),
    );
  }
}

// Configuration class for vital signs
class VitalSignConfig {
  final String name;
  final String unit;
  final IconData icon;
  final Color color;
  final String normalRange;
  final String optimalRange;
  final double Function(VitalSigns) getValue;
  final List<String> tips;
  final double warningThreshold;
  final double criticalThreshold;

  const VitalSignConfig({
    required this.name,
    required this.unit,
    required this.icon,
    required this.color,
    required this.normalRange,
    required this.optimalRange,
    required this.getValue,
    required this.tips,
    required this.warningThreshold,
    required this.criticalThreshold,
  });
} 