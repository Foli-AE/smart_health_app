import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pregnancy timeline model for tracking pregnancy progression
class PregnancyTimeline {
  final String id;
  final DateTime lastMenstrualPeriod;
  final DateTime estimatedDueDate;
  final int currentWeek;
  final int currentDay;
  final PregnancyTrimester currentTrimester;
  final String babySize;
  final String babySizeComparison;
  final double estimatedBabyWeight;
  final double estimatedBabyLength;
  final List<PregnancyMilestone> milestones;
  final List<WeeklyUpdate> weeklyUpdates;
  final Map<String, dynamic>? metadata;

  const PregnancyTimeline({
    required this.id,
    required this.lastMenstrualPeriod,
    required this.estimatedDueDate,
    required this.currentWeek,
    required this.currentDay,
    required this.currentTrimester,
    required this.babySize,
    required this.babySizeComparison,
    required this.estimatedBabyWeight,
    required this.estimatedBabyLength,
    required this.milestones,
    required this.weeklyUpdates,
    this.metadata,
  });

  PregnancyTimeline copyWith({
    String? id,
    DateTime? lastMenstrualPeriod,
    DateTime? estimatedDueDate,
    int? currentWeek,
    int? currentDay,
    PregnancyTrimester? currentTrimester,
    String? babySize,
    String? babySizeComparison,
    double? estimatedBabyWeight,
    double? estimatedBabyLength,
    List<PregnancyMilestone>? milestones,
    List<WeeklyUpdate>? weeklyUpdates,
    Map<String, dynamic>? metadata,
  }) {
    return PregnancyTimeline(
      id: id ?? this.id,
      lastMenstrualPeriod: lastMenstrualPeriod ?? this.lastMenstrualPeriod,
      estimatedDueDate: estimatedDueDate ?? this.estimatedDueDate,
      currentWeek: currentWeek ?? this.currentWeek,
      currentDay: currentDay ?? this.currentDay,
      currentTrimester: currentTrimester ?? this.currentTrimester,
      babySize: babySize ?? this.babySize,
      babySizeComparison: babySizeComparison ?? this.babySizeComparison,
      estimatedBabyWeight: estimatedBabyWeight ?? this.estimatedBabyWeight,
      estimatedBabyLength: estimatedBabyLength ?? this.estimatedBabyLength,
      milestones: milestones ?? this.milestones,
      weeklyUpdates: weeklyUpdates ?? this.weeklyUpdates,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lastMenstrualPeriod': lastMenstrualPeriod.toIso8601String(),
      'estimatedDueDate': estimatedDueDate.toIso8601String(),
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'currentTrimester': currentTrimester.name,
      'babySize': babySize,
      'babySizeComparison': babySizeComparison,
      'estimatedBabyWeight': estimatedBabyWeight,
      'estimatedBabyLength': estimatedBabyLength,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'weeklyUpdates': weeklyUpdates.map((w) => w.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory PregnancyTimeline.fromJson(Map<String, dynamic> json) {
    return PregnancyTimeline(
      id: json['id'],
      lastMenstrualPeriod: DateTime.parse(json['lastMenstrualPeriod']),
      estimatedDueDate: DateTime.parse(json['estimatedDueDate']),
      currentWeek: json['currentWeek'],
      currentDay: json['currentDay'],
      currentTrimester: PregnancyTrimester.values.firstWhere((e) => e.name == json['currentTrimester']),
      babySize: json['babySize'],
      babySizeComparison: json['babySizeComparison'],
      estimatedBabyWeight: json['estimatedBabyWeight'].toDouble(),
      estimatedBabyLength: json['estimatedBabyLength'].toDouble(),
      milestones: (json['milestones'] as List).map((m) => PregnancyMilestone.fromJson(m)).toList(),
      weeklyUpdates: (json['weeklyUpdates'] as List).map((w) => WeeklyUpdate.fromJson(w)).toList(),
      metadata: json['metadata'],
    );
  }

  int get daysUntilDue => estimatedDueDate.difference(DateTime.now()).inDays;
  double get pregnancyProgress => (currentWeek + currentDay / 7) / 40.0;
  String get formattedWeek => '$currentWeek weeks ${currentDay > 0 ? '$currentDay days' : ''}';

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'lastMenstrualPeriod': Timestamp.fromDate(lastMenstrualPeriod),
      'estimatedDueDate': Timestamp.fromDate(estimatedDueDate),
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'currentTrimester': currentTrimester.name,
      'babySize': babySize,
      'babySizeComparison': babySizeComparison,
      'estimatedBabyWeight': estimatedBabyWeight,
      'estimatedBabyLength': estimatedBabyLength,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'weeklyUpdates': weeklyUpdates.map((w) => w.toJson()).toList(),
      'metadata': metadata,
    };
  }

  /// Create from Firestore document data
  factory PregnancyTimeline.fromFirestore(Map<String, dynamic> data) {
    return PregnancyTimeline(
      id: data['id'] ?? '',
      lastMenstrualPeriod: (data['lastMenstrualPeriod'] as Timestamp).toDate(),
      estimatedDueDate: (data['estimatedDueDate'] as Timestamp).toDate(),
      currentWeek: data['currentWeek'] ?? 0,
      currentDay: data['currentDay'] ?? 0,
      currentTrimester: PregnancyTrimester.values.firstWhere((e) => e.name == data['currentTrimester']),
      babySize: data['babySize'] ?? '',
      babySizeComparison: data['babySizeComparison'] ?? '',
      estimatedBabyWeight: data['estimatedBabyWeight']?.toDouble() ?? 0.0,
      estimatedBabyLength: data['estimatedBabyLength']?.toDouble() ?? 0.0,
      milestones: (data['milestones'] as List? ?? []).map((m) => PregnancyMilestone.fromJson(m)).toList(),
      weeklyUpdates: (data['weeklyUpdates'] as List? ?? []).map((w) => WeeklyUpdate.fromJson(w)).toList(),
      metadata: data['metadata'],
    );
  }
}

/// Pregnancy milestone model
class PregnancyMilestone {
  final String id;
  final int week;
  final String title;
  final String description;
  final MilestoneType type;
  final bool isCompleted;
  final DateTime? completedAt;
  final IconData? icon;
  final Color? color;

  const PregnancyMilestone({
    required this.id,
    required this.week,
    required this.title,
    required this.description,
    required this.type,
    this.isCompleted = false,
    this.completedAt,
    this.icon,
    this.color,
  });

  PregnancyMilestone copyWith({
    String? id,
    int? week,
    String? title,
    String? description,
    MilestoneType? type,
    bool? isCompleted,
    DateTime? completedAt,
    IconData? icon,
    Color? color,
  }) {
    return PregnancyMilestone(
      id: id ?? this.id,
      week: week ?? this.week,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'week': week,
      'title': title,
      'description': description,
      'type': type.name,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'icon': icon?.codePoint,
      'color': color?.value,
    };
  }

  factory PregnancyMilestone.fromJson(Map<String, dynamic> json) {
    return PregnancyMilestone(
      id: json['id'],
      week: json['week'],
      title: json['title'],
      description: json['description'],
      type: MilestoneType.values.firstWhere((e) => e.name == json['type']),
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      icon: null, // Use enum-based icon instead of dynamic IconData
      color: json['color'] != null ? Color(json['color']) : null,
    );
  }
}

/// Weekly update model for pregnancy progression
class WeeklyUpdate {
  final String id;
  final int week;
  final String title;
  final String motherChanges;
  final String babyDevelopment;
  final List<String> tips;
  final List<String> symptoms;
  final List<String> appointments;
  final String? imageUrl;

  const WeeklyUpdate({
    required this.id,
    required this.week,
    required this.title,
    required this.motherChanges,
    required this.babyDevelopment,
    required this.tips,
    required this.symptoms,
    required this.appointments,
    this.imageUrl,
  });

  WeeklyUpdate copyWith({
    String? id,
    int? week,
    String? title,
    String? motherChanges,
    String? babyDevelopment,
    List<String>? tips,
    List<String>? symptoms,
    List<String>? appointments,
    String? imageUrl,
  }) {
    return WeeklyUpdate(
      id: id ?? this.id,
      week: week ?? this.week,
      title: title ?? this.title,
      motherChanges: motherChanges ?? this.motherChanges,
      babyDevelopment: babyDevelopment ?? this.babyDevelopment,
      tips: tips ?? this.tips,
      symptoms: symptoms ?? this.symptoms,
      appointments: appointments ?? this.appointments,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'week': week,
      'title': title,
      'motherChanges': motherChanges,
      'babyDevelopment': babyDevelopment,
      'tips': tips,
      'symptoms': symptoms,
      'appointments': appointments,
      'imageUrl': imageUrl,
    };
  }

  factory WeeklyUpdate.fromJson(Map<String, dynamic> json) {
    return WeeklyUpdate(
      id: json['id'],
      week: json['week'],
      title: json['title'],
      motherChanges: json['motherChanges'],
      babyDevelopment: json['babyDevelopment'],
      tips: json['tips'].cast<String>(),
      symptoms: json['symptoms'].cast<String>(),
      appointments: json['appointments'].cast<String>(),
      imageUrl: json['imageUrl'],
    );
  }
}

/// Pregnancy trimesters
enum PregnancyTrimester {
  first,
  second,
  third,
}

/// Types of pregnancy milestones
enum MilestoneType {
  appointment,
  test,
  development,
  preparation,
  education,
}

/// Extensions for pregnancy trimesters
extension PregnancyTrimesterExtension on PregnancyTrimester {
  String get displayName {
    switch (this) {
      case PregnancyTrimester.first:
        return 'First Trimester';
      case PregnancyTrimester.second:
        return 'Second Trimester';
      case PregnancyTrimester.third:
        return 'Third Trimester';
    }
  }

  String get description {
    switch (this) {
      case PregnancyTrimester.first:
        return 'Weeks 1-12: Early development and body changes';
      case PregnancyTrimester.second:
        return 'Weeks 13-26: Often the most comfortable period';
      case PregnancyTrimester.third:
        return 'Weeks 27-40: Final preparation for birth';
    }
  }

  Color get color {
    switch (this) {
      case PregnancyTrimester.first:
        return const Color(0xFF4CAF50); // Green
      case PregnancyTrimester.second:
        return const Color(0xFF2196F3); // Blue
      case PregnancyTrimester.third:
        return const Color(0xFFE91E63); // Pink
    }
  }

  IntRange get weekRange {
    switch (this) {
      case PregnancyTrimester.first:
        return const IntRange(1, 12);
      case PregnancyTrimester.second:
        return const IntRange(13, 26);
      case PregnancyTrimester.third:
        return const IntRange(27, 40);
    }
  }
}

/// Extensions for milestone types
extension MilestoneTypeExtension on MilestoneType {
  String get displayName {
    switch (this) {
      case MilestoneType.appointment:
        return 'Appointment';
      case MilestoneType.test:
        return 'Test';
      case MilestoneType.development:
        return 'Development';
      case MilestoneType.preparation:
        return 'Preparation';
      case MilestoneType.education:
        return 'Education';
    }
  }

  IconData get icon {
    switch (this) {
      case MilestoneType.appointment:
        return Icons.event;
      case MilestoneType.test:
        return Icons.assignment;
      case MilestoneType.development:
        return Icons.child_care;
      case MilestoneType.preparation:
        return Icons.check_circle;
      case MilestoneType.education:
        return Icons.school;
    }
  }

  Color get color {
    switch (this) {
      case MilestoneType.appointment:
        return const Color(0xFF2196F3); // Blue
      case MilestoneType.test:
        return const Color(0xFFFF9800); // Orange
      case MilestoneType.development:
        return const Color(0xFFE91E63); // Pink
      case MilestoneType.preparation:
        return const Color(0xFF4CAF50); // Green
      case MilestoneType.education:
        return const Color(0xFF9C27B0); // Purple
    }
  }
}

/// Helper class for integer ranges
class IntRange {
  final int start;
  final int end;

  const IntRange(this.start, this.end);

  bool contains(int value) => value >= start && value <= end;
  int get length => end - start + 1;
} 