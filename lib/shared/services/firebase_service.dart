import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/vital_signs.dart';
import '../models/alert.dart';
import '../models/doctor_contact.dart';
import '../models/health_recommendation.dart';
import '../models/pregnancy_timeline.dart';

/// Comprehensive Firebase Service for Maternal Guardian App
/// Handles Authentication, Firestore, and Cloud Messaging
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseMessaging _messaging;

  // Stream controllers for real-time data
  final StreamController<VitalSigns> _vitalSignsController = 
      StreamController<VitalSigns>.broadcast();
  final StreamController<List<Alert>> _alertsController = 
      StreamController<List<Alert>>.broadcast();
  final StreamController<User?> _authStateController = 
      StreamController<User?>.broadcast();

  // Current user data
  User? _currentUser;
  String? _currentUserId;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseMessaging get messaging => _messaging;
  User? get currentUser => _currentUser;
  String? get currentUserId => _currentUserId;
  
  Stream<VitalSigns> get vitalSignsStream => _vitalSignsController.stream;
  Stream<List<Alert>> get alertsStream => _alertsController.stream;
  Stream<User?> get authStateStream => _authStateController.stream;

  /// Initialize Firebase services
  static Future<void> initialize() async {
    final service = FirebaseService();
    await service._initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize Firebase instances
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _messaging = FirebaseMessaging.instance;

      // Configure Firestore settings
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Set up authentication state listener
      _auth.authStateChanges().listen((User? user) {
        _currentUser = user;
        _currentUserId = user?.uid;
        _authStateController.add(user);
        
        if (user != null) {
          _setupMessaging();
          _startListeningToUserData();
        } else {
          _stopListeningToUserData();
        }
      });

      // Request notification permissions
      await _requestNotificationPermissions();

      print('Firebase Service initialized successfully');
    } catch (e) {
      print('Error initializing Firebase Service: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  /// Set up Firebase Cloud Messaging
  Future<void> _setupMessaging() async {
    try {
      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null && _currentUserId != null) {
        await _saveFCMToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((String token) {
        _saveFCMToken(token);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          _handleForegroundMessage(message);
        }
      });

      // Handle message when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('A new onMessageOpenedApp event was published!');
        _handleMessageOpenedApp(message);
      });

    } catch (e) {
      print('Error setting up messaging: $e');
    }
  }

  /// Save FCM token to user document
  Future<void> _saveFCMToken(String token) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .update({'fcmToken': token, 'lastTokenUpdate': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // Parse message data and update local state
    if (message.data.containsKey('vitalSigns')) {
      // Handle vital signs update
      _parseAndUpdateVitalSigns(message.data['vitalSigns']);
    } else if (message.data.containsKey('alert')) {
      // Handle alert
      _parseAndUpdateAlert(message.data['alert']);
    }
  }

  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to appropriate screen based on message data
    if (message.data.containsKey('screen')) {
      // Navigate to specific screen
      print('Navigate to: ${message.data['screen']}');
    }
  }

  /// Start listening to user's real-time data
  void _startListeningToUserData() {
    if (_currentUserId == null) return;

    // Listen to vital signs
    _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('vitalSigns')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final vitalSigns = VitalSigns.fromFirestore(data);
        _vitalSignsController.add(vitalSigns);
      }
    });

    // Listen to alerts
    _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final alerts = snapshot.docs
          .map((doc) => Alert.fromFirestore(doc.data()))
          .toList();
      _alertsController.add(alerts);
    });
  }

  /// Stop listening to user data
  void _stopListeningToUserData() {
    // Streams will automatically close when user logs out
  }

  /// Parse and update vital signs from message data
  void _parseAndUpdateVitalSigns(Map<String, dynamic> data) {
    try {
      final vitalSigns = VitalSigns.fromFirestore(data);
      _vitalSignsController.add(vitalSigns);
    } catch (e) {
      print('Error parsing vital signs: $e');
    }
  }

  /// Parse and update alert from message data
  void _parseAndUpdateAlert(Map<String, dynamic> data) {
    try {
      final alert = Alert.fromFirestore(data);
      // Update alerts list
      // This will be handled by the Firestore listener
    } catch (e) {
      print('Error parsing alert: $e');
    }
  }

  // MARK: - Authentication Methods

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email, 
    String password,
    Map<String, dynamic> userData,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        ...userData,
      });

      return credential;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  // MARK: - Firestore Methods

  /// Save vital signs to Firestore
  Future<void> saveVitalSigns(VitalSigns vitalSigns) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('vitalSigns')
          .add(vitalSigns.toFirestore());
    } catch (e) {
      print('Error saving vital signs: $e');
      rethrow;
    }
  }

  /// Get historical vital signs
  Future<List<VitalSigns>> getHistoricalVitalSigns({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    if (_currentUserId == null) return [];

    try {
      Query query = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('vitalSigns')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => VitalSigns.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting historical vital signs: $e');
      return [];
    }
  }

  /// Save alert to Firestore
  Future<void> saveAlert(Alert alert) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('alerts')
          .add(alert.toFirestore());
    } catch (e) {
      print('Error saving alert: $e');
      rethrow;
    }
  }

  /// Get user alerts
  Future<List<Alert>> getUserAlerts({bool activeOnly = false}) async {
    if (_currentUserId == null) return [];

    try {
      Query query = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('alerts')
          .orderBy('timestamp', descending: true);

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Alert.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user alerts: $e');
      return [];
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      
      return doc.data();
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Save doctor contact
  Future<void> saveDoctorContact(DoctorContact contact) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('contacts')
          .add(contact.toFirestore());
    } catch (e) {
      print('Error saving doctor contact: $e');
      rethrow;
    }
  }

  /// Get doctor contacts
  Future<List<DoctorContact>> getDoctorContacts() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('contacts')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => DoctorContact.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting doctor contacts: $e');
      return [];
    }
  }

  /// Save health recommendation
  Future<void> saveHealthRecommendation(HealthRecommendation recommendation) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('recommendations')
          .add(recommendation.toFirestore());
    } catch (e) {
      print('Error saving health recommendation: $e');
      rethrow;
    }
  }

  /// Get health recommendations
  Future<List<HealthRecommendation>> getHealthRecommendations() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('recommendations')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => HealthRecommendation.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting health recommendations: $e');
      return [];
    }
  }

  /// Save pregnancy timeline
  Future<void> savePregnancyTimeline(PregnancyTimeline timeline) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('timeline')
          .add(timeline.toFirestore());
    } catch (e) {
      print('Error saving pregnancy timeline: $e');
      rethrow;
    }
  }

  /// Get pregnancy timeline
  Future<List<PregnancyTimeline>> getPregnancyTimeline() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('timeline')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PregnancyTimeline.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting pregnancy timeline: $e');
      return [];
    }
  }

  // MARK: - Cleanup

  /// Dispose of resources
  void dispose() {
    _vitalSignsController.close();
    _alertsController.close();
    _authStateController.close();
  }
} 