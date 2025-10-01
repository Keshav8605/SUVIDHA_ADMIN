import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/worker.dart';
import '../models/assignment.dart';
import '../services/api_service.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  Worker? _workerProfile;
  List<Assignment> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData(); // Use one function to load all data
  }

  // Combines both data loading functions into one
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? workerEmail = prefs.getString('worker_email');

      if (workerEmail == null) {
        throw Exception("Worker email not found. Please log in again.");
      }

      // Fetch profile and assignments at the same time
      final results = await Future.wait([
        ApiService.getWorkerProfile(workerEmail),
        ApiService.getWorkerAssignments(workerEmail),
      ]);

      setState(() {
        _workerProfile = results[0] as Worker?;
        _assignments = results[1] as List<Assignment>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _markWorkAsCompleted(Assignment assignment) async {
    try {
      // Corrected the function name here
      final success = await ApiService.updateAssignmentStatusWorker(
        ticketId: assignment.ticketId,
        status: 'worker_completed',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work marked as completed!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAllData(); // Refresh all data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Worker Dashboard'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
          // You should also have a logout button here
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkerProfile(),
            const SizedBox(height: 24),
            _buildAssignmentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerProfile() {
    if (_workerProfile == null) return const Center(child: Text("Could not load worker profile."));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF059669),
            child: Text(
              _workerProfile!.name.isNotEmpty ? _workerProfile!.name.substring(0, 1).toUpperCase() : 'W',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _workerProfile!.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          Text(
            _workerProfile!.specialization,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Experience', '${_workerProfile!.experienceYears} years'),
              _buildStatCard('Assignments', '${_assignments.length}'),
              _buildStatCard('Workload', '${_workerProfile!.currentWorkload}/${_workerProfile!.maxCapacity}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildAssignmentsList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Assignments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          if (_assignments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 64, color: Color(0xFF64748B)),
                    SizedBox(height: 16),
                    Text('No assignments yet'),
                  ],
                ),
              ),
            )
          else
          // This is a cleaner way to build a list of widgets from a map
            Column(
              children: _assignments.map((assignment) => _buildAssignmentCard(assignment)).toList(),
            ),
        ],
      ),
    );
  }

  // This is the single, combined assignment card widget
  Widget _buildAssignmentCard(Assignment assignment) {
    bool isCompleted = assignment.status == 'worker_completed' || assignment.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                assignment.ticketId,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(assignment.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  assignment.status.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Assigned: ${assignment.assignedAt}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          if (assignment.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              assignment.notes,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCompleted ? null : () => _markWorkAsCompleted(assignment),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(isCompleted ? 'Completed' : 'Mark as Complete'),
            ),
          )
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return const Color(0xFF3B82F6); // Blue
      case 'in_progress':
        return const Color(0xFFF59E0B); // Amber
      case 'worker_completed':
        return const Color(0xFF8B5CF6); // Violet
      case 'completed':
        return const Color(0xFF10B981); // Green
      default:
        return const Color(0xFF64748B); // Slate
    }
  }
}