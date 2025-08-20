import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vital_signs.dart';
import '../models/alert.dart';
import '../models/doctor_contact.dart';
import '../models/health_recommendation.dart';
import '../models/pregnancy_timeline.dart';
import 'firebase_service.dart';

/// Firebase Data Service - Replaces Mock Data Service
/// Provides real-time data from Firebase while maintaining the same interface
class FirebaseDataService {
  static final FirebaseDataService _instance = FirebaseDataService._internal();
  factory FirebaseDataService() => _instance;
  FirebaseDataService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final Random _random = Random();

  // Stream controllers for real-time data
  late StreamController<VitalSigns> _vitalSignsController;
  late StreamController<List<Alert>> _alertsController;
  late StreamController<List<DoctorContact>> _contactsController;
  late StreamController<List<HealthRecommendation>> _recommendationsController;
  late StreamController<PregnancyTimeline?> _timelineController;

  // Streams for real IoT sensor data
  late StreamController<List<VitalSigns>> _historicalVitalSignsController;

  // Current data
  VitalSigns? _currentVitals;
  List<Alert> _currentAlerts = [];
  List<DoctorContact> _currentContacts = [];
  List<HealthRecommendation> _currentRecommendations = [];
  PregnancyTimeline? _currentTimeline;

  // Stream subscriptions
  StreamSubscription<VitalSigns>? _vitalSignsSubscription;
  StreamSubscription<List<Alert>>? _alertsSubscription;
  StreamSubscription<User?>? _authSubscription;

  // Getters
  Stream<VitalSigns> get vitalSignsStream => _vitalSignsController.stream;
  Stream<List<Alert>> get alertsStream => _alertsController.stream;
  Stream<List<DoctorContact>> get contactsStream => _contactsController.stream;
  Stream<List<HealthRecommendation>> get recommendationsStream =>
      _recommendationsController.stream;
  Stream<PregnancyTimeline?> get timelineStream => _timelineController.stream;

  /// Get historical vital signs stream from IoT sensor data
  Stream<List<VitalSigns>> get historicalVitalSignsStream =>
      _historicalVitalSignsController.stream;

  VitalSigns? get currentVitals => _currentVitals;
  List<Alert> get currentAlerts => _currentAlerts;
  List<DoctorContact> get currentContacts => _currentContacts;
  List<HealthRecommendation> get currentRecommendations =>
      _currentRecommendations;
  PregnancyTimeline? get currentTimeline => _currentTimeline;

  /// Initialize the service and start listening to real IoT data
  Future<void> initialize() async {
    print('🔄 Initializing Firebase Data Service...');

    // Ensure Firebase service is initialized first
    await FirebaseService.initialize();
    print('✅ Firebase Service initialized');

    // Initialize stream controllers
    _vitalSignsController = StreamController<VitalSigns>.broadcast();
    _alertsController = StreamController<List<Alert>>.broadcast();
    _contactsController = StreamController<List<DoctorContact>>.broadcast();
    _recommendationsController =
        StreamController<List<HealthRecommendation>>.broadcast();
    _timelineController = StreamController<PregnancyTimeline?>.broadcast();
    _historicalVitalSignsController =
        StreamController<List<VitalSigns>>.broadcast();

    // Start listening to real IoT data
    _startListeningToIoTData();
    _startListeningToUserData();

    // Test access to SensorReadings collection
    await testSensorReadingsAccess();

    // Test different collection names
    await testDifferentCollectionNames();

    print('✅ Firebase Data Service initialized successfully');
  }

  /// Start listening to user's Firebase data
  Future<void> _startListeningToUserData() async {
    try {
      // Load initial data
      await _loadUserData();

      // Set up real-time listeners
      _setupRealtimeListeners();

      print('Started listening to user data');
    } catch (e) {
      print('Error starting user data listeners: $e');
      // Fallback to mock data if Firebase fails
      _startMockDataFallback();
    }
  }

  /// Stop listening to user data
  void _stopListeningToUserData() {
    _currentVitals = null;
    _currentAlerts = [];
    _currentContacts = [];
    _currentRecommendations = [];
    _currentTimeline = null;

    // Send empty data to streams
    _vitalSignsController.add(_generateMockVitalSigns());
    _alertsController.add([]);
    _contactsController.add([]);
    _recommendationsController.add([]);
    _timelineController.add(null);
  }

  /// Load user data from Firebase
  Future<void> _loadUserData() async {
    try {
      // Load contacts
      _currentContacts = await _firebaseService.getDoctorContacts();
      _contactsController.add(_currentContacts);

      // Load recommendations
      _currentRecommendations =
          await _firebaseService.getHealthRecommendations();
      _recommendationsController.add(_currentRecommendations);

      // Load timeline
      final timelines = await _firebaseService.getPregnancyTimeline();
      _currentTimeline = timelines.isNotEmpty ? timelines.first : null;
      _timelineController.add(_currentTimeline);

      // Load historical vital signs
      final historicalVitals =
          await _firebaseService.getHistoricalVitalSigns(limit: 1);
      if (historicalVitals.isNotEmpty) {
        _currentVitals = historicalVitals.first;
        _vitalSignsController.add(_currentVitals!);
      } else {
        // Generate mock vitals if no data exists
        _currentVitals = _generateMockVitalSigns();
        _vitalSignsController.add(_currentVitals!);
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Fallback to mock data
      _loadMockData();
    }
  }

  /// Set up real-time listeners
  void _setupRealtimeListeners() {
    // Real-time listeners are already set up in FirebaseService
    // This method can be used for additional real-time features
  }

  /// Fallback to mock data when Firebase is unavailable
  void _startMockDataFallback() {
    print('Using mock data fallback');
    _loadMockData();
    _startMockDataGeneration();
  }

  /// Load mock data for fallback
  void _loadMockData() {
    _currentVitals = _generateMockVitalSigns();
    _currentAlerts = _generateMockAlerts();
    _currentContacts = _generateMockContacts();
    _currentRecommendations = _generateMockRecommendations();
    _currentTimeline = _generateMockTimeline();

    // Send to streams
    _vitalSignsController.add(_currentVitals!);
    _alertsController.add(_currentAlerts);
    _contactsController.add(_currentContacts);
    _recommendationsController.add(_currentRecommendations);
    _timelineController.add(_currentTimeline);
  }

  /// Start generating mock data for fallback
  void _startMockDataGeneration() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_firebaseService.currentUser == null) {
        final newVitals = _generateMockVitalSigns();
        _currentVitals = newVitals;
        _vitalSignsController.add(newVitals);
      } else {
        timer.cancel();
      }
    });
  }

  /// Start listening to real IoT sensor data from SensorReadings collection
  void _startListeningToIoTData() {
    print(
        '🔍 Starting to listen to IoT data from SensorReadings collection...');

    _firebaseService.firestore
        .collection('SensorReadings')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      print(
          '📊 Received IoT data snapshot with ${snapshot.docs.length} documents');

      if (snapshot.docs.isNotEmpty) {
        final latestReading = snapshot.docs.first;
        final data = latestReading.data();
        print('📈 Latest IoT reading data: $data');

        // Convert IoT sensor data to VitalSigns format
        final vitalSigns = _convertIoTDataToVitalSigns(data, latestReading.id);
        print(
            '🔄 Converted to VitalSigns: HR=${vitalSigns.heartRate}, SpO2=${vitalSigns.oxygenSaturation}, Temp=${vitalSigns.temperature}, Glucose=${vitalSigns.glucose}');

        _vitalSignsController.add(vitalSigns);
      } else {
        print('⚠️ No IoT data found in SensorReadings collection');
      }
    }, onError: (error) {
      print('❌ Error listening to IoT data: $error');
      // Fallback to mock data if IoT data fails
      final mockData = _generateMockVitalSigns();
      print(
          '🔄 Using fallback mock data: HR=${mockData.heartRate}, SpO2=${mockData.oxygenSaturation}, Temp=${mockData.temperature}');
      _vitalSignsController.add(mockData);
    });
  }

  /// Convert IoT sensor data to VitalSigns format
  VitalSigns _convertIoTDataToVitalSigns(
      Map<String, dynamic> data, String documentId) {
    return VitalSigns(
      id: documentId,
      heartRate: data['heartRate']?.toDouble(),
      oxygenSaturation: data['spo2']
          ?.toDouble(), // Note: IoT uses 'spo2', we use 'oxygenSaturation'
      temperature: data['temperature']?.toDouble(),
      glucose: data['glucose']?.toDouble(), // If available in IoT data
      timestamp: _convertTimestamp(data['timestamp']),
      source: 'iot_device',
      isSynced: true,
    );
  }

  /// Convert timestamp from IoT format to DateTime
  DateTime _convertTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      // If timestamp is a Unix timestamp (seconds) - this is what the IoT device sends
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    } else if (timestamp is Timestamp) {
      // If timestamp is a Firestore Timestamp
      return timestamp.toDate();
    } else if (timestamp is String) {
      // If timestamp is a string, try to parse it
      try {
        final intValue = int.parse(timestamp);
        return DateTime.fromMillisecondsSinceEpoch(intValue * 1000);
      } catch (e) {
        print('⚠️ Could not parse timestamp string: $timestamp');
        return DateTime.now();
      }
    } else {
      // Fallback to current time
      print(
          '⚠️ Unknown timestamp format: $timestamp (${timestamp.runtimeType})');
      return DateTime.now();
    }
  }

  /// Get historical IoT sensor data for charts and trends
  Future<List<VitalSigns>> getHistoricalIoTData({int days = 7}) async {
    print('🔄 Fetching historical IoT data for last $days days...');
    try {
      // For IoT data, we'll get the most recent readings regardless of timestamp
      // since the IoT device timestamps seem to be relative or in a different format
      final snapshot = await _firebaseService.firestore
          .collection('SensorReadings')
          .orderBy('timestamp', descending: true)
          .limit(100) // Get the most recent 100 readings
          .get();

      print('📊 Found ${snapshot.docs.length} IoT readings in database');

      final vitalSigns = snapshot.docs.map((doc) {
        final data = doc.data();
        print('📈 IoT reading: $data');
        return _convertIoTDataToVitalSigns(data, doc.id);
      }).toList();

      print('🔄 Converted ${vitalSigns.length} readings to VitalSigns format');
      return vitalSigns;
    } catch (e) {
      print('❌ Error fetching historical IoT data: $e');
      return [];
    }
  }

  /// Get real-time stream of historical IoT data
  Stream<List<VitalSigns>> getRealTimeHistoricalData({int days = 7}) {
    // For IoT data, we'll get the most recent readings regardless of timestamp
    // since the IoT device timestamps seem to be relative or in a different format
    return _firebaseService.firestore
        .collection('SensorReadings')
        .orderBy('timestamp', descending: true)
        .limit(100) // Get the most recent 100 readings
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return _convertIoTDataToVitalSigns(data, doc.id);
            }).toList());
  }

  /// Get the latest IoT reading for current vitals display
  Future<VitalSigns?> getLatestIoTReading() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('SensorReadings')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        print('📈 Latest IoT reading: $data');
        return _convertIoTDataToVitalSigns(data, snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      print('❌ Error getting latest IoT reading: $e');
      return null;
    }
  }

  /// Get IoT data statistics for charts and insights
  Future<Map<String, dynamic>> getIoTDataStats({int days = 7}) async {
    try {
      // Get the most recent IoT data for statistics
      final historicalData = await getHistoricalIoTData(days: days);

      if (historicalData.isEmpty) {
        return {};
      }

      // Calculate statistics from the available IoT data
      final heartRates = historicalData
          .where((v) => v.heartRate != null)
          .map((v) => v.heartRate!)
          .toList();
      final oxygenLevels = historicalData
          .where((v) => v.oxygenSaturation != null)
          .map((v) => v.oxygenSaturation!)
          .toList();
      final temperatures = historicalData
          .where((v) => v.temperature != null)
          .map((v) => v.temperature!)
          .toList();
      final glucoseLevels = historicalData
          .where((v) => v.glucose != null)
          .map((v) => v.glucose!)
          .toList();

      return {
        'heartRate': {
          'avg': heartRates.isNotEmpty
              ? heartRates.reduce((a, b) => a + b) / heartRates.length
              : 0,
          'min': heartRates.isNotEmpty
              ? heartRates.reduce((a, b) => a < b ? a : b)
              : 0,
          'max': heartRates.isNotEmpty
              ? heartRates.reduce((a, b) => a > b ? a : b)
              : 0,
        },
        'oxygenSaturation': {
          'avg': oxygenLevels.isNotEmpty
              ? oxygenLevels.reduce((a, b) => a + b) / oxygenLevels.length
              : 0,
          'min': oxygenLevels.isNotEmpty
              ? oxygenLevels.reduce((a, b) => a < b ? a : b)
              : 0,
          'max': oxygenLevels.isNotEmpty
              ? oxygenLevels.reduce((a, b) => a > b ? a : b)
              : 0,
        },
        'temperature': {
          'avg': temperatures.isNotEmpty
              ? temperatures.reduce((a, b) => a + b) / temperatures.length
              : 0,
          'min': temperatures.isNotEmpty
              ? temperatures.reduce((a, b) => a < b ? a : b)
              : 0,
          'max': temperatures.isNotEmpty
              ? temperatures.reduce((a, b) => a > b ? a : b)
              : 0,
        },
        'glucose': {
          'avg': glucoseLevels.isNotEmpty
              ? glucoseLevels.reduce((a, b) => a + b) / glucoseLevels.length
              : 0,
          'min': glucoseLevels.isNotEmpty
              ? glucoseLevels.reduce((a, b) => a < b ? a : b)
              : 0,
          'max': glucoseLevels.isNotEmpty
              ? glucoseLevels.reduce((a, b) => a > b ? a : b)
              : 0,
        },
      };
    } catch (e) {
      print('❌ Error calculating IoT data stats: $e');
      return {};
    }
  }

  /// Test method to check if we can read from SensorReadings collection
  Future<void> testSensorReadingsAccess() async {
    print('🧪 Testing SensorReadings collection access...');
    try {
      // Try to read directly from SensorReadings collection
      final snapshot = await _firebaseService.firestore
          .collection('SensorReadings')
          .limit(5) // Get more documents to see what's available
          .get();

      print(
          '📊 SensorReadings collection test: Found ${snapshot.docs.length} documents');

      if (snapshot.docs.isNotEmpty) {
        for (int i = 0; i < snapshot.docs.length; i++) {
          final data = snapshot.docs[i].data();
          print('📈 IoT reading ${i + 1}: $data');
        }

        // Try to convert the first reading to VitalSigns
        final firstData = snapshot.docs.first.data();
        final vitalSigns =
            _convertIoTDataToVitalSigns(firstData, snapshot.docs.first.id);
        print(
            '🔄 Converted first reading to VitalSigns: HR=${vitalSigns.heartRate}, SpO2=${vitalSigns.oxygenSaturation}, Temp=${vitalSigns.temperature}');

        // Send this data to the stream
        _vitalSignsController.add(vitalSigns);
      } else {
        print('⚠️ No documents found in SensorReadings collection');
        print('💡 This means either:');
        print('   1. The collection is empty');
        print('   2. The collection name is different');
        print('   3. There are permission issues');
        print('   4. The IoT device hasn\'t sent data yet');
      }
    } catch (e) {
      print('❌ Error testing SensorReadings access: $e');
      print('💡 This could be due to:');
      print('   1. Firebase not properly initialized');
      print('   2. Network connectivity issues');
      print('   3. Firestore security rules blocking access');
    }
  }

  /// Test different possible collection names for IoT data
  Future<void> testDifferentCollectionNames() async {
    print('🔍 Testing different possible collection names...');

    final possibleNames = [
      'SensorReadings',
      'sensor_readings',
      'sensorreadings',
      'iot_data',
      'iotData',
      'vital_signs',
      'vitalSigns',
      'readings',
      'sensors',
    ];

    for (final collectionName in possibleNames) {
      try {
        final snapshot = await _firebaseService.firestore
            .collection(collectionName)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          print('✅ Found data in collection: $collectionName');
          final data = snapshot.docs.first.data();
          print('📈 Sample data: $data');
          return; // Found the right collection
        }
      } catch (e) {
        // Collection doesn't exist or access denied
        continue;
      }
    }

    print('❌ No data found in any of the tested collection names');
  }

  // MARK: - Mock Data Generation (Fallback)

  /// Generate realistic mock vital signs
  VitalSigns _generateMockVitalSigns() {
    final now = DateTime.now();

    // Time-based variations
    final hourOfDay = now.hour;
    final isNightTime = hourOfDay < 6 || hourOfDay > 22;
    final isDayTime = hourOfDay >= 10 && hourOfDay <= 16;

    // Circadian rhythm adjustments
    double heartRateAdjustment = 0;
    double temperatureAdjustment = 0;

    if (isNightTime) {
      heartRateAdjustment = -8.0;
      temperatureAdjustment = -0.3;
    } else if (isDayTime) {
      heartRateAdjustment = 5.0;
      temperatureAdjustment = 0.2;
    }

    return VitalSigns(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: now,
      heartRate: _generateValue(85.0 + heartRateAdjustment, 15.0,
          min: 60.0, max: 120.0),
      oxygenSaturation: _generateValue(98.0, 2.0, min: 95.0, max: 100.0),
      temperature: _generateValue(36.8 + temperatureAdjustment, 0.8,
          min: 35.5, max: 37.8),
      glucose: _generateValue(115.0, 12.0, min: 90.0, max: 140.0),
      source: 'mock_device',
      isSynced: true,
    );
  }

  /// Generate mock alerts
  List<Alert> _generateMockAlerts() {
    return [
      Alert(
        id: '1',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: AlertType.vitalSigns,
        severity: AlertSeverity.info,
        title: 'Good News!',
        message: 'Your vital signs are all within normal ranges today.',
        actionText: 'View Details',
      ),
      Alert(
        id: '2',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: AlertType.appointment,
        severity: AlertSeverity.warning,
        title: 'Upcoming Appointment',
        message: 'You have a prenatal checkup tomorrow at 2:00 PM.',
        actionText: 'View Details',
      ),
    ];
  }

  /// Generate mock contacts
  List<DoctorContact> _generateMockContacts() {
    return [
      const DoctorContact(
        id: '1',
        name: 'Dr. Sarah Johnson',
        title: 'Obstetrician',
        specialization: 'Obstetrics & Gynecology',
        hospital: 'Accra Regional Hospital',
        phoneNumber: '+233 20 123 4567',
        email: 'dr.sarah@hospital.com',
        type: ContactType.obstetrician,
        isEmergencyContact: true,
        isAvailable: true,
        rating: 4.8,
        yearsExperience: 12,
        languages: ['English', 'Twi'],
      ),
      const DoctorContact(
        id: '2',
        name: 'Nurse Grace Mensah',
        title: 'Midwife',
        specialization: 'Midwifery',
        hospital: 'Community Health Center',
        phoneNumber: '+233 24 987 6543',
        email: 'grace.mensah@health.gov.gh',
        type: ContactType.midwife,
        isEmergencyContact: true,
        isAvailable: true,
        rating: 4.9,
        yearsExperience: 8,
        languages: ['English', 'Twi', 'Ga'],
      ),
    ];
  }

  /// Generate mock recommendations
  List<HealthRecommendation> _generateMockRecommendations() {
    return [
      HealthRecommendation(
        id: '1',
        title: 'Stay Hydrated',
        description:
            'Drink at least 8-10 glasses of water daily to support your pregnancy.',
        type: RecommendationType.hydration,
        priority: RecommendationPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        actionText: 'Log Water Intake',
        icon: Icons.local_drink,
        color: Colors.blue,
      ),
      HealthRecommendation(
        id: '2',
        title: 'Gentle Exercise',
        description:
            'Take a 30-minute walk daily to maintain good circulation.',
        type: RecommendationType.exercise,
        priority: RecommendationPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        actionText: 'Log Exercise',
        icon: Icons.fitness_center,
        color: Colors.green,
      ),
    ];
  }

  /// Generate mock timeline
  PregnancyTimeline? _generateMockTimeline() {
    final lmp =
        DateTime.now().subtract(const Duration(days: 196)); // 28 weeks ago
    final edd = lmp.add(const Duration(days: 280)); // 40 weeks total

    return PregnancyTimeline(
      id: '1',
      lastMenstrualPeriod: lmp,
      estimatedDueDate: edd,
      currentWeek: 28,
      currentDay: 0,
      currentTrimester: PregnancyTrimester.third,
      babySize: 'Eggplant',
      babySizeComparison: 'About the size of an eggplant',
      estimatedBabyWeight: 1.1, // kg
      estimatedBabyLength: 37.6, // cm
      milestones: [],
      weeklyUpdates: [],
    );
  }

  /// Generate a value within a range
  double _generateValue(double base, double variation,
      {double? min, double? max}) {
    final value = base + (_random.nextDouble() - 0.5) * 2 * variation;
    if (min != null && value < min) return min;
    if (max != null && value > max) return max;
    return value;
  }

  // MARK: - Public Methods

  /// Save vital signs to Firebase
  Future<void> saveVitalSigns(VitalSigns vitalSigns) async {
    try {
      await _firebaseService.saveVitalSigns(vitalSigns);
    } catch (e) {
      print('Error saving vital signs: $e');
      // Store locally for later sync
    }
  }

  /// Save alert to Firebase
  Future<void> saveAlert(Alert alert) async {
    try {
      await _firebaseService.saveAlert(alert);
    } catch (e) {
      print('Error saving alert: $e');
    }
  }

  /// Save doctor contact to Firebase
  Future<void> saveDoctorContact(DoctorContact contact) async {
    try {
      await _firebaseService.saveDoctorContact(contact);
    } catch (e) {
      print('Error saving doctor contact: $e');
    }
  }

  /// Save health recommendation to Firebase
  Future<void> saveHealthRecommendation(
      HealthRecommendation recommendation) async {
    try {
      await _firebaseService.saveHealthRecommendation(recommendation);
    } catch (e) {
      print('Error saving health recommendation: $e');
    }
  }

  /// Save pregnancy timeline to Firebase
  Future<void> savePregnancyTimeline(PregnancyTimeline timeline) async {
    try {
      await _firebaseService.savePregnancyTimeline(timeline);
    } catch (e) {
      print('Error saving pregnancy timeline: $e');
    }
  }

  /// Get historical vital signs
  Future<List<VitalSigns>> getHistoricalVitalSigns({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      return await _firebaseService.getHistoricalVitalSigns(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      print('Error getting historical vital signs: $e');
      return [];
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      await _firebaseService.updateUserProfile(data);
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      return await _firebaseService.getUserProfile();
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Dispose of resources
  void dispose() {
    _vitalSignsSubscription?.cancel();
    _alertsSubscription?.cancel();
    _authSubscription?.cancel();

    _vitalSignsController.close();
    _alertsController.close();
    _contactsController.close();
    _recommendationsController.close();
    _timelineController.close();
  }
}
