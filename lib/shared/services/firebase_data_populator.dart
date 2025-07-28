import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/vital_signs.dart';
import '../models/alert.dart';
import '../models/doctor_contact.dart';
import '../models/health_recommendation.dart';
import '../models/pregnancy_timeline.dart';

/// Service to populate Firebase with realistic test data
class FirebaseDataPopulator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Populate all test data for the current user
  static Future<void> populateAllData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      print('Starting data population for user: ${user.uid}');

      // Populate in parallel
      await Future.wait([
        _populateVitalSigns(user.uid),
        _populateAlerts(user.uid),
        _populateDoctorContacts(user.uid),
        _populateHealthRecommendations(user.uid),
        _populatePregnancyTimeline(user.uid),
      ]);

      print('All test data populated successfully!');
    } catch (e) {
      print('Error populating data: $e');
    }
  }

  /// Populate vital signs with realistic data
  static Future<void> _populateVitalSigns(String userId) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    // Generate 7 days of data with 12 readings per day
    for (int day = 6; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));
      
      for (int hour = 0; hour < 24; hour += 2) { // Every 2 hours
        final timestamp = DateTime(date.year, date.month, date.day, hour);
        
        // Time-based variations for realistic data
        final isNightTime = hour < 6 || hour > 22;
        final isDayTime = hour >= 10 && hour <= 16;
        
        double heartRateAdjustment = 0;
        double temperatureAdjustment = 0;
        
        if (isNightTime) {
          heartRateAdjustment = -8.0;
          temperatureAdjustment = -0.3;
        } else if (isDayTime) {
          heartRateAdjustment = 5.0;
          temperatureAdjustment = 0.2;
        }

        final vitalSigns = VitalSigns(
          id: '${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          heartRate: _generateRealisticValue(85.0 + heartRateAdjustment, 15.0, 60.0, 120.0),
          oxygenSaturation: _generateRealisticValue(98.0, 2.0, 95.0, 100.0),
          temperature: _generateRealisticValue(36.8 + temperatureAdjustment, 0.8, 35.5, 37.8),
          systolicBP: _generateRealisticValue(115.0, 12.0, 90.0, 140.0),
          diastolicBP: _generateRealisticValue(72.0, 8.0, 60.0, 90.0),
          glucose: _generateRealisticValue(90.0, 25.0, 70.0, 140.0),
          source: 'device',
          isSynced: true,
        );

        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('vitalSigns')
            .doc(vitalSigns.id);

        batch.set(docRef, vitalSigns.toFirestore());
      }
    }

    await batch.commit();
    print('Vital signs populated: 84 readings over 7 days');
  }

  /// Populate alerts
  static Future<void> _populateAlerts(String userId) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    final alerts = [
      Alert(
        id: '1',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: AlertType.vitalSigns,
        severity: AlertSeverity.info,
        title: 'Good News!',
        message: 'Your vital signs are all within normal ranges today.',
        actionText: 'View Details',
        isRead: false,
      ),
      Alert(
        id: '2',
        timestamp: now.subtract(const Duration(days: 1)),
        type: AlertType.appointment,
        severity: AlertSeverity.warning,
        title: 'Upcoming Appointment',
        message: 'You have a prenatal checkup tomorrow at 2:00 PM.',
        actionText: 'View Details',
        isRead: false,
      ),
      Alert(
        id: '3',
        timestamp: now.subtract(const Duration(days: 2)),
        type: AlertType.vitalSigns,
        severity: AlertSeverity.info,
        title: 'Hydration Reminder',
        message: 'Remember to drink at least 8 glasses of water today.',
        actionText: 'Log Water Intake',
        isRead: true,
      ),
      Alert(
        id: '4',
        timestamp: now.subtract(const Duration(days: 3)),
        type: AlertType.medication,
        severity: AlertSeverity.warning,
        title: 'Medication Due',
        message: 'Time to take your prenatal vitamins.',
        actionText: 'Mark as Taken',
        isRead: false,
      ),
    ];

    for (final alert in alerts) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('alerts')
          .doc(alert.id);

      batch.set(docRef, alert.toFirestore());
    }

    await batch.commit();
    print('Alerts populated: ${alerts.length} alerts');
  }

  /// Populate doctor contacts
  static Future<void> _populateDoctorContacts(String userId) async {
    final batch = _firestore.batch();

    final contacts = [
      DoctorContact(
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
      DoctorContact(
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
      DoctorContact(
        id: '3',
        name: 'Dr. Kwame Asante',
        title: 'Pediatrician',
        specialization: 'Pediatrics',
        hospital: 'Korle Bu Teaching Hospital',
        phoneNumber: '+233 26 555 1234',
        email: 'dr.asante@korlebu.edu.gh',
        type: ContactType.specialist,
        isEmergencyContact: false,
        isAvailable: true,
        rating: 4.7,
        yearsExperience: 15,
        languages: ['English', 'Twi', 'Fante'],
      ),
    ];

    for (final contact in contacts) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contact.id);

      batch.set(docRef, contact.toFirestore());
    }

    await batch.commit();
    print('Doctor contacts populated: ${contacts.length} contacts');
  }

  /// Populate health recommendations
  static Future<void> _populateHealthRecommendations(String userId) async {
    final batch = _firestore.batch();

    final now = DateTime.now();
    final recommendations = [
      HealthRecommendation(
        id: '1',
        title: 'Stay Hydrated',
        description: 'Drink at least 8-10 glasses of water daily to support your pregnancy.',
        type: RecommendationType.hydration,
        priority: RecommendationPriority.medium,
        createdAt: now.subtract(const Duration(days: 1)),
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
        createdAt: now.subtract(const Duration(days: 2)),
        actionText: 'Log Exercise',
        icon: Icons.fitness_center,
        color: Colors.green,
      ),
      HealthRecommendation(
        id: '3',
        title: 'Prenatal Vitamins',
        description: 'Take your prenatal vitamins daily as prescribed.',
        type: RecommendationType.medication,
        priority: RecommendationPriority.high,
        createdAt: now.subtract(const Duration(days: 3)),
        actionText: 'Mark as Taken',
        icon: Icons.medication,
        color: Colors.orange,
      ),
      HealthRecommendation(
        id: '4',
        title: 'Rest Well',
        description: 'Get 7-9 hours of sleep each night for optimal health.',
        type: RecommendationType.rest,
        priority: RecommendationPriority.medium,
        createdAt: now.subtract(const Duration(days: 4)),
        actionText: 'Log Sleep',
        icon: Icons.bedtime,
        color: Colors.purple,
      ),
    ];

    for (final recommendation in recommendations) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendations')
          .doc(recommendation.id);

      batch.set(docRef, recommendation.toFirestore());
    }

    await batch.commit();
    print('Health recommendations populated: ${recommendations.length} recommendations');
  }

  /// Populate pregnancy timeline
  static Future<void> _populatePregnancyTimeline(String userId) async {
    final lmp = DateTime.now().subtract(const Duration(days: 196)); // 28 weeks ago
    final edd = lmp.add(const Duration(days: 280)); // 40 weeks total
    
    // Create a simple timeline document
    final timelineData = {
      'id': '1',
      'lastMenstrualPeriod': lmp.toIso8601String(),
      'estimatedDueDate': edd.toIso8601String(),
      'currentWeek': 28,
      'currentDay': 0,
      'currentTrimester': 'third',
      'babySize': 'Eggplant',
      'babySizeComparison': 'About the size of an eggplant',
      'estimatedBabyWeight': 1.1,
      'estimatedBabyLength': 37.6,
      'milestones': [
        {
          'id': '1',
          'week': 28,
          'title': 'Third Trimester Begins',
          'description': 'Welcome to the final trimester! Your baby is growing rapidly.',
          'isCompleted': true,
        },
        {
          'id': '2',
          'week': 30,
          'title': 'Baby\'s Eyes Open',
          'description': 'Your baby can now open and close their eyes.',
          'isCompleted': false,
        },
      ],
      'weeklyUpdates': [
        {
          'id': '1',
          'week': 28,
          'title': 'Week 28: Growing Strong',
          'description': 'Your baby is about the size of an eggplant and weighs around 1.1 kg.',
          'isRead': true,
        },
      ],
    };

    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('timeline')
        .doc('1');

    await docRef.set(timelineData);
    print('Pregnancy timeline populated');
  }

  /// Generate realistic value within a range
  static double _generateRealisticValue(double base, double variation, double min, double max) {
    final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000.0;
    final value = base + (random - 0.5) * 2 * variation;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Clear all test data
  static Future<void> clearAllData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      final collections = ['vitalSigns', 'alerts', 'contacts', 'recommendations', 'timeline'];
      
      for (final collection in collections) {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection(collection)
            .get();
        
        final batch = _firestore.batch();
        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      print('All test data cleared successfully!');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
} 