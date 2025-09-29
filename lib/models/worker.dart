// models/worker.dart
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import 'assignment.dart';

class Worker {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String departmentId;
  final String specialization;
  final int experienceYears;
  final int currentWorkload;
  final int maxCapacity;
  final bool isAvailable;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  Worker({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.departmentId,
    required this.specialization,
    required this.experienceYears,
    required this.currentWorkload,
    required this.maxCapacity,
    required this.isAvailable,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      departmentId: json['department_id'] ?? '',
      specialization: json['specialization'] ?? '',
      experienceYears: json['experience_years'] ?? 0,
      currentWorkload: json['current_workload'] ?? 0,
      maxCapacity: json['max_capacity'] ?? 5,
      isAvailable: json['is_available'] ?? true,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'department_id': departmentId,
      'specialization': specialization,
      'experience_years': experienceYears,
      'current_workload': currentWorkload,
      'max_capacity': maxCapacity,
      'is_available': isAvailable,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  double get workloadPercentage => currentWorkload / maxCapacity;

  bool get isOverloaded => workloadPercentage > 0.8;

  Worker copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? departmentId,
    String? specialization,
    int? experienceYears,
    int? currentWorkload,
    int? maxCapacity,
    bool? isAvailable,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      departmentId: departmentId ?? this.departmentId,
      specialization: specialization ?? this.specialization,
      experienceYears: experienceYears ?? this.experienceYears,
      currentWorkload: currentWorkload ?? this.currentWorkload,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// models/department.dart
class Department {
  final String id;
  final String name;
  final List<String> categories;
  final bool? isActive;
  final String createdAt;
  final String? updatedAt;

  Department({
    required this.id,
    required this.name,
    required this.categories,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'categories': categories,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}



