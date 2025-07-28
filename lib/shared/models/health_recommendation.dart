import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Health recommendation model for personalized tips and insights
class HealthRecommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationType type;
  final RecommendationPriority priority;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isCompleted;
  final String? actionText;
  final IconData? icon;
  final Color? color;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  const HealthRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.expiresAt,
    this.isCompleted = false,
    this.actionText,
    this.icon,
    this.color,
    this.tags,
    this.metadata,
  });

  HealthRecommendation copyWith({
    String? id,
    String? title,
    String? description,
    RecommendationType? type,
    RecommendationPriority? priority,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isCompleted,
    String? actionText,
    IconData? icon,
    Color? color,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return HealthRecommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
      actionText: actionText ?? this.actionText,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'actionText': actionText,
      'icon': icon?.codePoint,
      'color': color?.value,
      'tags': tags,
      'metadata': metadata,
    };
  }

  factory HealthRecommendation.fromJson(Map<String, dynamic> json) {
    return HealthRecommendation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: RecommendationType.values.firstWhere((e) => e.name == json['type']),
      priority: RecommendationPriority.values.firstWhere((e) => e.name == json['priority']),
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      isCompleted: json['isCompleted'] ?? false,
      actionText: json['actionText'],
      icon: null, // Use enum-based icon instead of dynamic IconData
      color: json['color'] != null ? Color(json['color']) : null,
      tags: json['tags']?.cast<String>(),
      metadata: json['metadata'],
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isActive => !isCompleted && !isExpired;

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isCompleted': isCompleted,
      'actionText': actionText,
      'icon': icon?.codePoint,
      'color': color?.value,
      'tags': tags,
      'metadata': metadata,
    };
  }

  /// Create from Firestore document data
  factory HealthRecommendation.fromFirestore(Map<String, dynamic> data) {
    return HealthRecommendation(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: RecommendationType.values.firstWhere((e) => e.name == data['type']),
      priority: RecommendationPriority.values.firstWhere((e) => e.name == data['priority']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate() : null,
      isCompleted: data['isCompleted'] ?? false,
      actionText: data['actionText'],
      icon: null, // Use enum-based icon instead of dynamic IconData
      color: data['color'] != null ? Color(data['color']) : null,
      tags: data['tags']?.cast<String>(),
      metadata: data['metadata'],
    );
  }
}

/// Types of health recommendations
enum RecommendationType {
  nutrition,
  exercise,
  hydration,
  rest,
  medication,
  appointment,
  lifestyle,
  mindfulness,
  safety,
  education,
}

/// Priority levels for recommendations
enum RecommendationPriority {
  low,
  medium,
  high,
  urgent,
}

/// Extensions for recommendation types
extension RecommendationTypeExtension on RecommendationType {
  String get displayName {
    switch (this) {
      case RecommendationType.nutrition:
        return 'Nutrition';
      case RecommendationType.exercise:
        return 'Exercise';
      case RecommendationType.hydration:
        return 'Hydration';
      case RecommendationType.rest:
        return 'Rest';
      case RecommendationType.medication:
        return 'Medication';
      case RecommendationType.appointment:
        return 'Appointment';
      case RecommendationType.lifestyle:
        return 'Lifestyle';
      case RecommendationType.mindfulness:
        return 'Mindfulness';
      case RecommendationType.safety:
        return 'Safety';
      case RecommendationType.education:
        return 'Education';
    }
  }

  IconData get icon {
    switch (this) {
      case RecommendationType.nutrition:
        return Icons.restaurant;
      case RecommendationType.exercise:
        return Icons.fitness_center;
      case RecommendationType.hydration:
        return Icons.local_drink;
      case RecommendationType.rest:
        return Icons.bed;
      case RecommendationType.medication:
        return Icons.medication;
      case RecommendationType.appointment:
        return Icons.event;
      case RecommendationType.lifestyle:
        return Icons.self_improvement;
      case RecommendationType.mindfulness:
        return Icons.psychology;
      case RecommendationType.safety:
        return Icons.shield;
      case RecommendationType.education:
        return Icons.school;
    }
  }

  Color get color {
    switch (this) {
      case RecommendationType.nutrition:
        return const Color(0xFF4CAF50); // Green
      case RecommendationType.exercise:
        return const Color(0xFFFF9800); // Orange
      case RecommendationType.hydration:
        return const Color(0xFF2196F3); // Blue
      case RecommendationType.rest:
        return const Color(0xFF9C27B0); // Purple
      case RecommendationType.medication:
        return const Color(0xFFF44336); // Red
      case RecommendationType.appointment:
        return const Color(0xFF3F51B5); // Indigo
      case RecommendationType.lifestyle:
        return const Color(0xFF795548); // Brown
      case RecommendationType.mindfulness:
        return const Color(0xFF00BCD4); // Cyan
      case RecommendationType.safety:
        return const Color(0xFFE91E63); // Pink
      case RecommendationType.education:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }
}

/// Extensions for recommendation priorities
extension RecommendationPriorityExtension on RecommendationPriority {
  String get displayName {
    switch (this) {
      case RecommendationPriority.low:
        return 'Low Priority';
      case RecommendationPriority.medium:
        return 'Medium Priority';
      case RecommendationPriority.high:
        return 'High Priority';
      case RecommendationPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case RecommendationPriority.low:
        return const Color(0xFF4CAF50); // Green
      case RecommendationPriority.medium:
        return const Color(0xFFFF9800); // Orange
      case RecommendationPriority.high:
        return const Color(0xFFF44336); // Red
      case RecommendationPriority.urgent:
        return const Color(0xFFD32F2F); // Dark Red
    }
  }

  int get priority {
    switch (this) {
      case RecommendationPriority.low:
        return 1;
      case RecommendationPriority.medium:
        return 2;
      case RecommendationPriority.high:
        return 3;
      case RecommendationPriority.urgent:
        return 4;
    }
  }
} 