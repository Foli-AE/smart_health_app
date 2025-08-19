import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Test Firebase connectivity
  static Future<bool> testConnection() async {
    try {
      // Test Firestore connection
      await _firestore.collection('test').doc('connection').get();
      return true;
    } catch (e) {
      print('Firebase connection test failed: $e');
      return false;
    }
  }

  /// Test user authentication
  static Future<bool> testAuth() async {
    try {
      final user = _auth.currentUser;
      return user != null;
    } catch (e) {
      print('Firebase auth test failed: $e');
      return false;
    }
  }

  /// Test basic CRUD operations
  static Future<Map<String, dynamic>> testCRUD() async {
    final results = <String, dynamic>{};

    try {
      // Test Create
      final testDoc = await _firestore.collection('test').add({
        'message': 'Hello Firebase!',
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
      });
      results['create'] = 'Success - Document ID: ${testDoc.id}';

      // Test Read
      final readDoc = await testDoc.get();
      results['read'] = 'Success - Data: ${readDoc.data()}';

      // Test Update
      await testDoc.update({
        'message': 'Updated message',
        'updated': true,
      });
      results['update'] = 'Success';

      // Test Delete
      await testDoc.delete();
      results['delete'] = 'Success';

      results['overall'] = 'All CRUD operations successful';
    } catch (e) {
      results['error'] = 'CRUD test failed: $e';
    }

    return results;
  }

  /// Test real-time data streaming
  static Stream<Map<String, dynamic>> testRealtimeData() {
    return _firestore
        .collection('test')
        .doc('realtime')
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  /// Create test data for the app
  static Future<void> createTestData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Create test vital signs
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vitalSigns')
          .add({
        'heartRate': 78,
        'oxygenSaturation': 98,
        'temperature': 36.7,
        'systolicBP': 110,
        'diastolicBP': 70,
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'test',
      });

      // Create test alerts
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('alerts')
          .add({
        'type': 'info',
        'title': 'Test Alert',
        'message': 'This is a test alert',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Create test doctor contacts
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('contacts')
          .add({
        'name': 'Dr. Sarah Johnson',
        'phone': '+233 20 123 4567',
        'specialty': 'Obstetrics',
        'hospital': 'Korle Bu Teaching Hospital',
        'isEmergency': true,
      });

      print('Test data created successfully');
    } catch (e) {
      print('Failed to create test data: $e');
    }
  }

  /// Clean up test data
  static Future<void> cleanupTestData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Delete test collections
      final collections = ['vitalSigns', 'alerts', 'contacts'];

      for (final collection in collections) {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection(collection)
            .get();

        for (final doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
      }

      print('Test data cleaned up successfully');
    } catch (e) {
      print('Failed to cleanup test data: $e');
    }
  }
}
