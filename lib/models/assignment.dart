class Assignment {
  final String id;
  final String ticketId;
  final String assignedTo;
  final String assignedBy;
  final String assignedAt;
  final String status;
  final String priority;
  final String notes;
  final String? completedAt;
  final String? estimatedCompletion;

  Assignment({
    required this.id,
    required this.ticketId,
    required this.assignedTo,
    required this.assignedBy,
    required this.assignedAt,
    required this.status,
    required this.priority,
    required this.notes,
    this.completedAt,
    this.estimatedCompletion,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['_id'] ?? '',
      ticketId: json['ticket_id'] ?? '',
      assignedTo: json['assigned_to'] ?? '',
      assignedBy: json['assigned_by'] ?? '',
      assignedAt: json['assigned_at'] ?? '',
      status: json['status'] ?? 'assigned',
      priority: json['priority'] ?? 'medium',
      notes: json['notes'] ?? '',
      completedAt: json['completed_at'],
      estimatedCompletion: json['estimated_completion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ticket_id': ticketId,
      'assigned_to': assignedTo,
      'assigned_by': assignedBy,
      'assigned_at': assignedAt,
      'status': status,
      'priority': priority,
      'notes': notes,
      'completed_at': completedAt,
      'estimated_completion': estimatedCompletion,
    };
  }
}