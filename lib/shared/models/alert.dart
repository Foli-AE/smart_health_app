import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Alert model for notifications and warnings
class Alert {
  final String id;
  final DateTime timestamp;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? action;
  final bool isRead;
  final Map<String, dynamic>? data;

  const Alert({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.actionText,
    this.action,
    this.isRead = false,
    this.data,
  });

  Alert copyWith({
    String? id,
    DateTime? timestamp,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    String? actionText,
    VoidCallback? action,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return Alert(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      actionText: actionText ?? this.actionText,
      action: action ?? this.action,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'message': message,
      'actionText': actionText,
      'isRead': isRead,
      'data': data,
    };
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      type: AlertType.values.firstWhere((e) => e.name == json['type']),
      severity: AlertSeverity.values.firstWhere((e) => e.name == json['severity']),
      title: json['title'],
      message: json['message'],
      actionText: json['actionText'],
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'message': message,
      'actionText': actionText,
      'isRead': isRead,
      'data': data,
      'isActive': true, // For Firestore queries
    };
  }

  /// Create from Firestore document data
  factory Alert.fromFirestore(Map<String, dynamic> data) {
    return Alert(
      id: data['id'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: AlertType.values.firstWhere((e) => e.name == data['type']),
      severity: AlertSeverity.values.firstWhere((e) => e.name == data['severity']),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      actionText: data['actionText'],
      isRead: data['isRead'] ?? false,
      data: data['data'],
    );
  }
}

/// Types of alerts in the system
enum AlertType {
  vitalSigns,
  medication,
  appointment,
  emergency,
  system,
  recommendation,
  achievement,
}

/// Alert severity levels
enum AlertSeverity {
  info,
  warning,
  critical,
  emergency,
}

/// Extensions for alert types and severities
extension AlertTypeExtension on AlertType {
  String get displayName {
    switch (this) {
      case AlertType.vitalSigns:
        return 'Vital Signs';
      case AlertType.medication:
        return 'Medication';
      case AlertType.appointment:
        return 'Appointment';
      case AlertType.emergency:
        return 'Emergency';
      case AlertType.system:
        return 'System';
      case AlertType.recommendation:
        return 'Recommendation';
      case AlertType.achievement:
        return 'Achievement';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.vitalSigns:
        return Icons.favorite;
      case AlertType.medication:
        return Icons.medication;
      case AlertType.appointment:
        return Icons.event;
      case AlertType.emergency:
        return Icons.emergency;
      case AlertType.system:
        return Icons.settings;
      case AlertType.recommendation:
        return Icons.lightbulb;
      case AlertType.achievement:
        return Icons.star;
    }
  }
}

extension AlertSeverityExtension on AlertSeverity {
  String get displayName {
    switch (this) {
      case AlertSeverity.info:
        return 'Information';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
      case AlertSeverity.emergency:
        return 'Emergency';
    }
  }

  Color get color {
    switch (this) {
      case AlertSeverity.info:
        return const Color(0xFF2196F3); // Blue
      case AlertSeverity.warning:
        return const Color(0xFFFF9800); // Orange
      case AlertSeverity.critical:
        return const Color(0xFFF44336); // Red
      case AlertSeverity.emergency:
        return const Color(0xFFD32F2F); // Dark Red
    }
  }

  int get priority {
    switch (this) {
      case AlertSeverity.info:
        return 1;
      case AlertSeverity.warning:
        return 2;
      case AlertSeverity.critical:
        return 3;
      case AlertSeverity.emergency:
        return 4;
    }
  }
} 