import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- DATA MODELS ---
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

  Color get priorityColor {
    if (issueCount >= 10) return const Color(0xFFDC2626);
    if (issueCount >= 5) return const Color(0xFFEA580C);
    if (issueCount >= 2) return const Color(0xFFD97706);
    return const Color(0xFF059669);
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

// --- MAIN WIDGET ---
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // UI State
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isExporting = false;
  String _errorMessage = '';

  // Data
  List<Issue> _issues = [];
  List<Marker> _markers = [];
  final MapController _mapController = MapController();

  // OPTIMIZATION: Cached data
  Map<String, int> _cachedComplaintsBySector = {};
  Map<String, int> _cachedStatusData = {};
  List<Issue> _cachedRecentIssues = [];
  int _totalComplaints = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;
  int _criticalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchIssues();
  }

  // --- DATA HANDLING & CACHING ---
  Future<void> _fetchIssues() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://suvidha-backend-fmw2.onrender.com/issues'),
        headers: {'Content-Type': 'application/json'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> jsonData = json.decode(response.body);
          _issues = jsonData.map((json) => Issue.fromJson(json)).toList();
          _processAndCacheData();
          setState(() => _isLoading = false);
        } else {
          setState(() {
            _errorMessage = 'Failed to load issues. Status: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading issues: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// FINAL FIX: This function now uses the exact date format from your API.
  DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;
    try {
      // This format "HH:mm dd-MM-yyyy" EXACTLY matches "14:28 18-09-2025"
      return DateFormat("HH:mm dd-MM-yyyy").parse(dateString);
    } catch (e) {
      print('Failed to parse date "$dateString" with expected format.');
      // Fallback for standard ISO format, just in case
      try {
        return DateTime.parse(dateString);
      } catch (_) {
        return null;
      }
    }
  }

  void _processAndCacheData() {
    _totalComplaints = _issues.length;
    _inProgressCount = _issues.where((i) => i.status.toLowerCase() == 'in progress').length;
    _completedCount = _issues.where((i) => i.status.toLowerCase() == 'completed').length;
    _criticalCount = _issues.where((i) => i.issueCount >= 10).length;

    final Map<String, int> sectorCounts = {};
    final Map<String, int> statusCounts = {};
    for (final issue in _issues) {
      final category = issue.category.isNotEmpty ? issue.category : 'Other';
      sectorCounts[category] = (sectorCounts[category] ?? 0) + 1;
      final status = _getFormattedStatus(issue.status);
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    _cachedComplaintsBySector = sectorCounts;
    _cachedStatusData = statusCounts;

    final sortedIssues = List<Issue>.from(_issues);

    // UPDATED: More reliable date sorting using the new helper method
    sortedIssues.sort((a, b) {
      final dateA = _parseDate(a.createdAt);
      final dateB = _parseDate(b.createdAt);

      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA); // Correctly compare valid dates
      }
      // Puts issues with unreadable dates at the bottom of the list
      if (dateB == null) return -1;
      if (dateA == null) return 1;
      return 0;
    });

    _cachedRecentIssues = sortedIssues.take(5).toList();
    _createMarkers();
  }

  String _getFormattedStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new': return 'New';
      case 'in_progress':
      case 'in progress': return 'In Progress';
      case 'completed': return 'Completed';
      default: return 'Other';
    }
  }

  // --- EXPORT FUNCTIONALITY ---
  Future<void> _exportPdfReport() async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();

      final sortedIssues = List<Issue>.from(_issues)
        ..sort((a, b) {
          final dateA = _parseDate(a.createdAt);
          final dateB = _parseDate(b.createdAt);
          if (dateA != null && dateB != null) return dateB.compareTo(dateA);
          return 0;
        });

      final List<Issue> issuesForPdf = sortedIssues.take(20).toList();

      final imageFutures = issuesForPdf.map((issue) => _fetchImage(issue.photo)).toList();
      final images = await Future.wait(imageFutures);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          header: (context) => _buildPdfHeader(),
          footer: (context) => _buildPdfFooter(context),
          build: (context) => [
            _buildPdfSummaryPage(),
            pw.NewPage(),
            pw.Text('Latest 20 Issue Details',
                style:
                pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 15),
            pw.ListView.separated(
              itemBuilder: (context, index) {
                final issue = issuesForPdf[index];
                final imageResult = images[index];
                return _buildPdfIssueCard(issue, imageResult);
              },
              separatorBuilder: (context, index) => pw.SizedBox(height: 20),
              itemCount: issuesForPdf.length,
            ),
          ],
        ),
      );
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'latest_issues_report.pdf',
      );
      if (mounted) _showSnackBar('✅ PDF report exported successfully');
    } catch (e) {
      if (mounted) _showSnackBar('❌ Failed to export PDF: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportIssuesToCsv() async {
    setState(() => _isExporting = true);
    try {
      if (_issues.isEmpty) {
        _showSnackBar('No data to export.', isError: true);
        return;
      }
      final buffer = StringBuffer();
      buffer.writeln(
          'Ticket ID,Title,Category,Status,Priority,Address,Latitude,Longitude,Created At');

      final sortedIssues = List<Issue>.from(_issues)
        ..sort((a, b) {
          final dateA = _parseDate(a.createdAt);
          final dateB = _parseDate(b.createdAt);
          if (dateA != null && dateB != null) return dateB.compareTo(dateA);
          return 0;
        });

      for (final issue in sortedIssues) {
        buffer.writeln(
            '"${issue.ticketId}","${issue.title}","${issue.category}","${_getFormattedStatus(issue.status)}","${issue.priorityText}","${issue.address.replaceAll('"', '""')}","${issue.location.latitude}","${issue.location.longitude}","${issue.createdAt}"');
      }
      final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
      await FileSaver.instance.saveFile(
        name: 'full_issue_report.csv',
        bytes: bytes,
        mimeType: MimeType.csv,
      );
      if (mounted) _showSnackBar('✅ Full data exported successfully to CSV');
    } catch (e) {
      if (mounted) _showSnackBar('❌ Failed to export CSV: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export Options',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF8B5CF6)),
              title: const Text('Export PDF Report (Latest 20)'),
              subtitle: const Text('A visual summary of the most recent issues.'),
              onTap: () {
                Navigator.pop(context);
                _exportPdfReport();
              },
            ),
            const Divider(height: 20),
            ListTile(
              leading: const Icon(Icons.description_rounded,
                  color: Color(0xFF3B82F6)),
              title: const Text('Export All Data as CSV'),
              subtitle: const Text('The complete dataset for spreadsheet analysis.'),
              onTap: () {
                Navigator.pop(context);
                _exportIssuesToCsv();
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- UI & WIDGETS ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics Overview')),
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics Overview')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('Error Loading Data',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700])),
              const SizedBox(height: 8),
              Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: _fetchIssues, child: const Text('Retry')),
            ]),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Analytics Overview',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF64748B)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: _isRefreshing
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, color: Color(0xFF64748B)),
                onPressed: _isRefreshing ? null : _handleRefresh,
              ),
              IconButton(
                icon: const Icon(Icons.ios_share, color: Color(0xFF64748B)),
                onPressed: _isExporting ? null : _showExportOptions,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCards(),
                const SizedBox(height: 24),
                if (_issues.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildChartCard(
                          title: 'Issues by Category',
                          subtitle: 'Distribution across sectors',
                          child: _buildBarChart(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: _buildChartCard(
                          title: 'Status Distribution',
                          subtitle: 'Current status overview',
                          child: _buildPieChart(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildMapCard(),
                  const SizedBox(height: 24),
                  _buildRecentActivityCard(),
                ] else
                  _buildEmptyState(),
              ],
            ),
          ),
        ),
        if (_isExporting)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Generating Report...',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          decoration: TextDecoration.none)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard('Total Issues', _totalComplaints.toString(),
                Icons.analytics_outlined, const Color(0xFF3B82F6))),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard('In Progress', _inProgressCount.toString(),
                Icons.hourglass_top_rounded, const Color(0xFFF59E0B))),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard('Completed', _completedCount.toString(),
                Icons.check_circle_outline_rounded, const Color(0xFF10B981))),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard('Critical', _criticalCount.toString(),
                Icons.warning_amber_rounded, const Color(0xFFEF4444))),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 16),
        Text(value,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 4),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildChartCard(
      {required String title,
        required String subtitle,
        required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (_cachedComplaintsBySector.isEmpty) {
      return const SizedBox(
          height: 280, child: Center(child: Text('No data available')));
    }
    final barSpots = _cachedComplaintsBySector.entries.toList();
    final maxY =
        (_cachedComplaintsBySector.values.reduce((a, b) => a > b ? a : b))
            .toDouble() +
            5;

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                      '${barSpots[group.x.toInt()].key}\n${rod.toY.round()} issues',
                      const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500)))),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 80,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= barSpots.length) return const SizedBox();
                  final key = barSpots[index].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      key.length > 15
                          ? '${key.substring(0, 12)}...'
                          : key.replaceAll(' & ', '\n& '),
                      style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
              show: true,
              horizontalInterval: 5,
              getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
              drawVerticalLine: false),
          barGroups: barSpots.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  gradient: LinearGradient(colors: [
                    _getCategoryColor(entry.value.key),
                    _getCategoryColor(entry.value.key).withOpacity(0.7)
                  ], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                  width: 32,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (_cachedStatusData.isEmpty) {
      return const SizedBox(
          height: 280, child: Center(child: Text('No data available')));
    }
    final total = _cachedStatusData.values.isNotEmpty
        ? _cachedStatusData.values.reduce((a, b) => a + b)
        : 1;

    return SizedBox(
      height: 280,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: _cachedStatusData.entries.map((entry) {
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
                        fontSize: 11),
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 45,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: _cachedStatusData.entries.map((entry) {
              final percentage = (entry.value / total * 100);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: _getStatusColor(entry.key),
                          shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${entry.key} (${percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500)),
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Issues',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
              GestureDetector(
                onTap: _handleViewAllActivity,
                child: const Text('View all',
                    style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._cachedRecentIssues.map((issue) => _buildActivityItem(issue)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Issue issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: issue.priorityColor, shape: BoxShape.circle)),
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
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(
                    issue.category.isNotEmpty
                        ? issue.category
                        : 'Uncategorized',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_getTimeAgo(issue.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: issue.statusBackgroundColor,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(issue.status.toLowerCase(),
                    style: TextStyle(
                        fontSize: 10,
                        color: issue.statusColor,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 60),
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No Data Available',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
          SizedBox(height: 8),
          Text('No issues found to display analytics',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- MAP & PDF HELPERS ---
  void _createMarkers() {
    final List<Marker> newMarkers = [];
    for (final issue in _issues) {
      if (issue.location.latitude != 0.0 && issue.location.longitude != 0.0) {
        newMarkers.add(
          Marker(
            point: LatLng(issue.location.latitude, issue.location.longitude),
            width: 80,
            height: 80,
            child: Tooltip(
              message: "${issue.title}\nPriority: ${issue.priorityText}",
              child: Icon(
                Icons.location_pin,
                color: _getMarkerColor(issue.priorityText),
                size: 40,
              ),
            ),
          ),
        );
      }
    }
    setState(() {
      _markers = newMarkers;
    });
  }

  Color _getMarkerColor(String priority) {
    switch (priority) {
      case 'Critical': return Colors.red;
      case 'High': return Colors.orange;
      case 'Medium': return Colors.amber;
      default: return Colors.green;
    }
  }

  Widget _buildMapCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Issue Locations',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B))),
                  Text('Geographic distribution of issues',
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF64748B))),
                ],
              ),
              Row(
                children: [
                  _buildMapLegendItem('Critical', Colors.red),
                  const SizedBox(width: 12),
                  _buildMapLegendItem('High', Colors.orange),
                  const SizedBox(width: 12),
                  _buildMapLegendItem('Medium', Colors.amber),
                  const SizedBox(width: 12),
                  _buildMapLegendItem('Low', Colors.green),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(23.2599, 77.4126), // Bhopal, India
                initialZoom: 11.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app', // Replace with your app's package name
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfHeader() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Analytics Report',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800)),
          pw.Text('Generated: ${DateTime.now().toString().substring(0, 16)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Platform Report',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfStatText(String title, String value) {
    return pw.Column(children: [
      pw.Text(value,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 2),
      pw.Text(title,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
    ]);
  }

  pw.Widget _buildPdfIssueCard(Issue issue, dynamic imageResult) {
    final lat = issue.location.latitude == 0.0 ? 'Not Provided' : issue.location.latitude.toStringAsFixed(5);
    final lon = issue.location.longitude == 0.0 ? 'Not Provided' : issue.location.longitude.toStringAsFixed(5);

    pw.Widget imageWidget;
    if (imageResult is pw.ImageProvider) {
      imageWidget = pw.Image(imageResult, fit: pw.BoxFit.cover);
    } else {
      imageWidget = pw.Container(
        color: PdfColors.grey200,
        child: pw.Center(
          child: pw.Text(
            imageResult ?? 'No photo provided',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(issue.title.isNotEmpty ? issue.title : 'Untitled Issue', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.SizedBox(height: 5),
                pw.Text('ID: ${issue.ticketId}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Divider(height: 10),
                _buildPdfInfoRow('Status:', issue.status),
                _buildPdfInfoRow('Category:', issue.category),
                _buildPdfInfoRow('Priority:', issue.priorityText),
                _buildPdfInfoRow('Address:', issue.address),
                _buildPdfInfoRow('Latitude:', lat),
                _buildPdfInfoRow('Longitude:', lon),
              ],
            ),
          ),
          pw.SizedBox(width: 15),
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              height: 100,
              child: imageWidget,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 60,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }

  Future<dynamic> _fetchImage(String? base64String) async {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }
    try {
      final String actualBase64 = base64String.contains(',')
          ? base64String.substring(base64String.indexOf(',') + 1)
          : base64String;

      final Uint8List imageBytes = base64Decode(actualBase64);
      return pw.MemoryImage(imageBytes);
    } catch (e) {
      print("Could not decode Base64 image for PDF: $e");
      return 'Invalid photo data';
    }
  }

  pw.Widget _buildPdfSummaryPage() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('📊 Analytics Report',
            style:
            pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 25),
        pw.Text('Summary Statistics',
            style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800)),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPdfStatText('Total Issues', _totalComplaints.toString()),
              _buildPdfStatText('In Progress', _inProgressCount.toString()),
              _buildPdfStatText('Completed', _completedCount.toString()),
              _buildPdfStatText('Critical', _criticalCount.toString()),
            ],
          ),
        ),
        pw.SizedBox(height: 25),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Issues by Category',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Table.fromTextArray(
                      data: [
                        ['Category', 'Count', '%'],
                        ..._cachedComplaintsBySector.entries.map((e) => [
                          e.key,
                          e.value.toString(),
                          '${(_totalComplaints > 0 ? (e.value / _totalComplaints) * 100 : 0).toStringAsFixed(1)}%'
                        ]),
                      ],
                      headerStyle:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey200),
                    ),
                  ]),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Status Distribution',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    data: [
                      ['Status', 'Count', '%'],
                      ..._cachedStatusData.entries.map((e) => [
                        e.key,
                        e.value.toString(),
                        '${(_totalComplaints > 0 ? (e.value / _totalComplaints) * 100 : 0).toStringAsFixed(1)}%'
                      ]),
                    ],
                    headerStyle:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- OTHER HELPERS & HANDLERS ---
  String _getTimeAgo(String dateString) {
    try {
      final date = _parseDate(dateString);
      if (date == null) return 'Invalid date';
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _fetchIssues();
    setState(() => _isRefreshing = false);
    if (mounted && _errorMessage.isEmpty) {
      _showSnackBar('✅ Analytics data refreshed successfully');
    }
  }

  void _handleViewAllActivity() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
                padding: EdgeInsets.all(20),
                child: Text('All Issues',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B)))),
            Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _issues.length,
                    itemBuilder: (context, index) {
                      final sortedIssues = List<Issue>.from(_issues)
                        ..sort((a,b) {
                          final dateA = _parseDate(a.createdAt);
                          final dateB = _parseDate(b.createdAt);
                          if(dateA != null && dateB != null) return dateB.compareTo(dateA);
                          return 0;
                        });
                      return _buildActivityItem(sortedIssues[index]);
                    })),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getCategoryColor(String key) {
    final hash = key.hashCode.abs();
    final colors = [
      const Color(0xFF3B82F6), const Color(0xFF10B981),
      const Color(0xFF8B5CF6), const Color(0xFFEF4444),
      const Color(0xFFF59E0B), const Color(0xFF06B6D4),
      const Color(0xFF84CC16), const Color(0xFFEC4899),
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
      default:
        return const Color(0xFF64748B);
    }
  }
}