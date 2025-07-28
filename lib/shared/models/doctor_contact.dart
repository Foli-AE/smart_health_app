import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Doctor/Healthcare provider contact model
class DoctorContact {
  final String id;
  final String name;
  final String title;
  final String specialization;
  final String? hospital;
  final String phoneNumber;
  final String? email;
  final String? address;
  final ContactType type;
  final bool isEmergencyContact;
  final bool isAvailable;
  final String? profileImage;
  final double? rating;
  final int? yearsExperience;
  final List<String>? languages;
  final WorkingHours? workingHours;

  const DoctorContact({
    required this.id,
    required this.name,
    required this.title,
    required this.specialization,
    this.hospital,
    required this.phoneNumber,
    this.email,
    this.address,
    required this.type,
    this.isEmergencyContact = false,
    this.isAvailable = true,
    this.profileImage,
    this.rating,
    this.yearsExperience,
    this.languages,
    this.workingHours,
  });

  DoctorContact copyWith({
    String? id,
    String? name,
    String? title,
    String? specialization,
    String? hospital,
    String? phoneNumber,
    String? email,
    String? address,
    ContactType? type,
    bool? isEmergencyContact,
    bool? isAvailable,
    String? profileImage,
    double? rating,
    int? yearsExperience,
    List<String>? languages,
    WorkingHours? workingHours,
  }) {
    return DoctorContact(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      specialization: specialization ?? this.specialization,
      hospital: hospital ?? this.hospital,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      type: type ?? this.type,
      isEmergencyContact: isEmergencyContact ?? this.isEmergencyContact,
      isAvailable: isAvailable ?? this.isAvailable,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      languages: languages ?? this.languages,
      workingHours: workingHours ?? this.workingHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'specialization': specialization,
      'hospital': hospital,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'type': type.name,
      'isEmergencyContact': isEmergencyContact,
      'isAvailable': isAvailable,
      'profileImage': profileImage,
      'rating': rating,
      'yearsExperience': yearsExperience,
      'languages': languages,
      'workingHours': workingHours?.toJson(),
    };
  }

  factory DoctorContact.fromJson(Map<String, dynamic> json) {
    return DoctorContact(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      specialization: json['specialization'],
      hospital: json['hospital'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      address: json['address'],
      type: ContactType.values.firstWhere((e) => e.name == json['type']),
      isEmergencyContact: json['isEmergencyContact'] ?? false,
      isAvailable: json['isAvailable'] ?? true,
      profileImage: json['profileImage'],
      rating: json['rating']?.toDouble(),
      yearsExperience: json['yearsExperience'],
      languages: json['languages']?.cast<String>(),
      workingHours: json['workingHours'] != null 
          ? WorkingHours.fromJson(json['workingHours'])
          : null,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'specialization': specialization,
      'hospital': hospital,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'type': type.name,
      'isEmergencyContact': isEmergencyContact,
      'isAvailable': isAvailable,
      'profileImage': profileImage,
      'rating': rating,
      'yearsExperience': yearsExperience,
      'languages': languages,
      'workingHours': workingHours?.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create from Firestore document data
  factory DoctorContact.fromFirestore(Map<String, dynamic> data) {
    return DoctorContact(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      title: data['title'] ?? '',
      specialization: data['specialization'] ?? '',
      hospital: data['hospital'],
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'],
      address: data['address'],
      type: ContactType.values.firstWhere((e) => e.name == data['type']),
      isEmergencyContact: data['isEmergencyContact'] ?? false,
      isAvailable: data['isAvailable'] ?? true,
      profileImage: data['profileImage'],
      rating: data['rating']?.toDouble(),
      yearsExperience: data['yearsExperience'],
      languages: data['languages']?.cast<String>(),
      workingHours: data['workingHours'] != null 
          ? WorkingHours.fromJson(data['workingHours'])
          : null,
    );
  }
}

/// Working hours for healthcare providers
class WorkingHours {
  final TimeOfDay? mondayStart;
  final TimeOfDay? mondayEnd;
  final TimeOfDay? tuesdayStart;
  final TimeOfDay? tuesdayEnd;
  final TimeOfDay? wednesdayStart;
  final TimeOfDay? wednesdayEnd;
  final TimeOfDay? thursdayStart;
  final TimeOfDay? thursdayEnd;
  final TimeOfDay? fridayStart;
  final TimeOfDay? fridayEnd;
  final TimeOfDay? saturdayStart;
  final TimeOfDay? saturdayEnd;
  final TimeOfDay? sundayStart;
  final TimeOfDay? sundayEnd;
  final bool isOnCall24h;

  const WorkingHours({
    this.mondayStart,
    this.mondayEnd,
    this.tuesdayStart,
    this.tuesdayEnd,
    this.wednesdayStart,
    this.wednesdayEnd,
    this.thursdayStart,
    this.thursdayEnd,
    this.fridayStart,
    this.fridayEnd,
    this.saturdayStart,
    this.saturdayEnd,
    this.sundayStart,
    this.sundayEnd,
    this.isOnCall24h = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'mondayStart': mondayStart != null ? '${mondayStart!.hour}:${mondayStart!.minute}' : null,
      'mondayEnd': mondayEnd != null ? '${mondayEnd!.hour}:${mondayEnd!.minute}' : null,
      'tuesdayStart': tuesdayStart != null ? '${tuesdayStart!.hour}:${tuesdayStart!.minute}' : null,
      'tuesdayEnd': tuesdayEnd != null ? '${tuesdayEnd!.hour}:${tuesdayEnd!.minute}' : null,
      'wednesdayStart': wednesdayStart != null ? '${wednesdayStart!.hour}:${wednesdayStart!.minute}' : null,
      'wednesdayEnd': wednesdayEnd != null ? '${wednesdayEnd!.hour}:${wednesdayEnd!.minute}' : null,
      'thursdayStart': thursdayStart != null ? '${thursdayStart!.hour}:${thursdayStart!.minute}' : null,
      'thursdayEnd': thursdayEnd != null ? '${thursdayEnd!.hour}:${thursdayEnd!.minute}' : null,
      'fridayStart': fridayStart != null ? '${fridayStart!.hour}:${fridayStart!.minute}' : null,
      'fridayEnd': fridayEnd != null ? '${fridayEnd!.hour}:${fridayEnd!.minute}' : null,
      'saturdayStart': saturdayStart != null ? '${saturdayStart!.hour}:${saturdayStart!.minute}' : null,
      'saturdayEnd': saturdayEnd != null ? '${saturdayEnd!.hour}:${saturdayEnd!.minute}' : null,
      'sundayStart': sundayStart != null ? '${sundayStart!.hour}:${sundayStart!.minute}' : null,
      'sundayEnd': sundayEnd != null ? '${sundayEnd!.hour}:${sundayEnd!.minute}' : null,
      'isOnCall24h': isOnCall24h,
    };
  }

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return WorkingHours(
      mondayStart: parseTime(json['mondayStart']),
      mondayEnd: parseTime(json['mondayEnd']),
      tuesdayStart: parseTime(json['tuesdayStart']),
      tuesdayEnd: parseTime(json['tuesdayEnd']),
      wednesdayStart: parseTime(json['wednesdayStart']),
      wednesdayEnd: parseTime(json['wednesdayEnd']),
      thursdayStart: parseTime(json['thursdayStart']),
      thursdayEnd: parseTime(json['thursdayEnd']),
      fridayStart: parseTime(json['fridayStart']),
      fridayEnd: parseTime(json['fridayEnd']),
      saturdayStart: parseTime(json['saturdayStart']),
      saturdayEnd: parseTime(json['saturdayEnd']),
      sundayStart: parseTime(json['sundayStart']),
      sundayEnd: parseTime(json['sundayEnd']),
      isOnCall24h: json['isOnCall24h'] ?? false,
    );
  }
}

/// Types of contacts
enum ContactType {
  obstetrician,
  midwife,
  nurse,
  generalDoctor,
  specialist,
  emergency,
  familyMember,
  friend,
}

/// Extensions for contact types
extension ContactTypeExtension on ContactType {
  String get displayName {
    switch (this) {
      case ContactType.obstetrician:
        return 'Obstetrician';
      case ContactType.midwife:
        return 'Midwife';
      case ContactType.nurse:
        return 'Nurse';
      case ContactType.generalDoctor:
        return 'General Doctor';
      case ContactType.specialist:
        return 'Specialist';
      case ContactType.emergency:
        return 'Emergency';
      case ContactType.familyMember:
        return 'Family';
      case ContactType.friend:
        return 'Friend';
    }
  }

  IconData get icon {
    switch (this) {
      case ContactType.obstetrician:
        return Icons.pregnant_woman;
      case ContactType.midwife:
        return Icons.healing;
      case ContactType.nurse:
        return Icons.local_hospital;
      case ContactType.generalDoctor:
        return Icons.medical_services;
      case ContactType.specialist:
        return Icons.science;
      case ContactType.emergency:
        return Icons.emergency;
      case ContactType.familyMember:
        return Icons.family_restroom;
      case ContactType.friend:
        return Icons.people;
    }
  }

  Color get color {
    switch (this) {
      case ContactType.obstetrician:
        return const Color(0xFFE91E63); // Pink
      case ContactType.midwife:
        return const Color(0xFF9C27B0); // Purple
      case ContactType.nurse:
        return const Color(0xFF2196F3); // Blue
      case ContactType.generalDoctor:
        return const Color(0xFF4CAF50); // Green
      case ContactType.specialist:
        return const Color(0xFFFF9800); // Orange
      case ContactType.emergency:
        return const Color(0xFFF44336); // Red
      case ContactType.familyMember:
        return const Color(0xFF795548); // Brown
      case ContactType.friend:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }
} 