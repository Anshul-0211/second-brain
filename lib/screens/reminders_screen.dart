import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scnd_brain/app/theme.dart';
import 'package:scnd_brain/services/api_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Map<String, dynamic>> _reminders = [];
  bool _loading = true;
  String _filterTag = 'all'; // all, overdue, today, upcoming

  final List<String> _filterOptions = ['all', 'overdue', 'today', 'upcoming'];
  final Map<String, String> _filterLabels = {
    'all': 'All Reminders',
    'overdue': '🔴 Overdue',
    'today': '🟡 Due Today',
    'upcoming': '🟢 Upcoming',
  };

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _loading = true);
    try {
      final reminders = await ApiService.getPendingReminders();
      setState(() => _reminders = reminders);
      print('✅ [RemindersScreen] Loaded ${reminders.length} reminders');
    } catch (e) {
      print('❌ [RemindersScreen] Failed to load reminders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reminders: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredReminders() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _reminders.where((reminder) {
      final dueDate = DateTime.parse(reminder['due_date'] as String);
      final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

      switch (_filterTag) {
        case 'overdue':
          return dueDateOnly.isBefore(today);
        case 'today':
          return dueDateOnly.isAtSameMomentAs(today);
        case 'upcoming':
          return dueDateOnly.isAfter(tomorrow) || dueDateOnly.isAtSameMomentAs(tomorrow);
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
      default:
        return Colors.grey;
    }
  }

  String _getPriorityEmoji(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return '🔴';
      case 'high':
        return '🟠';
      case 'medium':
        return '🟡';
      case 'low':
      default:
        return '⚪';
    }
  }

  String _getDaysUntil(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = dueDateOnly.difference(today).inDays;

    if (difference < 0) {
      return '${(-difference)} days overdue';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      return 'In $difference days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReminders = _getFilteredReminders();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppTheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reminders',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppTheme.onSurfaceVariant,
            onPressed: _loadReminders,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Filter Tags ───
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filterOptions.map((tag) {
                final isSelected = _filterTag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      _filterLabels[tag]!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                      ),
                    ),
                    backgroundColor: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
                    onSelected: (selected) {
                      setState(() => _filterTag = tag);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── Reminders List ───
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredReminders.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '✓ No reminders',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _filterTag == 'all'
                                    ? 'Dump items with deadlines to create reminders'
                                    : 'No reminders in this category',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredReminders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final reminder = filteredReminders[index];
                          final taskName = reminder['task_name'] as String;
                          final dueDate = DateTime.parse(reminder['due_date'] as String);
                          final priority = reminder['priority'] as String? ?? 'medium';
                          final status = reminder['status'] as String? ?? 'pending';
                          final reminderId = reminder['id'] as String;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Task name + Priority
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getPriorityEmoji(priority),
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            taskName,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.onSurface,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(priority).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _getPriorityColor(priority).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        priority.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _getPriorityColor(priority),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Due date
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${dueDate.toLocal().toString().split(' ')[0]} • ${_getDaysUntil(dueDate)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Action buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _updateReminderStatus(reminderId, 'completed'),
                                        icon: const Icon(Icons.check, size: 16),
                                        label: const Text('Complete'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          backgroundColor: Colors.green.withValues(alpha: 0.05),
                                          side: const BorderSide(color: Colors.green),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _updateReminderStatus(reminderId, 'dismissed'),
                                        icon: const Icon(Icons.close, size: 16),
                                        label: const Text('Dismiss'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateReminderStatus(String reminderId, String status) async {
    try {
      await ApiService.updateReminderStatus(reminderId, status);
      _loadReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder marked as $status')),
        );
      }
      print('✅ [RemindersScreen] Reminder updated to $status');
    } catch (e) {
      print('❌ [RemindersScreen] Failed to update reminder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update reminder: $e')),
        );
      }
    }
  }
}
