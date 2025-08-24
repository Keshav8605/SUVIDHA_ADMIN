import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/issue.dart';

class ApiService {
  static const String baseUrl = 'https://cdgi-backend-main.onrender.com';

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
          Uri.parse(
            'https://cdgi-backend-main.onrender.com/issues/$ticketId/complete',
          ),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'completion_type': 'admin',
            'email': currentUser!.email ?? "admin@g.com",
          }),
        );
        print(response.statusCode);
        print(response.body);
        return response.statusCode == 200;
      } else {
        final response = await http.put(
          Uri.parse('$baseUrl/issues/$ticketId/status'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'status': newStatus,
            'email': currentUser!.email ?? "admin@g.com",
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
}
