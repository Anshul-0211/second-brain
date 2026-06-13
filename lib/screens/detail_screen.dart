import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme.dart';
import '../models/item.dart';
import '../services/api_service.dart';

class DetailScreen extends StatefulWidget {
  final String itemId;
  const DetailScreen({super.key, required this.itemId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Item? _item;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _entities = [];
  bool _loadingReminders = false;
  bool _loadingEntities = false;

  @override
  void initState() {
    super.initState();
    _loadItem();
    _markAsViewed();
  }

  Future<void> _markAsViewed() async {
    try {
      final result = await ApiService.markItemAsOpened(widget.itemId);
      print('[DetailScreen] ✅ Item marked as opened');
      print('[DetailScreen] Response: opened=${result['opened']}, view_count=${result['view_count']}, opened_at=${result['opened_at']}');
    } catch (e) {
      print('[DetailScreen] ❌ Failed to mark as opened: $e');
    }
  }

  Future<void> _loadItem() async {
    try {
      final item = await ApiService.getItem(widget.itemId);
      setState(() {
        _item = item;
        _isLoading = false;
      });
      print('[DetailScreen] ✅ Item loaded: ${item.id}');
      
      // Load reminders and entities
      _loadReminders();
      _loadEntities();
    } catch (e) {
      print('[DetailScreen] ❌ Failed to load item: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReminders() async {
    if (_item == null) return;
    
    setState(() => _loadingReminders = true);
    try {
      final reminders = await ApiService.getReminders(widget.itemId);
      setState(() {
        _reminders = reminders;
        _loadingReminders = false;
      });
      print('[DetailScreen] ✅ Reminders loaded: ${reminders.length}');
      for (var r in reminders) {
        print('  - ${r['task_name']} (due: ${r['due_date']}, status: ${r['status']})');
      }
    } catch (e) {
      print('[DetailScreen] ⚠️ Failed to load reminders: $e');
      setState(() => _loadingReminders = false);
    }
  }

  Future<void> _loadEntities() async {
    if (_item == null) return;
    
    setState(() => _loadingEntities = true);
    try {
      final entities = await ApiService.getEntities(widget.itemId);
      setState(() {
        _entities = entities;
        _loadingEntities = false;
      });
      print('[DetailScreen] ✅ Entities loaded: ${entities.length}');
      for (var e in entities) {
        print('  - ${e['text']} (type: ${e['type']}, confidence: ${e['confidence']})');
      }
    } catch (e) {
      print('[DetailScreen] ⚠️ Failed to load entities: $e');
      setState(() => _loadingEntities = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Memory Detail',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_item != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              onPressed: _deleteItem,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: AppTheme.error)))
              : _item != null
                  ? _buildContent()
                  : const Center(child: Text('Item not found')),
    );
  }

  Widget _buildContent() {
    final item = _item!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Title ───
          Text(
            item.displayTitle,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
              height: 1.3,
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 12),

          // ─── Meta Row ───
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDim.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.typeEmoji} ${item.type.toUpperCase()}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Timestamp
              Text(
                'Saved ${item.timeAgo}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          // ─── Source URL ───
          if (item.sourceUrl != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchUrl(item.sourceUrl!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link, size: 14, color: AppTheme.secondary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.sourceUrl!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.secondary,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          ],

          const SizedBox(height: 20),

          // ─── Categories ───
          if (item.categories.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              children: item.categories.map((cat) {
                final color = AppTheme.categoryColors[cat.name] ?? AppTheme.outline;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    cat.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 12),
          ],

          // ─── Tags ───
          if (item.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.tags.map((tag) => Chip(
                label: Text('#${tag.name}'),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
            const SizedBox(height: 20),
          ],

          // ─── Reminders Section ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      _loadingReminders 
                        ? 'Reminders (loading...)'
                        : 'Reminders (${_reminders.length})',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loadingReminders)
                  const Center(
                    child: SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                      ),
                    ),
                  )
                else if (_reminders.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '📋 No reminders yet\nDump items with deadlines to create reminders',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reminders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      return _buildReminderItem(reminder);
                    },
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 280.ms),
          const SizedBox(height: 20),

          // ─── Entities Section ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.label_outline, size: 16, color: AppTheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      _loadingEntities 
                        ? 'Extracted Entities (loading...)'
                        : 'Extracted Entities (${_entities.length})',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loadingEntities)
                  const Center(
                    child: SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppTheme.secondary),
                      ),
                    ),
                  )
                else if (_entities.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '🏷️ No entities found\nEntities are automatically extracted from the content',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _entities.map((entity) {
                      final type = entity['type'] as String;
                      final text = entity['text'] as String;
                      final confidence = entity['confidence'] as double? ?? 0.8;
                      
                      Color typeColor;
                      String typeEmoji;
                      
                      switch (type) {
                        case 'TASK':
                          typeColor = Colors.blue;
                          typeEmoji = '✓';
                          break;
                        case 'DEADLINE':
                          typeColor = Colors.red;
                          typeEmoji = '📅';
                          break;
                        case 'PERSON':
                          typeColor = Colors.purple;
                          typeEmoji = '👤';
                          break;
                        case 'PROJECT':
                          typeColor = Colors.orange;
                          typeEmoji = '📂';
                          break;
                        case 'PRIORITY':
                          typeColor = Colors.amber;
                          typeEmoji = '⚡';
                          break;
                        default:
                          typeColor = Colors.grey;
                          typeEmoji = '•';
                      }
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(typeEmoji, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Text(
                              text,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 20),

          // ─── Debug Info Section ───
          if (item != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔍 Debug Info',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Viewed: ${item.opened ? '✅ Yes' : '❌ No'}\n'
                    'View Count: ${item.viewCount}\n'
                    'Last Viewed: ${item.lastViewedAt != null ? item.lastViewedAt!.toLocal().toString().split('.')[0] : 'Never'}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
          const SizedBox(height: 20),

          // ─── Notes Section ───
          if (item.notes.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sticky_note_2, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Notes (${item.notes.length})',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: item.notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final note = item.notes[index];
                      return _buildNoteItem(note);
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 280.ms),
            const SizedBox(height: 20),
          ],

          // ─── Content ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: glassDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Content',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  item.description ?? item.contentRaw,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.onSurface,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

          // ─── AI Summary ───
          if (item.aiSummary != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: glassDecoration(withGlow: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'AI Summary',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.aiSummary!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.onSurface.withValues(alpha: 0.9),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        title: Text('Delete Memory?', style: GoogleFonts.inter(color: AppTheme.onSurface)),
        content: Text(
          'This cannot be undone.',
          style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ApiService.deleteItem(widget.itemId);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildNoteItem(ItemNote note) {
    Color urgencyColor;
    String urgencyLabel;

    switch (note.urgency) {
      case 'urgent':
        urgencyColor = const Color(0xFFEF4444);
        urgencyLabel = 'Urgent';
        break;
      case 'important':
        urgencyColor = const Color(0xFFFCA311);
        urgencyLabel = 'Important';
        break;
      default:
        urgencyColor = AppTheme.onSurfaceVariant;
        urgencyLabel = 'Low Priority';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: urgencyColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: urgencyColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                urgencyLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: urgencyColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                note.timeAgo,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            note.content,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(Map<String, dynamic> reminder) {
    final taskName = reminder['task_name'] as String;
    final dueDate = DateTime.parse(reminder['due_date'] as String);
    final priority = reminder['priority'] as String? ?? 'medium';
    final status = reminder['status'] as String? ?? 'pending';

    // Calculate days until due
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    final daysUntilDue = difference.inDays;

    Color priorityColor;
    String priorityLabel;

    switch (priority.toLowerCase()) {
      case 'urgent':
        priorityColor = const Color(0xFFEF4444);
        priorityLabel = 'URGENT';
        break;
      case 'high':
        priorityColor = const Color(0xFFF97316);
        priorityLabel = 'HIGH';
        break;
      case 'medium':
        priorityColor = const Color(0xFFFBBF24);
        priorityLabel = 'MEDIUM';
        break;
      case 'low':
        priorityColor = Colors.grey;
        priorityLabel = 'LOW';
        break;
      default:
        priorityColor = Colors.grey;
        priorityLabel = 'MEDIUM';
    }

    String dueDateText;
    if (daysUntilDue < 0) {
      dueDateText = 'OVERDUE';
    } else if (daysUntilDue == 0) {
      dueDateText = 'TODAY';
    } else if (daysUntilDue == 1) {
      dueDateText = 'TOMORROW';
    } else if (daysUntilDue <= 7) {
      dueDateText = 'In $daysUntilDue days';
    } else {
      dueDateText = dueDate.toIso8601String().split('T')[0];
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                priorityLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: priorityColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dueDateText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status == 'completed'
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.replaceAll(RegExp(r'_'), '-').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: status == 'completed' ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            taskName,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
