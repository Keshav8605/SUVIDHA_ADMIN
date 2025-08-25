import 'package:flutter/material.dart';

class Issue {
  final String ticketId;
  final String category;
  final String address;
  final Location location;
  final String description;
  final String title;
  final String? photo;
  final String status;
  final String createdAt;
  final String? inProgressAt;
  final String? completedAt;
  final List<String> users;
  final int issueCount;
  final String? updatedBy;
  final dynamic originalText;

  final String? admin_completed_at;
  final String? user_completed_at;
  final String? admin_completed_by;
  final String? user_completed_by;
  Issue({
    required this.ticketId,
    required this.category,
    required this.address,
    required this.updatedBy,
    required this.originalText,
    required this.location,
    required this.inProgressAt,
    required this.completedAt,
    required this.description,
    required this.title,
    this.photo,
    required this.status,
    required this.createdAt,
    required this.users,
    required this.issueCount,
    required this.admin_completed_at,
    required this.user_completed_at,
    required this.admin_completed_by,
    required this.user_completed_by,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      ticketId: json['ticket_id'] ?? '',
      category: json['category'] ?? '',
      address: json['address'] ?? '',
      location: Location.fromJson(json['location'] ?? {}),
      description: json['description'] ?? '',
      title: json['title'] ?? '',
      photo: json['photo'],
      status: json['status'] ?? 'new',
      createdAt: json['created_at'] ?? '',
      users: List<String>.from(json['users'] ?? []),
      issueCount: json['issue_count'] ?? 0,
      inProgressAt: json['in_progress_at'] ?? '',
      completedAt: json['completed_at'] ?? '',
      updatedBy: json['updated_by_email'] ?? '',
      originalText: json['original_text'] ?? '',
      admin_completed_at: json['admin_completed_at'] ?? '',
      user_completed_at: json['user_completed_at'] ?? '',
      admin_completed_by: json['admin_completed_by'] ?? '',
      user_completed_by: json['user_completed_by'] ?? '',
    );
  }

  Issue copyWith({String? status}) {
    return Issue(
      ticketId: ticketId,
      category: category,
      address: address,
      location: location,
      description: description,
      title: title,
      photo: photo,
      status: status ?? this.status,
      createdAt: createdAt,
      users: users,
      issueCount: issueCount,
      inProgressAt: inProgressAt,
      completedAt: completedAt,
      updatedBy: updatedBy,
      originalText: originalText,
      admin_completed_at: admin_completed_at,
      user_completed_at: user_completed_at,
      admin_completed_by: admin_completed_by,
      user_completed_by: user_completed_by,
    );
  }

  Color get priorityColor {
    if (issueCount >= 10) return const Color(0xFFDC2626);
    if (issueCount >= 5) return const Color(0xFFEA580C);
    if (issueCount >= 2) return const Color(0xFFD97706);
    return const Color(0xFF059669);
  }

  Color get priorityBackgroundColor {
    if (issueCount >= 10) return const Color(0xFFFEF2F2);
    if (issueCount >= 5) return const Color(0xFFFFF7ED);
    if (issueCount >= 2) return const Color(0xFFFFFBEB);
    return const Color(0xFFF0FDF4);
  }

  String get priorityText {
    if (issueCount >= 10) return 'Critical';
    if (issueCount >= 5) return 'High';
    if (issueCount >= 2) return 'Medium';
    return 'Low';
  }

  Color get statusColor {
    switch (status) {
      case 'new':
        return const Color(0xFFEA580C);
      case 'in_progress':
        return const Color(0xFF2563EB);
      case 'completed':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color get statusBackgroundColor {
    switch (status) {
      case 'new':
        return const Color(0xFFFFF7ED);
      case 'in_progress':
        return const Color(0xFFEFF6FF);
      case 'completed':
        return const Color(0xFFF0FDF4);
      default:
        return const Color(0xFFF9FAFB);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'new':
        return Icons.fiber_new_rounded;
      case 'in_progress':
        return Icons.work_outline_rounded;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

class Location {
  final double longitude;
  final double latitude;

  Location({required this.longitude, required this.latitude});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
    );
  }
}
