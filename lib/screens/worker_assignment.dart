// worker_assignment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/assignment.dart';
import '../models/issue.dart';
import '../models/worker.dart';
import '../services/api_service.dart';

class WorkerAssignmentScreen extends StatefulWidget {
  const WorkerAssignmentScreen({super.key});

  @override
  State<WorkerAssignmentScreen> createState() => _WorkerAssignmentScreenState();
}

class _WorkerAssignmentScreenState extends State<WorkerAssignmentScreen>
    with TickerProviderStateMixin {
  List<Issue> _unassignedIssues = [];
  List<Issue> _assignedIssues = [];
  List<Worker> _workers = [];
  List<Department> _departments = [];
  List<Assignment> _assignments = [];

  bool _isLoading = true;
  String _selectedTab = 'unassigned';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getIssues(),
        ApiService.getWorkers(),
        ApiService.getDepartments(),
        ApiService.getAssignments(),
      ]);

      final allIssues = results[0] as List<Issue>;
      _workers = results[1] as List<Worker>;
      _departments = results[2] as List<Department>;
      _assignments = results[3] as List<Assignment>;

      // Separate assigned and unassigned issues
      final assignedTicketIds = _assignments.map((a) => a.ticketId).toSet();
      _unassignedIssues = allIssues.where((issue) => !assignedTicketIds.contains(issue.ticketId)).toList();
      _assignedIssues = allIssues.where((issue) => assignedTicketIds.contains(issue.ticketId)).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load data: $e');
    }
  }

  Department? _getDepartmentForCategory(String category) {
    return _departments.firstWhere(
          (dept) => dept.categories!.contains(category),
      orElse: () => Department(
        id: '',
        name: 'Unknown',
        categories: [],
        isActive: false,
        createdAt: '',
      ),
    );
  }

  List<Worker> _getWorkersForDepartment(String departmentId) {
    return _workers.where((worker) =>
    worker.departmentId == departmentId && worker.isAvailable).toList();
  }

  Assignment? _getAssignmentForIssue(String ticketId) {
    try {
      return _assignments.firstWhere((assignment) => assignment.ticketId == ticketId);
    } catch (e) {
      return null;
    }
  }

  Worker? _getWorkerByEmail(String email) {
    try {
      return _workers.firstWhere((worker) => worker.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<void> _assignWorker(Issue issue, Worker worker, String notes) async {
    try {
      final success = await ApiService.assignWorker(
        ticketId: issue.ticketId,
        workerEmail: worker.email,
        notes: notes,
      );

      if (success) {
        await _loadData(); // Refresh data
        _showSuccessSnackBar('Worker assigned successfully!');
      } else {
        _showErrorSnackBar('Failed to assign worker');
      }
    } catch (e) {
      _showErrorSnackBar('Error assigning worker: $e');
    }
  }

  Future<void> _reassignWorker(Assignment assignment, Worker newWorker) async {
    try {
      final success = await ApiService.reassignWorker(
        assignmentId: assignment.id,
        newWorkerEmail: newWorker.email,
      );

      if (success) {
        await _loadData(); // Refresh data
        _showSuccessSnackBar('Worker reassigned successfully!');
      } else {
        _showErrorSnackBar('Failed to reassign worker');
      }
    } catch (e) {
      _showErrorSnackBar('Error reassigning worker: $e');
    }
  }

  void _showAssignmentDialog(Issue issue) {
    final department = _getDepartmentForCategory(issue.category);
    if (department == null) {
      _showErrorSnackBar('No department found for this category');
      return;
    }

    final availableWorkers = _getWorkersForDepartment(department.id);
    if (availableWorkers.isEmpty) {
      _showErrorSnackBar('No available workers in ${department.name}');
      return;
    }

    Worker? selectedWorker;
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Worker'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Issue Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Issue: ${issue.title}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Category: ${issue.category}'),
                      Text('Priority: ${issue.priorityText}'),
                      Text('Reports: ${issue.issueCount}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Department Info
                Text('Department: ${department.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                // Worker Selection
                const Text('Select Worker:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                ...availableWorkers.map((worker) => RadioListTile<Worker>(
                  title: Text(worker.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${worker.specialization}'),
                      Text('Experience: ${worker.experienceYears} years'),
                      Text('Workload: ${worker.currentWorkload}/${worker.maxCapacity}'),
                      LinearProgressIndicator(
                        value: worker.currentWorkload / worker.maxCapacity,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          worker.currentWorkload / worker.maxCapacity > 0.8
                              ? Colors.red
                              : worker.currentWorkload / worker.maxCapacity > 0.6
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  value: worker,
                  groupValue: selectedWorker,
                  onChanged: (value) => setDialogState(() => selectedWorker = value),
                )),

                const SizedBox(height: 16),

                // Notes
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Assignment Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => notes = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedWorker == null ? null : () {
                Navigator.pop(context);
                _assignWorker(issue, selectedWorker!, notes);
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReassignmentDialog(Assignment assignment) {
    final issue = _assignedIssues.firstWhere((i) => i.ticketId == assignment.ticketId);
    final department = _getDepartmentForCategory(issue.category);
    final availableWorkers = _getWorkersForDepartment(department!.id);

    Worker? selectedWorker;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reassign Worker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Worker: ${_getWorkerByEmail(assignment.assignedTo)?.name ?? "Unknown"}'),
              const SizedBox(height: 16),
              const Text('Select New Worker:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              ...availableWorkers.where((w) => w.email != assignment.assignedTo).map((worker) =>
                  RadioListTile<Worker>(
                    title: Text(worker.name),
                    subtitle: Text('${worker.specialization} - Workload: ${worker.currentWorkload}/${worker.maxCapacity}'),
                    value: worker,
                    groupValue: selectedWorker,
                    onChanged: (value) => setDialogState(() => selectedWorker = value),
                  ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedWorker == null ? null : () {
                Navigator.pop(context);
                _reassignWorker(assignment, selectedWorker!);
              },
              child: const Text('Reassign'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Worker Assignment',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Unassigned (${_unassignedIssues.length})'),
            Tab(text: 'Assigned (${_assignedIssues.length})'),
            Tab(text: 'Workers (${_workers.length})'),
          ],
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF3B82F6),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildUnassignedIssues(),
          _buildAssignedIssues(),
          _buildWorkersOverview(),
        ],
      ),
    );
  }

  Widget _buildUnassignedIssues() {
    if (_unassignedIssues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text(
              'All issues assigned!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Text(
              'Great job managing the workload.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _unassignedIssues.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildUnassignedIssueCard(_unassignedIssues[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnassignedIssueCard(Issue issue) {
    final department = _getDepartmentForCategory(issue.category);
    final availableWorkers = department != null
        ? _getWorkersForDepartment(department.id).length
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: issue.priorityBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: issue.priorityColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    issue.priorityText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  issue.ticketId,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${issue.issueCount} reports',
                  style: TextStyle(
                    fontSize: 12,
                    color: issue.priorityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title.isNotEmpty ? issue.title : 'Untitled Issue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  issue.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        issue.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.business_outlined,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      department?.name ?? 'Unknown Department',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$availableWorkers workers available',
                      style: TextStyle(
                        fontSize: 12,
                        color: availableWorkers > 0 ? Colors.green.shade600 : Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: availableWorkers > 0
                        ? () => _showAssignmentDialog(issue)
                        : null,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: Text(availableWorkers > 0
                        ? 'Assign Worker'
                        : 'No Workers Available'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedIssues() {
    if (_assignedIssues.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Color(0xFF64748B)),
            SizedBox(height: 16),
            Text(
              'No assigned issues',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Issues will appear here once assigned to workers.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _assignedIssues.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildAssignedIssueCard(_assignedIssues[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssignedIssueCard(Issue issue) {
    final assignment = _getAssignmentForIssue(issue.ticketId);
    final worker = assignment != null ? _getWorkerByEmail(assignment.assignedTo) : null;
    final department = _getDepartmentForCategory(issue.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: issue.statusBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(issue.statusIcon, size: 20, color: issue.statusColor),
                const SizedBox(width: 8),
                Text(
                  issue.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: issue.statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  issue.ticketId,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: issue.priorityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    issue.priorityText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title.isNotEmpty ? issue.title : 'Untitled Issue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),

                // Worker Info
                if (worker != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF3B82F6),
                          child: Text(
                            worker.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                worker.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                worker.specialization,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                department?.name ?? 'Unknown Department',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Workload',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '${worker.currentWorkload}/${worker.maxCapacity}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (assignment != null) ...[
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Assigned: ${assignment.assignedAt}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  if (assignment.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note_outlined,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            assignment.notes,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showReassignmentDialog(assignment),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Reassign Worker'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                        side: const BorderSide(color: Color(0xFF3B82F6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersOverview() {
    final groupedWorkers = <String, List<Worker>>{};
    for (final worker in _workers) {
      final dept = _departments.firstWhere(
            (d) => d.id == worker.departmentId,
        orElse: () => Department(id: '', name: 'Unknown Department', categories: [], isActive: null, createdAt: ''),
      );
      groupedWorkers.putIfAbsent(dept.name, () => []).add(worker);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedWorkers.length,
      itemBuilder: (context, index) {
        final deptName = groupedWorkers.keys.elementAt(index);
        final workers = groupedWorkers[deptName]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.business_outlined,
                        color: const Color(0xFF3B82F6), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      deptName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${workers.length} workers',
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              ...workers.map((worker) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: worker.isAvailable
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                  child: Text(
                    worker.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  worker.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.specialization),
                    Text('${worker.experienceYears} years experience'),
                    Row(
                      children: [
                        Text('Workload: ${worker.currentWorkload}/${worker.maxCapacity}'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: worker.currentWorkload / worker.maxCapacity,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              worker.currentWorkload / worker.maxCapacity > 0.8
                                  ? Colors.red
                                  : worker.currentWorkload / worker.maxCapacity > 0.6
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Icon(
                  worker.isAvailable ? Icons.check_circle : Icons.cancel,
                  color: worker.isAvailable
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}