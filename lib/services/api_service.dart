import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/assignment.dart';
import '../models/issue.dart';
import '../models/worker.dart';

class ApiService {
  static const String baseUrl = 'https://suvidha-backend-fmw2.onrender.com';

  // ---------------- Issues ----------------
  static Future<List<Issue>> getIssues({String? category, int? limit}) async {
    String url = '$baseUrl/issues';
    List<String> queryParams = [];

    if (category != null && category.isNotEmpty) {
      queryParams.add('category=${Uri.encodeComponent(category)}');
    }
    if (limit != null) {
      queryParams.add('limit=$limit');
    }

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Issue.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load issues: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching issues: $e');
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/issues/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.cast<String>();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      // fallback categories
      return [
        'Sanitation & Waste',
        'Water & Drainage',
        'Electricity & Streetlights',
        'Roads & Transport',
        'Public Health & Safety',
        'Environment & Parks',
        'Building & Infrastructure',
        'Taxes & Documentation',
        'Emergency Services',
        'Animal Care & Control',
        'Other',
      ];
    }
  }

  static Future<bool> updateIssueStatus(
      String ticketId,
      String newStatus,
      ) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (newStatus == "completed") {
        final response = await http.post(
          Uri.parse('$baseUrl/issues/$ticketId/complete'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'completion_type': 'admin',
            'email': currentUser?.email ?? "admin@g.com",
          }),
        );
        return response.statusCode == 200;
      } else {
        final response = await http.put(
          Uri.parse('$baseUrl/issues/$ticketId/status'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'status': newStatus,
            'email': currentUser?.email ?? "admin@g.com",
          }),
        );
        return response.statusCode == 200;
      }
    } catch (e) {
      print('Error updating issue status: $e');
      return false;
    }
  }

  static Future<int> getIssueCount({String? category}) async {
    String url = '$baseUrl/issues/count';
    if (category != null && category.isNotEmpty) {
      url += '?category=${Uri.encodeComponent(category)}';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Failed to load issue count: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching issue count: $e');
    }
  }

  // ---------------- Worker Authentication ----------------
  static Future<bool> workerLogin(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/workers/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  static Future<bool> registerWorker(Map<String, dynamic> workerData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/workers/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(workerData),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  // ---------------- Worker Management ----------------
  static Future<List<Worker>> getWorkers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/workers'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Worker.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load workers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching workers: $e');
    }
  }

  static Future<List<Worker>> getWorkersByDepartment(
      String departmentId,
      ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/workers/department/$departmentId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Worker.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load workers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching workers: $e');
    }
  }

  // ---------------- Department Management ----------------
  static Future<List<Department>> getDepartments() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/departments'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Department.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load departments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching departments: $e');
    }
  }

  // ---------------- Assignment Management ----------------
  static Future<List<Assignment>> getAssignments() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/assignments'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Assignment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load assignments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching assignments: $e');
    }
  }

  static Future<bool> assignWorker({
    required String ticketId,
    required String workerEmail,
    String notes = '',
  }) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      final response = await http.post(
        Uri.parse('$baseUrl/assignments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ticket_id': ticketId,
          'assigned_to': workerEmail,
          'assigned_by': currentUser?.email ?? 'admin@example.com',
          'notes': notes,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error assigning worker: $e');
    }
  }

  static Future<bool> reassignWorker({
    required String assignmentId,
    required String newWorkerEmail,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/assignments/$assignmentId/reassign'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'new_assigned_to': newWorkerEmail}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error reassigning worker: $e');
    }
  }

  static Future<bool> updateAssignmentStatus({
    required String ticketId,
    required String status,
    String notes = '',
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/assignments/$ticketId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status, 'notes': notes}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating assignment status: $e');
    }
  }

  // ---------------- Worker Dashboard ----------------
  static Future<List<Assignment>> getWorkerAssignments(
      String workerEmail,
      ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/assignments/worker/$workerEmail'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Assignment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load assignments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching worker assignments: $e');
    }
  }

  static Future<Worker?> getWorkerProfile(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/workers/profile/$email'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Worker.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching worker profile: $e');
    }
  }
}
