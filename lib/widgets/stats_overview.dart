import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/issue.dart';
import '../screens/analytics_screen.dart' hide Issue;

class StatsOverview extends StatelessWidget {
  final List<Issue> issues;
  final String selectedStatus;
  final String selectedCategory;
  final bool showCriticalOnly;
  final Function(String) onStatusFilterChanged;
  final Function() onShowAll;
  final Function() onShowCritical;

  const StatsOverview({
    Key? key,
    required this.issues,
    required this.selectedStatus,
    required this.selectedCategory,
    required this.showCriticalOnly,
    required this.onStatusFilterChanged,
    required this.onShowAll,
    required this.onShowCritical,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final newIssues = issues.where((i) => i.status == 'new').length;
    final inProgressIssues = issues
        .where((i) => i.status == 'in progress')
        .length;
    final completedIssues = issues.where((i) => i.status == 'completed').length;
    final criticalIssues = issues.where((i) => i.issueCount >= 10).length;

    final stats = [
      StatData(
        'Total Issues',
        issues.length.toString(),
        const Color(0xFF667EEA),
        Icons.dashboard_rounded,
        onTap: onShowAll,
        isActive:
            selectedStatus.isEmpty &&
            selectedCategory.isEmpty &&
            !showCriticalOnly,
        subtitle: 'All reports',
      ),
      StatData(
        'New Issues',
        newIssues.toString(),
        const Color(0xFFFF6B6B),
        Icons.fiber_new_rounded,
        onTap: () => onStatusFilterChanged('new'),
        isActive: selectedStatus == 'new',
        subtitle: 'Pending review',
      ),
      StatData(
        'In Progress',
        inProgressIssues.toString(),
        const Color(0xFF4ECDC4),
        Icons.work_outline_rounded,
        onTap: () => onStatusFilterChanged('in progress'),
        isActive: selectedStatus == 'in progress',
        subtitle: 'Being resolved',
      ),
      StatData(
        'Completed',
        completedIssues.toString(),
        const Color(0xFF56AB2F),
        Icons.check_circle_outline_rounded,
        onTap: () => onStatusFilterChanged('completed'),
        isActive: selectedStatus == 'completed',
        subtitle: 'Successfully resolved',
      ),
      StatData(
        'Critical',
        criticalIssues.toString(),
        const Color(0xFFFF416C),
        Icons.warning_rounded,
        onTap: onShowCritical,
        isActive: showCriticalOnly,
        subtitle: '10+ reports',
      ),
      StatData(
        'Analytics Overview',
        '',
        const Color(0xFF4C6EF5),
        Icons.bar_chart_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
          );
        },
        isActive: false,
        subtitle: 'View detailed insights',
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Always use column layout regardless of screen size
          return _buildColumnLayout(stats);
        },
      ),
    );
  }

  Widget _buildColumnLayout(List<StatData> stats) {
    return AnimationLimiter(
      child: Column(
        children: stats.asMap().entries.map((entry) {
          return AnimationConfiguration.staggeredList(
            position: entry.key,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key < stats.length - 1 ? 16 : 0,
                  ),
                  child: StatCard(stat: entry.value),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StatCard extends StatefulWidget {
  final StatData stat;

  const StatCard({Key? key, required this.stat}) : super(key: key);

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) {
              setState(() => _isHovered = true);
              _controller.forward();
            },
            onExit: (_) {
              setState(() => _isHovered = false);
              _controller.reverse();
            },
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.stat.onTap();
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.3,
                height: 110,
                decoration: BoxDecoration(
                  gradient: widget.stat.isActive
                      ? LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            widget.stat.color,
                            widget.stat.color.withOpacity(0.8),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.white, Colors.grey.shade50],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.stat.isActive
                        ? widget.stat.color.withOpacity(0.3)
                        : (_isHovered
                              ? widget.stat.color.withOpacity(0.3)
                              : Colors.grey.shade200),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.stat.isActive
                          ? widget.stat.color.withOpacity(0.3)
                          : Colors.black.withOpacity(_isHovered ? 0.1 : 0.05),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: Offset(0, _isHovered ? 8 : 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.stat.isActive
                              ? Colors.white.withOpacity(0.2)
                              : widget.stat.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.stat.icon,
                          color: widget.stat.isActive
                              ? Colors.white
                              : widget.stat.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Content section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.stat.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: widget.stat.isActive
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.stat.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: widget.stat.isActive
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Value section
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.stat.value,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: widget.stat.isActive
                                  ? Colors.white
                                  : widget.stat.color,
                            ),
                          ),
                          if (_isHovered || widget.stat.isActive) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.stat.isActive
                                    ? Colors.white.withOpacity(0.2)
                                    : widget.stat.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.stat.isActive ? 'Active' : 'Click',
                                style: TextStyle(
                                  color: widget.stat.isActive
                                      ? Colors.white
                                      : widget.stat.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StatData {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final String subtitle;

  StatData(
    this.title,
    this.value,
    this.color,
    this.icon, {
    required this.onTap,
    this.isActive = false,
    required this.subtitle,
  });
}
