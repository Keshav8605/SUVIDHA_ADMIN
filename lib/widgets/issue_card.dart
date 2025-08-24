import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/issue.dart';

class IssueCard extends StatefulWidget {
  final Issue issue;
  final Function(Issue, String) onStatusUpdate;

  const IssueCard({Key? key, required this.issue, required this.onStatusUpdate})
    : super(key: key);

  @override
  State<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<IssueCard>
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
      end: 1.01,
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
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? widget.issue.priorityColor.withOpacity(0.3)
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? widget.issue.priorityColor.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: _isHovered ? 20 : 8,
                    offset: Offset(0, _isHovered ? 8 : 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildHeader(), _buildContent(), _buildActions()],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.issue.priorityColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.issue.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.issue.ticketId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4C00FF),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildPriorityBadge(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meta information in a clean grid
          _buildMetaGrid(),
          const SizedBox(height: 40),
          Container(
            constraints: const BoxConstraints(
              maxHeight: 500, // Maximum allowed height
            ),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xffCBB4FF), width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Take minimum space needed
              children: [
                const Text(
                  "DESCRIPTION",
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff4C00FF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.issue.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  // will truncate after 5 lines within 80px
                ),
              ],
            ),
          ),

          // Description
          const SizedBox(height: 40),
          // Reports info
          _buildReportsInfo(),
        ],
      ),
    );
  }

  Widget _buildMetaGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive layout based on available width
        if (constraints.maxWidth > 400) {
          return Row(
            children: [
              Expanded(
                child: _buildMetaItem(
                  Icons.category_rounded,
                  widget.issue.category,
                  const Color(0xFF8B5CF6),
                  true,
                ),
              ),
              Expanded(
                child: _buildMetaItem(
                  Icons.location_on_rounded,
                  _truncateText(widget.issue.address, 25),
                  const Color(0xFF06B6D4),
                  true,
                ),
              ),
              Expanded(
                child: _buildMetaItem(
                  Icons.calendar_month,
                  _formatDate(widget.issue.createdAt),
                  const Color(0xFF84CC16),
                  false,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetaItem(
                      Icons.category_rounded,
                      widget.issue.category,
                      const Color(0xFF8B5CF6),
                      true,
                    ),
                  ),
                  Expanded(
                    child: _buildMetaItem(
                      Icons.calendar_month,
                      _formatDate(widget.issue.createdAt),
                      const Color(0xFF84CC16),
                      false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildMetaItem(
                Icons.location_on_rounded,
                widget.issue.address,
                const Color(0xFF06B6D4),
                true,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMetaItem(IconData icon, String text, Color color, bool have) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: have
          ? const EdgeInsets.only(right: 8)
          : EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.issue.priorityColor.withOpacity(0.08),
            widget.issue.priorityColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.issue.priorityColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_rounded,
            size: 18,
            color: widget.issue.priorityColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reported by ${widget.issue.users.length} user${widget.issue.users.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.issue.priorityColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${widget.issue.issueCount} reports',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showIssueDetails(),
              icon: const Icon(
                Icons.visibility_rounded,
                size: 16,
                color: Colors.black,
              ),
              label: const Text(
                'Details',
                style: TextStyle(color: Colors.black),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (widget.issue.status == 'new') ...[
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _showStatusUpdateDialog('in progress'),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Start Progress'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else if (widget.issue.status == 'in progress') ...[
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _showStatusUpdateDialog('completed'),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Mark Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else if (widget.issue.status == 'completed') ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF059669).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: const Color(0xFF059669),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Completed',
                      style: TextStyle(
                        color: const Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.issue.priorityColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: widget.issue.priorityColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPriorityIcon(), color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            widget.issue.priorityText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.issue.statusBackgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: widget.issue.statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: widget.issue.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            widget.issue.status.toUpperCase(),
            style: TextStyle(
              color: widget.issue.statusColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _formatDate(String dateStr) {
    // Simple date formatting - you can enhance this
    try {
      final parts = dateStr.split(' ');
      if (parts.isNotEmpty) {
        return parts[0]; // Return just the date part
      }
    } catch (e) {
      // Fallback
    }
    return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
  }

  IconData _getPriorityIcon() {
    switch (widget.issue.priorityText) {
      case 'Critical':
        return Icons.warning_rounded;
      case 'High':
        return Icons.priority_high_rounded;
      case 'Medium':
        return Icons.remove_rounded;
      default:
        return Icons.low_priority_rounded;
    }
  }

  void _showIssueDetails() {
    Uint8List? decodedBytes;
    if (widget.issue.photo != null)
      decodedBytes = base64Decode(widget.issue.photo!);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: widget.issue.priorityColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Issue Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Basic Information', [
                        if (widget.issue.photo != null)
                          Image.memory(decodedBytes!, fit: BoxFit.scaleDown),
                        _buildDetailRow('Ticket ID', widget.issue.ticketId),
                        _buildDetailRow('Title', widget.issue.title),
                        _buildDetailRow('Category', widget.issue.category),
                        _buildDetailRow('Status', widget.issue.status),
                        _buildDetailRow('Priority', widget.issue.priorityText),
                      ]),
                      const SizedBox(height: 20),
                      _buildDetailSection('Location & Time', [
                        _buildDetailRow('Address', widget.issue.address),
                        _buildDetailRow('Created At', widget.issue.createdAt),
                        _buildDetailRow(
                          'Total Reports',
                          widget.issue.issueCount.toString(),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildDetailSection('Description', [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            widget.issue.description,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildDetailSection('Reporters', [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.issue.users
                              .map(
                                (user) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.issue.priorityColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: widget.issue.priorityColor
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    user,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: widget.issue.priorityColor,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.issue.priorityColor,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.update_rounded, color: widget.issue.priorityColor),
            const SizedBox(width: 12),
            const Text('Update Status'),
          ],
        ),
        content: Text(
          'Are you sure you want to mark this issue as "$newStatus"?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onStatusUpdate(widget.issue, newStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.issue.priorityColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
