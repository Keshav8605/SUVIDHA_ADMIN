import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> complaintsBySector = {
      'Sanitation & Waste': 24,
      'Water & Drainage': 18,
      'Electricity & Streetlights': 21,
      'Roads & Transport': 15,
      'Public Health & Safety': 12,
      'Environment & Parks': 8,
      'Building & Infrastructure': 14,
      'Taxes & Documentation': 6,
      'Emergency Services': 4,
      'Animal Care & Control': 3,
      'Other': 7,
    };

    final Map<String, int> statusData = {
      'In Progress': 45,
      'Completed': 68,
      'Critical': 18,
      'New': 21,
    };

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
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
              onPressed: () {},
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bar Chart
                Expanded(
                  flex: 2,
                  child: _buildChartCard(
                    title: 'Complaints by Category',
                    subtitle: 'Monthly breakdown',
                    child: _buildBarChart(complaintsBySector),
                  ),
                ),
                const SizedBox(width: 20),

                // Pie Chart
                Expanded(
                  flex: 1,
                  child: _buildChartCard(
                    title: 'Status Distribution',
                    subtitle: 'Current status overview',
                    child: _buildPieChart(statusData),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Activity Section
            _buildRecentActivityCard(),
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
            'Total Complaints',
            '152',
            Icons.analytics,
            const Color(0xFF3B82F6),
            '+18%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'In Progress',
            '45',
            Icons.pending_actions,
            const Color(0xFF10B981),
            '+12%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Completed',
            '68',
            Icons.check_circle,
            const Color(0xFF8B5CF6),
            '+25%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Critical',
            '18',
            Icons.warning,
            const Color(0xFFEF4444),
            '-5%',
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
    final bool isPositive = change.startsWith('+');

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
              Icon(Icons.more_horiz, color: const Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
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
                  '${barSpots[group.x.toInt()].key}\n${rod.toY.round()} complaints',
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
                      barSpots[index].key.split(' ')[0],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1);
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
    final total = data.values.reduce((a, b) => a + b);

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: data.entries.map((entry) {
                final percentage = (entry.value / total * 100);
                return PieChartSectionData(
                  color: _getStatusColor(entry.key),
                  value: entry.value.toDouble(),
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  badgeWidget: null,
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                enabled: true,
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: Column(
              children: data.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
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
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'View all',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActivityItem(
            'Water Logging - Scheme 45',
            'Water & Drainage',
            '1 hour ago',
            'high',
          ),
          _buildActivityItem(
            'Street Light Not Working',
            'Electricity & Streetlights',
            '3 hours ago',
            'medium',
          ),
          _buildActivityItem(
            'Garbage Collection Delayed',
            'Sanitation & Waste',
            '5 hours ago',
            'medium',
          ),
          _buildActivityItem(
            'Road Pothole Repair',
            'Roads & Transport',
            '8 hours ago',
            'low',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String category,
    String time,
    String priority,
  ) {
    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = const Color(0xFFEF4444);
        break;
      case 'medium':
        priorityColor = const Color(0xFFF59E0B);
        break;
      default:
        priorityColor = const Color(0xFF10B981);
    }

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
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Color _getPremiumColor(String key) {
    switch (key) {
      case 'Sanitation & Waste':
        return const Color(0xFF10B981); // Green
      case 'Water & Drainage':
        return const Color(0xFF06B6D4); // Cyan
      case 'Electricity & Streetlights':
        return const Color(0xFF3B82F6); // Blue
      case 'Roads & Transport':
        return const Color(0xFF8B5CF6); // Purple
      case 'Public Health & Safety':
        return const Color(0xFFEF4444); // Red
      case 'Environment & Parks':
        return const Color(0xFF22C55E); // Light Green
      case 'Building & Infrastructure':
        return const Color(0xFFF59E0B); // Amber
      case 'Taxes & Documentation':
        return const Color(0xFF6366F1); // Indigo
      case 'Emergency Services':
        return const Color(0xFFDC2626); // Dark Red
      case 'Animal Care & Control':
        return const Color(0xFF84CC16); // Lime
      case 'Other':
        return const Color(0xFF64748B); // Gray
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusColor(String key) {
    switch (key) {
      case 'In Progress':
        return const Color(0xFF3B82F6);
      case 'Completed':
        return const Color(0xFF10B981);
      case 'Critical':
        return const Color(0xFFEF4444);
      case 'New':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }
}
