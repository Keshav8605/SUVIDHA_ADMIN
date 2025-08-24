import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/issue.dart';
import '../services/api_service.dart';
import '../widgets/issue_card.dart';
import '../widgets/filter_bar.dart';
import '../widgets/stats_overview.dart';
import '../widgets/loading_shimmer.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  List<Issue> issues = [];
  List<Issue> filteredIssues = [];
  List<String> categories = [];
  bool isLoading = true;
  String selectedCategory = '';
  String selectedStatus = '';
  String sortBy = 'priority';
  bool showCriticalOnly = false;

  late AnimationController _refreshController;
  late AnimationController _filterController;
  late Animation<double> _refreshAnimation;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _refreshAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );
    _filterAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _filterController, curve: Curves.easeOutBack),
    );

    loadData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    _refreshController.forward();

    try {
      final [issuesData, categoriesData] = await Future.wait([
        ApiService.getIssues(),
        ApiService.getCategories(),
      ]);

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        issues = issuesData as List<Issue>;
        categories = categoriesData as List<String>;
        filteredIssues = List.from(issues);
        isLoading = false;
      });

      _applyFiltersAndSort();
      _refreshController.reset();
    } catch (e) {
      setState(() => isLoading = false);
      _refreshController.reset();
      _showErrorSnackBar('Error loading data: $e');
    }
  }

  void _applyFiltersAndSort() {
    _filterController.forward().then((_) => _filterController.reset());

    setState(() {
      filteredIssues = issues.where((issue) {
        bool categoryMatch =
            selectedCategory.isEmpty || issue.category == selectedCategory;
        bool statusMatch =
            selectedStatus.isEmpty || issue.status == selectedStatus;
        bool criticalMatch = !showCriticalOnly || issue.issueCount >= 10;
        return categoryMatch && statusMatch && criticalMatch;
      }).toList();

      switch (sortBy) {
        case 'priority':
          filteredIssues.sort((a, b) => b.issueCount.compareTo(a.issueCount));
          break;
        case 'date':
          filteredIssues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'category':
          filteredIssues.sort((a, b) => a.category.compareTo(b.category));
          break;
      }
    });
  }

  void _handleStatusFilter(String status) {
    HapticFeedback.mediumImpact();
    setState(() {
      selectedStatus = status;
      selectedCategory = '';
      showCriticalOnly = false;
    });
    _applyFiltersAndSort();
    _showFilterSnackBar(
      'Filtered by status: ${status.isEmpty ? 'All' : status}',
      const Color(0xFF667EEA),
    );
  }

  void _handleShowAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      selectedStatus = '';
      selectedCategory = '';
      showCriticalOnly = false;
    });
    _applyFiltersAndSort();
    _showFilterSnackBar('Showing all issues', const Color(0xFF667EEA));
  }

  void _handleShowCritical() {
    HapticFeedback.mediumImpact();
    setState(() {
      selectedStatus = '';
      selectedCategory = '';
      showCriticalOnly = true;
    });
    _applyFiltersAndSort();
    _showFilterSnackBar(
      'Showing critical issues only',
      const Color(0xFFFF416C),
    );
  }

  Future<void> _updateIssueStatus(Issue issue, String newStatus) async {
    final success = await ApiService.updateIssueStatus(
      issue.ticketId,
      newStatus,
    );
    if (success) {
      setState(() {
        final index = issues.indexWhere((i) => i.ticketId == issue.ticketId);
        if (index != -1) {
          issues[index] = issue.copyWith(status: newStatus);
        }
      });
      _applyFiltersAndSort();
      _showSuccessSnackBar('Issue status updated successfully');
    } else {
      _showErrorSnackBar('Failed to update issue status');
    }
  }

  void _showFilterSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
        elevation: 8,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.error_outline, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFFF416C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle_outline, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF56AB2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: _buildAppBar(),
          ),
          Expanded(child: isLoading ? LoadingShimmer() : _buildBody()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage("assets/sher.webp")),
              // gradient: const LinearGradient(
              //   colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              // ),
              borderRadius: BorderRadius.circular(16),
              //   boxShadow: [
              //     BoxShadow(
              //       color: const Color(0xFF667EEA).withOpacity(0.3),
              //       blurRadius: 12,
              //       offset: const Offset(0, 4),
              //     ),
              //   ],
              // ),
              // child: const Icon(
              //   Icons.admin_panel_settings,
              //   color: Colors.white,
              //   size: 28,
              // ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SUVIDHA Admin Portal',
                style: TextStyle(
                  letterSpacing: 1,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'जन सुविधा एवं शिकायत निवारण',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        AnimatedBuilder(
          animation: _refreshAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _refreshAnimation.value * 2 * 3.14159,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667EEA).withOpacity(0.1),
                      const Color(0xFF764BA2).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: isLoading ? null : loadData,
                  tooltip: 'Refresh Data',
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF667EEA),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBody() {
    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return Column(
          children: [
            const SizedBox(height: 20),
            FilterBar(
              categories: categories,
              selectedCategory: selectedCategory,
              selectedStatus: selectedStatus,
              sortBy: sortBy,
              showCriticalOnly: showCriticalOnly,
              onCategoryChanged: (category) {
                setState(() {
                  selectedCategory = category;
                  showCriticalOnly = false;
                });
                _applyFiltersAndSort();
              },
              onStatusChanged: (status) {
                setState(() {
                  selectedStatus = status;
                  showCriticalOnly = false;
                });
                _applyFiltersAndSort();
              },
              onSortChanged: (sort) {
                setState(() => sortBy = sort);
                _applyFiltersAndSort();
              },
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: filteredIssues.isEmpty
                        ? _buildEmptyState()
                        : _buildIssuesList(),
                  ),
                  SingleChildScrollView(
                    child: StatsOverview(
                      issues: issues,
                      selectedStatus: selectedStatus,
                      selectedCategory: selectedCategory,
                      showCriticalOnly: showCriticalOnly,
                      onStatusFilterChanged: _handleStatusFilter,
                      onShowAll: _handleShowAll,
                      onShowCritical: _handleShowCritical,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String emptyMessage = 'No issues found';
    String emptySubMessage = 'Try adjusting your filters to see more results';
    IconData emptyIcon = Icons.inbox_rounded;
    Color emptyColor = Colors.grey[400]!;

    if (showCriticalOnly) {
      emptyMessage = 'No critical issues! 🎉';
      emptySubMessage = 'Excellent! All issues are under control';
      emptyIcon = Icons.celebration_rounded;
      emptyColor = const Color(0xFF56AB2F);
    } else if (selectedStatus.isNotEmpty) {
      emptyMessage = 'No ${selectedStatus} issues found';
      emptySubMessage = 'Try selecting a different status or clear filters';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  emptyColor.withOpacity(0.1),
                  emptyColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: emptyColor.withOpacity(0.2), width: 2),
            ),
            child: Icon(emptyIcon, size: 80, color: emptyColor),
          ),
          const SizedBox(height: 32),
          Text(
            emptyMessage,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: emptyColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            emptySubMessage,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (selectedStatus.isNotEmpty ||
              selectedCategory.isNotEmpty ||
              showCriticalOnly) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _handleShowAll,
                icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
                label: const Text(
                  'Clear All Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIssuesList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: filteredIssues.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 100.0,
              child: FadeInAnimation(
                child: IssueCard(
                  issue: filteredIssues[index],
                  onStatusUpdate: _updateIssueStatus,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
