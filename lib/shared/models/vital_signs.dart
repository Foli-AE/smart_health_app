import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// part 'vital_signs.g.dart';

/// Represents a complete set of vital signs at a specific time
@HiveType(typeId: 0)
class VitalSigns extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final double? heartRate; // BPM

  @HiveField(3)
  final double? oxygenSaturation; // SpO2 percentage

  @HiveField(4)
  final double? temperature; // Celsius

  @HiveField(5)
  final double? systolicBP; // mmHg

  @HiveField(6)
  final double? diastolicBP; // mmHg

  @HiveField(7)
  final double? glucose; // mg/dL

  @HiveField(8)
  final String source; // 'device' or 'manual'

  @HiveField(9)
  final bool isSynced; // Whether synced to cloud

  VitalSigns({
    required this.id,
    required this.timestamp,
    this.heartRate,
    this.oxygenSaturation,
    this.temperature,
    this.systolicBP,
    this.diastolicBP,
    this.glucose,
    this.source = 'device',
    this.isSynced = false,
  });

  /// Health status based on vital signs (0-100 scale)
  double get healthScore {
    double score = 0;
    int validMetrics = 0;

    // Heart Rate scoring (60-100 BPM is ideal)
    if (heartRate != null) {
      if (heartRate! >= 60 && heartRate! <= 100) {
        score += 100;
      } else if (heartRate! >= 50 && heartRate! <= 120) {
        score += 80;
      } else if (heartRate! >= 40 && heartRate! <= 140) {
        score += 60;
      } else {
        score += 30;
      }
      validMetrics++;
    }

    // Oxygen Saturation scoring (95-100% is ideal)
    if (oxygenSaturation != null) {
      if (oxygenSaturation! >= 95) {
        score += 100;
      } else if (oxygenSaturation! >= 90) {
        score += 70;
      } else if (oxygenSaturation! >= 85) {
        score += 40;
      } else {
        score += 20;
      }
      validMetrics++;
    }

    // Temperature scoring (36.1-37.2°C is ideal)
    if (temperature != null) {
      if (temperature! >= 36.1 && temperature! <= 37.2) {
        score += 100;
      } else if (temperature! >= 35.5 && temperature! <= 37.8) {
        score += 80;
      } else if (temperature! >= 35.0 && temperature! <= 38.5) {
        score += 60;
      } else {
        score += 30;
      }
      validMetrics++;
    }

    // Blood Pressure scoring (systolic 90-120, diastolic 60-80)
    if (systolicBP != null && diastolicBP != null) {
      if (systolicBP! >= 90 && systolicBP! <= 120 && 
          diastolicBP! >= 60 && diastolicBP! <= 80) {
        score += 100;
      } else if (systolicBP! >= 80 && systolicBP! <= 140 && 
                 diastolicBP! >= 50 && diastolicBP! <= 90) {
        score += 70;
      } else {
        score += 40;
      }
      validMetrics++;
    }

    // Glucose scoring (70-140 mg/dL is acceptable for pregnancy)
    if (glucose != null) {
      if (glucose! >= 70 && glucose! <= 140) {
        score += 100;
      } else if (glucose! >= 60 && glucose! <= 180) {
        score += 70;
      } else {
        score += 40;
      }
      validMetrics++;
    }

    return validMetrics > 0 ? score / validMetrics : 50; // Default to 50 if no metrics
  }

  /// Health status level
  HealthStatus get status {
    final score = healthScore;
    if (score >= 90) return HealthStatus.excellent;
    if (score >= 75) return HealthStatus.good;
    if (score >= 60) return HealthStatus.fair;
    if (score >= 40) return HealthStatus.poor;
    return HealthStatus.critical;
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'heartRate': heartRate,
      'oxygenSaturation': oxygenSaturation,
      'temperature': temperature,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'glucose': glucose,
      'source': source,
      'healthScore': healthScore,
      'status': status.name,
    };
  }

  /// Create from Firestore map
  factory VitalSigns.fromMap(Map<String, dynamic> map) {
    return VitalSigns(
      id: map['id'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      heartRate: map['heartRate']?.toDouble(),
      oxygenSaturation: map['oxygenSaturation']?.toDouble(),
      temperature: map['temperature']?.toDouble(),
      systolicBP: map['systolicBP']?.toDouble(),
      diastolicBP: map['diastolicBP']?.toDouble(),
      glucose: map['glucose']?.toDouble(),
      source: map['source'] ?? 'device',
      isSynced: true, // From cloud, so already synced
    );
  }

  /// Copy with new values
  VitalSigns copyWith({
    String? id,
    DateTime? timestamp,
    double? heartRate,
    double? oxygenSaturation,
    double? temperature,
    double? systolicBP,
    double? diastolicBP,
    double? glucose,
    String? source,
    bool? isSynced,
  }) {
    return VitalSigns(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      heartRate: heartRate ?? this.heartRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      temperature: temperature ?? this.temperature,
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      glucose: glucose ?? this.glucose,
      source: source ?? this.source,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'timestamp': Timestamp.fromDate(timestamp),
      'heartRate': heartRate,
      'oxygenSaturation': oxygenSaturation,
      'temperature': temperature,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'glucose': glucose,
      'source': source,
      'isSynced': isSynced,
      'healthScore': healthScore,
      'status': status.name,
    };
  }

  /// Create from Firestore document data
  factory VitalSigns.fromFirestore(Map<String, dynamic> data) {
    return VitalSigns(
      id: data['id'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      heartRate: data['heartRate']?.toDouble(),
      oxygenSaturation: data['oxygenSaturation']?.toDouble(),
      temperature: data['temperature']?.toDouble(),
      systolicBP: data['systolicBP']?.toDouble(),
      diastolicBP: data['diastolicBP']?.toDouble(),
      glucose: data['glucose']?.toDouble(),
      source: data['source'] ?? 'device',
      isSynced: data['isSynced'] ?? true,
    );
  }
}

/// Health status levels
enum HealthStatus {
  excellent,
  good,
  fair,
  poor,
  critical,
}

extension HealthStatusExtension on HealthStatus {
  String get displayName {
    switch (this) {
      case HealthStatus.excellent:
        return 'Excellent';
      case HealthStatus.good:
        return 'Good';
      case HealthStatus.fair:
        return 'Fair';
      case HealthStatus.poor:
        return 'Poor';
      case HealthStatus.critical:
        return 'Critical';
    }
  }

  String get description {
    switch (this) {
      case HealthStatus.excellent:
        return 'All vitals are in optimal range';
      case HealthStatus.good:
        return 'Vitals are healthy';
      case HealthStatus.fair:
        return 'Some vitals need attention';
      case HealthStatus.poor:
        return 'Multiple vitals are concerning';
      case HealthStatus.critical:
        return 'Immediate medical attention needed';
    }
  }
}

/// Connection status with the wearable device
enum DeviceConnectionStatus {
  connected,
  connecting,
  disconnected,
  scanning,
  error,
}

extension DeviceConnectionStatusExtension on DeviceConnectionStatus {
  String get displayName {
    switch (this) {
      case DeviceConnectionStatus.connected:
        return 'Connected';
      case DeviceConnectionStatus.connecting:
        return 'Connecting...';
      case DeviceConnectionStatus.disconnected:
        return 'Disconnected';
      case DeviceConnectionStatus.scanning:
        return 'Scanning...';
      case DeviceConnectionStatus.error:
        return 'Connection Error';
    }
  }
} 