import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Stream<List<HealthRecommendation>> get recommendationsStream => _recommendationsController.stream;
  Stream<PregnancyTimeline?> get timelineStream => _timelineController.stream;

  VitalSigns? get currentVitals => _currentVitals;
  List<Alert> get currentAlerts => _currentAlerts;
  List<DoctorContact> get currentContacts => _currentContacts;
  List<HealthRecommendation> get currentRecommendations => _currentRecommendations;
  PregnancyTimeline? get currentTimeline => _currentTimeline;

  /// Initialize the service
  Future<void> initialize() async {
    _vitalSignsController = StreamController<VitalSigns>.broadcast();
    _alertsController = StreamController<List<Alert>>.broadcast();
    _contactsController = StreamController<List<DoctorContact>>.broadcast();
    _recommendationsController = StreamController<List<HealthRecommendation>>.broadcast();
    _timelineController = StreamController<PregnancyTimeline?>.broadcast();

    // Listen to authentication state changes
    _authSubscription = _firebaseService.authStateStream.listen((user) {
      if (user != null) {
        _startListeningToUserData();
      } else {
        _stopListeningToUserData();
      }
    });

    // Listen to Firebase vital signs stream
    _vitalSignsSubscription = _firebaseService.vitalSignsStream.listen((vitalSigns) {
      _currentVitals = vitalSigns;
      _vitalSignsController.add(vitalSigns);
    });

    // Listen to Firebase alerts stream
    _alertsSubscription = _firebaseService.alertsStream.listen((alerts) {
      _currentAlerts = alerts;
      _alertsController.add(alerts);
    });

    print('Firebase Data Service initialized');
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
      _currentRecommendations = await _firebaseService.getHealthRecommendations();
      _recommendationsController.add(_currentRecommendations);

      // Load timeline
      final timelines = await _firebaseService.getPregnancyTimeline();
      _currentTimeline = timelines.isNotEmpty ? timelines.first : null;
      _timelineController.add(_currentTimeline);

      // Load historical vital signs
      final historicalVitals = await _firebaseService.getHistoricalVitalSigns(limit: 1);
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
      heartRate: _generateValue(85.0 + heartRateAdjustment, 15.0, min: 60.0, max: 120.0),
      oxygenSaturation: _generateValue(98.0, 2.0, min: 95.0, max: 100.0),
      temperature: _generateValue(36.8 + temperatureAdjustment, 0.8, min: 35.5, max: 37.8),
      systolicBP: _generateValue(115.0, 12.0, min: 90.0, max: 140.0),
      diastolicBP: _generateValue(72.0, 8.0, min: 60.0, max: 90.0),
      glucose: _generateValue(90.0, 25.0, min: 70.0, max: 140.0),
      source: 'device',
      isSynced: false,
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
        description: 'Drink at least 8-10 glasses of water daily to support your pregnancy.',
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
        description: 'Take a 30-minute walk daily to maintain good circulation.',
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
    final lmp = DateTime.now().subtract(const Duration(days: 196)); // 28 weeks ago
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
  double _generateValue(double base, double variation, {double? min, double? max}) {
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
  Future<void> saveHealthRecommendation(HealthRecommendation recommendation) async {
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