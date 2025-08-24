import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Your Issue model (make sure to import this from your model file)
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
  final List<String> users;
  final int issueCount;

  Issue({
    required this.ticketId,
    required this.category,
    required this.address,
    required this.location,
    required this.description,
    required this.title,
    this.photo,
    required this.status,
    required this.createdAt,
    required this.users,
    required this.issueCount,
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
    switch (status.toLowerCase()) {
      case 'new':
        return const Color(0xFFEA580C);
      case 'in progress':
        return const Color(0xFF2563EB);
      case 'completed':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color get statusBackgroundColor {
    switch (status.toLowerCase()) {
      case 'new':
        return const Color(0xFFFFF7ED);
      case 'in progress':
        return const Color(0xFFEFF6FF);
      case 'completed':
        return const Color(0xFFF0FDF4);
      default:
        return const Color(0xFFF9FAFB);
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'new':
        return Icons.fiber_new_rounded;
      case 'in progress':
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

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isRefreshing = false;
  bool _isLoading = true;
  List<Issue> _issues = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchIssues();
  }

  Future<void> _fetchIssues() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await http.get(
        Uri.parse('https://cdgi-backend-main.onrender.com/issues'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          _issues = jsonData.map((json) => Issue.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load issues. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading issues: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, int> get _complaintsBySector {
    final Map<String, int> sectorCounts = {};
    for (final issue in _issues) {
      final category = issue.category.isNotEmpty ? issue.category : 'Other';
      sectorCounts[category] = (sectorCounts[category] ?? 0) + 1;
    }
    return sectorCounts;
  }

  Map<String, int> get _statusData {
    final Map<String, int> statusCounts = {};
    for (final issue in _issues) {
      final status = _getFormattedStatus(issue.status);
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    return statusCounts;
  }

  String _getFormattedStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return 'New';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Other';
    }
  }

  int get _totalComplaints => _issues.length;

  int get _inProgressCount => _issues
      .where((issue) => issue.status.toLowerCase() == 'in progress')
      .length;

  int get _completedCount => _issues
      .where((issue) => issue.status.toLowerCase() == 'completed')
      .length;

  int get _criticalCount =>
      _issues.where((issue) => issue.issueCount >= 10).length;

  List<Issue> get _recentIssues {
    final sortedIssues = List<Issue>.from(_issues);
    sortedIssues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedIssues.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Analytics Overview'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Analytics Overview'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Error Loading Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchIssues,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Analytics Overview',
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
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF64748B),
                      ),
                    )
                  : const Icon(Icons.refresh, color: Color(0xFF64748B)),
              onPressed: _isRefreshing ? null : _handleRefresh,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards Row
            _buildStatsCards(),
            const SizedBox(height: 24),

            // Charts Section
            if (_issues.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bar Chart
                  Expanded(
                    flex: 2,
                    child: _buildChartCard(
                      title: 'Issues by Category',
                      subtitle: 'Distribution across sectors',
                      child: _buildBarChart(_complaintsBySector),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Pie Chart
                  Expanded(
                    flex: 1,
                    child: _buildChartCard(
                      title: 'Status Distribution',
                      subtitle: 'Current status overview',
                      child: _buildPieChart(_statusData),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Activity Section
              _buildRecentActivityCard(),
            ] else ...[
              // Empty state
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Icon(
                      Icons.analytics_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Data Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No issues found to display analytics',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Issues',
            _totalComplaints.toString(),
            Icons.analytics,
            const Color(0xFF3B82F6),
            '',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'In Progress',
            _inProgressCount.toString(),
            Icons.pending_actions,
            const Color(0xFF10B981),
            '',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Completed',
            _completedCount.toString(),
            Icons.check_circle,
            const Color(0xFF8B5CF6),
            '',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Critical',
            _criticalCount.toString(),
            Icons.warning,
            const Color(0xFFEF4444),
            '',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showChartOptions(context, title),
                child: const Icon(Icons.more_horiz, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: Text('No data available')),
      );
    }

    final barSpots = data.entries.toList();

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (data.values.reduce((a, b) => a > b ? a : b)).toDouble() + 5,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: const Color(0xFF1E293B),
              tooltipRoundedRadius: 8,
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${barSpots[group.x.toInt()].key}\n${rod.toY.round()} issues',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 80,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= barSpots.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      barSpots[index].key.length > 15
                          ? '${barSpots[index].key.substring(0, 12)}...'
                          : barSpots[index].key.replaceAll(' & ', '\n& '),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1);
            },
            drawVerticalLine: false,
          ),
          barGroups: barSpots.asMap().entries.map((entry) {
            final index = entry.key;
            final e = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  gradient: LinearGradient(
                    colors: [
                      _getPremiumColor(e.key),
                      _getPremiumColor(e.key).withOpacity(0.7),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 32,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> data) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: Text('No data available')),
      );
    }

    final total = data.values.reduce((a, b) => a + b);

    return SizedBox(
      height: 280,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: data.entries.map((entry) {
                  final percentage = (entry.value / total * 100);
                  return PieChartSectionData(
                    color: _getStatusColor(entry.key),
                    value: entry.value.toDouble(),
                    title: percentage > 8
                        ? '${percentage.toStringAsFixed(1)}%'
                        : '',
                    radius: 70,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    titlePositionPercentageOffset: 0.6,
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 45,
                pieTouchData: PieTouchData(enabled: true),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: data.entries.map((entry) {
              final percentage = (entry.value / total * 100);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key} (${percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Issues',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              GestureDetector(
                onTap: _handleViewAllActivity,
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._recentIssues.map((issue) => _buildActivityItem(issue)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Issue issue) {
    final timeAgo = _getTimeAgo(issue.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: issue.priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title.isNotEmpty ? issue.title : 'Untitled Issue',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  issue.category.isNotEmpty ? issue.category : 'Uncategorized',
                  style: const TextStyle(
                    fontSize: 12,
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
                timeAgo,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: issue.statusBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  issue.status.toLowerCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: issue.statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await _fetchIssues();

    setState(() {
      _isRefreshing = false;
    });

    if (mounted && _errorMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analytics data refreshed successfully'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleViewAllActivity() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'All Recent Issues',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _issues.length,
                itemBuilder: (context, index) =>
                    _buildActivityItem(_issues[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChartOptions(BuildContext context, String chartTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$chartTitle Options',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.download, color: Color(0xFF64748B)),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chart data exported successfully');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF64748B)),
              title: const Text('Share Chart'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chart shared successfully');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF3B82F6),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getPremiumColor(String key) {
    // Generate colors based on category name hash for consistency
    final hash = key.hashCode.abs();
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
      const Color(0xFFEC4899), // Pink
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF22C55E), // Light Green
    ];
    return colors[hash % colors.length];
  }

  Color _getStatusColor(String key) {
    switch (key.toLowerCase()) {
      case 'in progress':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF10B981);
      case 'new':
        return const Color(0xFF8B5CF6);
      case 'other':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }
}
