import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/vital_signs.dart';
import '../models/alert.dart';
import '../models/doctor_contact.dart';
import '../models/health_recommendation.dart';
import '../models/pregnancy_timeline.dart';

/// Mock Data Service for generating realistic vital signs data
/// This service simulates real wearable device data for demonstration
class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  final Random _random = Random();
  late StreamController<VitalSigns> _vitalSignsController;
  late Timer _dataTimer;
  bool _isGenerating = false;

  // Base values for a healthy pregnant woman (28 weeks)
  static const double _baseHeartRate = 85.0;
  static const double _baseOxygenSaturation = 98.0;
  static const double _baseTemperature = 36.8;
  static const double _baseSystolicBP = 115.0;
  static const double _baseDiastolicBP = 72.0;
  static const double _baseGlucose = 90.0;

  // Variation ranges for realistic fluctuations
  static const double _heartRateVariation = 15.0;
  static const double _oxygenVariation = 2.0;
  static const double _temperatureVariation = 0.8;
  static const double _bloodPressureVariation = 12.0;
  static const double _glucoseVariation = 25.0;

  /// Get stream of real-time vital signs
  Stream<VitalSigns> get vitalSignsStream {
    if (!_isGenerating) {
      startGenerating();
    }
    return _vitalSignsController.stream;
  }

  /// Start generating mock data
  void startGenerating() {
    if (_isGenerating) return;
    
    _vitalSignsController = StreamController<VitalSigns>.broadcast();
    _isGenerating = true;

    // Generate data every 5 seconds (simulating device readings)
    _dataTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final vitalSigns = _generateRealisticVitalSigns();
      _vitalSignsController.add(vitalSigns);
    });

    // Send initial data immediately
    _vitalSignsController.add(_generateRealisticVitalSigns());
  }

  /// Stop generating mock data
  void stopGenerating() {
    if (!_isGenerating) return;
    
    _dataTimer.cancel();
    _vitalSignsController.close();
    _isGenerating = false;
  }

  /// Generate realistic vital signs with natural variations
  VitalSigns _generateRealisticVitalSigns() {
    final now = DateTime.now();
    
    // Time-based variations (higher heart rate during day, lower at night)
    final hourOfDay = now.hour;
    final isNightTime = hourOfDay < 6 || hourOfDay > 22;
    final isDayTime = hourOfDay >= 10 && hourOfDay <= 16;
    
    // Circadian rhythm adjustments
    double heartRateAdjustment = 0;
    double temperatureAdjustment = 0;
    
    if (isNightTime) {
      heartRateAdjustment = -8.0; // Lower heart rate at night
      temperatureAdjustment = -0.3; // Slightly lower temperature
    } else if (isDayTime) {
      heartRateAdjustment = 5.0; // Slightly higher during active hours
      temperatureAdjustment = 0.2;
    }

    // Generate values with realistic variations
    final heartRate = _generateValue(
      _baseHeartRate + heartRateAdjustment,
      _heartRateVariation,
      min: 60.0,
      max: 120.0,
    );

    final oxygenSaturation = _generateValue(
      _baseOxygenSaturation,
      _oxygenVariation,
      min: 95.0,
      max: 100.0,
    );

    final temperature = _generateValue(
      _baseTemperature + temperatureAdjustment,
      _temperatureVariation,
      min: 35.5,
      max: 38.0,
    );

    final systolicBP = _generateValue(
      _baseSystolicBP,
      _bloodPressureVariation,
      min: 90.0,
      max: 140.0,
    );

    final diastolicBP = _generateValue(
      _baseDiastolicBP,
      _bloodPressureVariation,
      min: 60.0,
      max: 90.0,
    );

    final glucose = _generateValue(
      _baseGlucose,
      _glucoseVariation,
      min: 70.0,
      max: 140.0,
    );

    return VitalSigns(
      id: 'mock-${now.millisecondsSinceEpoch}',
      timestamp: now,
      heartRate: heartRate,
      oxygenSaturation: oxygenSaturation,
      temperature: temperature,
      systolicBP: systolicBP,
      diastolicBP: diastolicBP,
      glucose: glucose,
      source: 'mock_device',
      isSynced: false,
    );
  }

  /// Generate historical data for charts and trends
  List<VitalSigns> generateHistoricalData({
    int days = 7,
    int readingsPerDay = 24,
  }) {
    final data = <VitalSigns>[];
    final now = DateTime.now();

    for (int day = days; day >= 0; day--) {
      for (int hour = 0; hour < readingsPerDay; hour++) {
        final timestamp = now.subtract(
          Duration(
            days: day,
            hours: readingsPerDay - hour - 1,
          ),
        );

        // Simulate some trends over the week
        final dayProgress = (days - day) / days;
        final trendAdjustment = dayProgress * 2; // Slight upward trend

        final heartRate = _generateValue(
          _baseHeartRate + trendAdjustment,
          _heartRateVariation * 0.8, // Less variation in historical data
          min: 60.0,
          max: 120.0,
        );

        final oxygenSaturation = _generateValue(
          _baseOxygenSaturation,
          _oxygenVariation * 0.6,
          min: 95.0,
          max: 100.0,
        );

        final temperature = _generateValue(
          _baseTemperature,
          _temperatureVariation * 0.7,
          min: 35.5,
          max: 38.0,
        );

        final systolicBP = _generateValue(
          _baseSystolicBP + trendAdjustment,
          _bloodPressureVariation * 0.8,
          min: 90.0,
          max: 140.0,
        );

        final diastolicBP = _generateValue(
          _baseDiastolicBP + (trendAdjustment * 0.6),
          _bloodPressureVariation * 0.8,
          min: 60.0,
          max: 90.0,
        );

        final glucose = _generateValue(
          _baseGlucose,
          _glucoseVariation * 0.9,
          min: 70.0,
          max: 140.0,
        );

        data.add(VitalSigns(
          id: 'historical-${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          heartRate: heartRate,
          oxygenSaturation: oxygenSaturation,
          temperature: temperature,
          systolicBP: systolicBP,
          diastolicBP: diastolicBP,
          glucose: glucose,
          source: 'mock_device',
          isSynced: true,
        ));
      }
    }

    return data;
  }

  /// Generate emergency scenario data (for testing alerts)
  VitalSigns generateEmergencyScenario(EmergencyType type) {
    final now = DateTime.now();
    
    switch (type) {
      case EmergencyType.highBloodPressure:
        return VitalSigns(
          id: 'emergency-${now.millisecondsSinceEpoch}',
          timestamp: now,
          heartRate: 95.0,
          oxygenSaturation: 97.0,
          temperature: 37.1,
          systolicBP: 165.0, // Dangerously high
          diastolicBP: 105.0, // Dangerously high
          glucose: 88.0,
          source: 'mock_device',
        );
      
      case EmergencyType.lowOxygen:
        return VitalSigns(
          id: 'emergency-${now.millisecondsSinceEpoch}',
          timestamp: now,
          heartRate: 110.0,
          oxygenSaturation: 88.0, // Dangerously low
          temperature: 36.9,
          systolicBP: 125.0,
          diastolicBP: 78.0,
          glucose: 92.0,
          source: 'mock_device',
        );
      
      case EmergencyType.highHeartRate:
        return VitalSigns(
          id: 'emergency-${now.millisecondsSinceEpoch}',
          timestamp: now,
          heartRate: 145.0, // Dangerously high
          oxygenSaturation: 96.0,
          temperature: 37.8,
          systolicBP: 135.0,
          diastolicBP: 85.0,
          glucose: 95.0,
          source: 'mock_device',
        );
      
      case EmergencyType.fever:
        return VitalSigns(
          id: 'emergency-${now.millisecondsSinceEpoch}',
          timestamp: now,
          heartRate: 105.0,
          oxygenSaturation: 97.0,
          temperature: 39.2, // High fever
          systolicBP: 120.0,
          diastolicBP: 75.0,
          glucose: 98.0,
          source: 'mock_device',
        );
    }
  }

  /// Helper method to generate values with natural variation
  double _generateValue(
    double base,
    double variation, {
    required double min,
    required double max,
  }) {
    // Use normal distribution for more realistic variations
    final normalValue = _generateNormalDistribution() * variation + base;
    return normalValue.clamp(min, max);
  }

  /// Generate normally distributed random values (Box-Muller transform)
  double _generateNormalDistribution() {
    double u = 0, v = 0;
    while (u == 0) {
      u = _random.nextDouble(); // Converting [0,1) to (0,1)
    }
    while (v == 0) {
      v = _random.nextDouble();
    }
    return sqrt(-2.0 * log(u)) * cos(2 * pi * v);
  }

  /// Generate alert history with realistic notifications
  List<Alert> generateAlertHistory({int days = 30}) {
    final alerts = <Alert>[];
    final now = DateTime.now();
    final random = Random();

    // Generate alerts over the past 30 days
    for (int i = 0; i < days; i++) {
      final alertDate = now.subtract(Duration(days: i));
      
      // Simulate occasional alerts (not every day)
      if (random.nextDouble() < 0.3) { // 30% chance of alert per day
        final alertTypes = [
          (AlertType.vitalSigns, AlertSeverity.info, 'Blood pressure reading recorded', 'Your blood pressure of 118/75 mmHg is within normal range.'),
          (AlertType.recommendation, AlertSeverity.info, 'Daily hydration reminder', 'Don\'t forget to drink plenty of water today. Aim for 8-10 glasses.'),
          (AlertType.achievement, AlertSeverity.info, 'Weekly milestone reached', 'Congratulations! You\'ve completed another healthy week of pregnancy.'),
          (AlertType.appointment, AlertSeverity.warning, 'Upcoming appointment', 'Your prenatal checkup is scheduled for tomorrow at 2:00 PM.'),
          (AlertType.vitalSigns, AlertSeverity.warning, 'Heart rate slightly elevated', 'Your heart rate was 105 bpm. Consider resting and monitoring.'),
        ];

        final alertData = alertTypes[random.nextInt(alertTypes.length)];
        
        alerts.add(Alert(
          id: 'alert-${alertDate.millisecondsSinceEpoch}',
          timestamp: alertDate,
          type: alertData.$1,
          severity: alertData.$2,
          title: alertData.$3,
          message: alertData.$4,
          isRead: i > 3, // Recent alerts are unread
          actionText: alertData.$2 == AlertSeverity.warning ? 'View Details' : null,
        ));
      }
    }

    // Add a few critical alerts for demonstration
    alerts.addAll([
      Alert(
        id: 'critical-alert-1',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: AlertType.emergency,
        severity: AlertSeverity.critical,
        title: 'Blood pressure spike detected',
        message: 'Your blood pressure reading of 150/95 mmHg is concerning. Please contact your healthcare provider.',
        actionText: 'Call Doctor',
        isRead: false,
      ),
      Alert(
        id: 'system-alert-1',
        timestamp: now.subtract(const Duration(days: 1)),
        type: AlertType.system,
        severity: AlertSeverity.info,
        title: 'Device connected successfully',
        message: 'Your wearable device is now connected and monitoring your vital signs.',
        isRead: true,
      ),
    ]);

    // Sort by timestamp (newest first)
    alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return alerts;
  }

  /// Generate doctor contacts and emergency contacts
  List<DoctorContact> generateDoctorContacts() {
    return [
      // Primary Obstetrician
      const DoctorContact(
        id: 'dr-mensah-001',
        name: 'Dr. Akosua Mensah',
        title: 'Dr.',
        specialization: 'Obstetrics & Gynecology',
        hospital: 'Ridge Hospital, Accra',
        phoneNumber: '+233 24 123 4567',
        email: 'akosua.mensah@ridgehospital.gh',
        address: 'Ridge Hospital, Ring Road Central, Accra',
        type: ContactType.obstetrician,
        isEmergencyContact: true,
        isAvailable: true,
        rating: 4.8,
        yearsExperience: 15,
        languages: ['English', 'Akan', 'Ewe'],
        workingHours: WorkingHours(
          mondayStart: TimeOfDay(hour: 8, minute: 0),
          mondayEnd: TimeOfDay(hour: 17, minute: 0),
          tuesdayStart: TimeOfDay(hour: 8, minute: 0),
          tuesdayEnd: TimeOfDay(hour: 17, minute: 0),
          wednesdayStart: TimeOfDay(hour: 8, minute: 0),
          wednesdayEnd: TimeOfDay(hour: 17, minute: 0),
          thursdayStart: TimeOfDay(hour: 8, minute: 0),
          thursdayEnd: TimeOfDay(hour: 17, minute: 0),
          fridayStart: TimeOfDay(hour: 8, minute: 0),
          fridayEnd: TimeOfDay(hour: 15, minute: 0),
        ),
      ),
      
      // Midwife
      const DoctorContact(
        id: 'midwife-001',
        name: 'Grace Asante',
        title: 'Midwife',
        specialization: 'Maternal Care',
        hospital: 'Ridge Hospital, Accra',
        phoneNumber: '+233 24 234 5678',
        email: 'grace.asante@ridgehospital.gh',
        type: ContactType.midwife,
        isEmergencyContact: true,
        isAvailable: true,
        rating: 4.9,
        yearsExperience: 12,
        languages: ['English', 'Akan'],
        workingHours: WorkingHours(
          isOnCall24h: true,
        ),
      ),

      // Emergency Contact
      const DoctorContact(
        id: 'emergency-001',
        name: 'Ghana Emergency Services',
        title: 'Emergency',
        specialization: 'Emergency Medicine',
        phoneNumber: '999',
        type: ContactType.emergency,
        isEmergencyContact: true,
        isAvailable: true,
        workingHours: WorkingHours(
          isOnCall24h: true,
        ),
      ),

      // Family Contact
      const DoctorContact(
        id: 'family-001',
        name: 'Kwame Mensah',
        title: 'Husband',
        specialization: 'Family Support',
        phoneNumber: '+233 24 345 6789',
        type: ContactType.familyMember,
        isEmergencyContact: true,
        isAvailable: true,
      ),

      // General Doctor
      const DoctorContact(
        id: 'dr-boateng-001',
        name: 'Dr. Samuel Boateng',
        title: 'Dr.',
        specialization: 'General Medicine',
        hospital: 'Korle-Bu Teaching Hospital',
        phoneNumber: '+233 24 456 7890',
        email: 'samuel.boateng@korlebu.gh',
        type: ContactType.generalDoctor,
        isAvailable: true,
        rating: 4.6,
        yearsExperience: 10,
        languages: ['English', 'Akan'],
      ),
    ];
  }

  /// Generate personalized health recommendations
  List<HealthRecommendation> generateHealthRecommendations() {
    final now = DateTime.now();
    
    return [
      HealthRecommendation(
        id: 'rec-nutrition-001',
        title: 'Increase Iron-Rich Foods',
        description: 'Based on your recent blood work, consider adding more iron-rich foods like spinach, lean meat, and lentils to prevent anemia during pregnancy.',
        type: RecommendationType.nutrition,
        priority: RecommendationPriority.high,
        createdAt: now.subtract(const Duration(hours: 2)),
        actionText: 'View Iron-Rich Foods',
        tags: ['anemia', 'nutrition', 'iron'],
      ),
      
      HealthRecommendation(
        id: 'rec-exercise-001',
        title: 'Daily Pregnancy Yoga',
        description: '10-15 minutes of gentle prenatal yoga can help reduce back pain and improve flexibility. Perfect for your current trimester.',
        type: RecommendationType.exercise,
        priority: RecommendationPriority.medium,
        createdAt: now.subtract(const Duration(days: 1)),
        actionText: 'Start Yoga Session',
        tags: ['exercise', 'yoga', 'flexibility'],
      ),

      HealthRecommendation(
        id: 'rec-hydration-001',
        title: 'Optimal Hydration Goals',
        description: 'Aim for 8-10 glasses of water daily. Proper hydration helps prevent constipation and supports increased blood volume.',
        type: RecommendationType.hydration,
        priority: RecommendationPriority.medium,
        createdAt: now.subtract(const Duration(days: 2)),
        actionText: 'Set Water Reminder',
        tags: ['hydration', 'water', 'health'],
      ),

      HealthRecommendation(
        id: 'rec-rest-001',
        title: 'Sleep Position Guidance',
        description: 'Sleeping on your left side improves blood flow to your baby. Use a pregnancy pillow for extra comfort.',
        type: RecommendationType.rest,
        priority: RecommendationPriority.low,
        createdAt: now.subtract(const Duration(days: 3)),
        actionText: 'Learn More',
        tags: ['sleep', 'position', 'comfort'],
      ),

      HealthRecommendation(
        id: 'rec-appointment-001',
        title: 'Schedule Glucose Screening',
        description: 'You\'re approaching 24-28 weeks. Time to schedule your glucose screening test to check for gestational diabetes.',
        type: RecommendationType.appointment,
        priority: RecommendationPriority.high,
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 7)),
        actionText: 'Book Appointment',
        tags: ['glucose', 'screening', 'diabetes'],
      ),

      HealthRecommendation(
        id: 'rec-education-001',
        title: 'Preparing for Labor',
        description: 'Consider enrolling in childbirth classes. Understanding the labor process can help reduce anxiety and prepare you for delivery.',
        type: RecommendationType.education,
        priority: RecommendationPriority.medium,
        createdAt: now.subtract(const Duration(days: 5)),
        actionText: 'Find Classes',
        tags: ['education', 'labor', 'preparation'],
      ),
    ];
  }

  /// Generate pregnancy timeline with milestones
  PregnancyTimeline generatePregnancyTimeline() {
    final now = DateTime.now();
    final lmp = DateTime(2024, 3, 15); // Last menstrual period
    final edd = lmp.add(const Duration(days: 280)); // Estimated due date (40 weeks)
    
    // Calculate current week
    final daysSinceLmp = now.difference(lmp).inDays;
    final currentWeek = (daysSinceLmp / 7).floor();
    final currentDay = daysSinceLmp % 7;
    
    // Determine trimester
    PregnancyTrimester trimester;
    if (currentWeek <= 12) {
      trimester = PregnancyTrimester.first;
    } else if (currentWeek <= 26) {
      trimester = PregnancyTrimester.second;
    } else {
      trimester = PregnancyTrimester.third;
    }

    // Baby size data for week 28
    final babySizes = {
      28: ('Eggplant', 'Size of an eggplant', 1000.0, 25.0),
      29: ('Butternut Squash', 'Size of a butternut squash', 1150.0, 26.0),
      30: ('Cabbage', 'Size of a cabbage', 1300.0, 27.0),
    };
    
    final sizeData = babySizes[currentWeek] ?? babySizes[28]!;

    return PregnancyTimeline(
      id: 'timeline-001',
      lastMenstrualPeriod: lmp,
      estimatedDueDate: edd,
      currentWeek: currentWeek,
      currentDay: currentDay,
      currentTrimester: trimester,
      babySize: sizeData.$1,
      babySizeComparison: sizeData.$2,
      estimatedBabyWeight: sizeData.$3,
      estimatedBabyLength: sizeData.$4,
      milestones: _generateMilestones(currentWeek),
      weeklyUpdates: _generateWeeklyUpdates(),
    );
  }

  /// Generate milestone data
  List<PregnancyMilestone> _generateMilestones(int currentWeek) {
    final milestones = <PregnancyMilestone>[
      PregnancyMilestone(
        id: 'milestone-001',
        week: 8,
        title: 'First Prenatal Appointment',
        description: 'Initial checkup with your healthcare provider',
        type: MilestoneType.appointment,
        isCompleted: currentWeek > 8,
        completedAt: currentWeek > 8 ? DateTime.now().subtract(Duration(days: (currentWeek - 8) * 7)) : null,
      ),
      
      PregnancyMilestone(
        id: 'milestone-002',
        week: 12,
        title: 'First Trimester Screening',
        description: 'Blood tests and ultrasound to assess baby\'s health',
        type: MilestoneType.test,
        isCompleted: currentWeek > 12,
        completedAt: currentWeek > 12 ? DateTime.now().subtract(Duration(days: (currentWeek - 12) * 7)) : null,
      ),

      PregnancyMilestone(
        id: 'milestone-003',
        week: 16,
        title: 'Anatomy Scan',
        description: 'Detailed ultrasound to check baby\'s development',
        type: MilestoneType.test,
        isCompleted: currentWeek > 16,
        completedAt: currentWeek > 16 ? DateTime.now().subtract(Duration(days: (currentWeek - 16) * 7)) : null,
      ),

      PregnancyMilestone(
        id: 'milestone-004',
        week: 20,
        title: 'Feeling Baby\'s Movements',
        description: 'You may start feeling your baby\'s first movements',
        type: MilestoneType.development,
        isCompleted: currentWeek > 20,
        completedAt: currentWeek > 20 ? DateTime.now().subtract(Duration(days: (currentWeek - 20) * 7)) : null,
      ),

      PregnancyMilestone(
        id: 'milestone-005',
        week: 24,
        title: 'Glucose Screening Test',
        description: 'Test for gestational diabetes',
        type: MilestoneType.test,
        isCompleted: currentWeek > 24,
        completedAt: currentWeek > 24 ? DateTime.now().subtract(Duration(days: (currentWeek - 24) * 7)) : null,
      ),

      PregnancyMilestone(
        id: 'milestone-006',
        week: 28,
        title: 'Third Trimester Begins',
        description: 'Welcome to your third trimester!',
        type: MilestoneType.development,
        isCompleted: currentWeek >= 28,
        completedAt: currentWeek >= 28 ? DateTime.now().subtract(Duration(days: (currentWeek - 28) * 7)) : null,
      ),

      const PregnancyMilestone(
        id: 'milestone-007',
        week: 32,
        title: 'Hospital Bag Preparation',
        description: 'Start preparing your hospital bag for delivery',
        type: MilestoneType.preparation,
        isCompleted: false,
      ),

      const PregnancyMilestone(
        id: 'milestone-008',
        week: 36,
        title: 'Baby is Full Term',
        description: 'Your baby is considered full term and ready for birth',
        type: MilestoneType.development,
        isCompleted: false,
      ),
    ];

    return milestones;
  }

  /// Generate weekly pregnancy updates
  List<WeeklyUpdate> _generateWeeklyUpdates() {
    return [
      const WeeklyUpdate(
        id: 'week-28',
        week: 28,
        title: 'Your Baby is Growing Strong',
        motherChanges: 'You may notice increased fatigue and some difficulty sleeping. Your belly is growing more noticeable, and you might experience mild back pain.',
        babyDevelopment: 'Your baby\'s eyes can now open and close, and they\'re developing fat layers under their skin. Their brain is developing rapidly.',
        tips: [
          'Sleep on your left side to improve blood flow',
          'Stay hydrated and eat iron-rich foods',
          'Consider prenatal yoga for back pain relief',
          'Schedule your glucose screening test'
        ],
        symptoms: [
          'Increased fatigue',
          'Mild back pain',
          'Difficulty sleeping',
          'Leg cramps'
        ],
        appointments: [
          'Glucose screening test (24-28 weeks)',
          'Regular prenatal checkup'
        ],
      ),
      
      const WeeklyUpdate(
        id: 'week-29',
        week: 29,
        title: 'Preparing for the Third Trimester',
        motherChanges: 'Your uterus is expanding, which may cause some shortness of breath. You might also notice more frequent urination.',
        babyDevelopment: 'Your baby\'s bones are hardening, and their movements are becoming more pronounced. They\'re practicing breathing movements.',
        tips: [
          'Practice deep breathing exercises',
          'Eat smaller, more frequent meals',
          'Start thinking about birth preferences',
          'Consider childbirth classes'
        ],
        symptoms: [
          'Shortness of breath',
          'Frequent urination',
          'Heartburn',
          'Swollen feet'
        ],
        appointments: [
          'Monthly prenatal checkup',
          'Blood pressure monitoring'
        ],
      ),
    ];
  }

  /// Dispose resources
  void dispose() {
    stopGenerating();
  }
}

/// Emergency scenarios for testing
enum EmergencyType {
  highBloodPressure,
  lowOxygen,
  highHeartRate,
  fever,
} 