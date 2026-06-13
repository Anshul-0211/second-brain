import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';

class InlineNoteInput extends StatefulWidget {
  final TextEditingController notesController;
  final Function(String) onNoteSaved;
  final bool isLoading;

  const InlineNoteInput({
    super.key,
    required this.notesController,
    required this.onNoteSaved,
    this.isLoading = false,
  });

  @override
  State<InlineNoteInput> createState() => _InlineNoteInputState();
}

class _InlineNoteInputState extends State<InlineNoteInput> {
  String _urgency = 'low-priority';

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'urgent':
        return const Color(0xFFEF4444); // Red
      case 'important':
        return const Color(0xFFFCA311); // Amber/Yellow
      default:
        return AppTheme.onSurfaceVariant; // Gray
    }
  }

  String _getUrgencyLabel(String urgency) {
    switch (urgency) {
      case 'urgent':
        return 'Urgent 🔴';
      case 'important':
        return 'Important 🟡';
      default:
        return 'Low Priority';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.outlineVariant,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Label ───
            Row(
              children: [
                Icon(Icons.sticky_note_2, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Add context note (optional)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ─── Note Input Field ───
            TextField(
              controller: widget.notesController,
              maxLines: 3,
              minLines: 2,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.onSurface,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Why did you save this? Context for later...',
                hintStyle: GoogleFonts.inter(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppTheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 10),

            // ─── Urgency Selector + Save Button ───
            Row(
              children: [
                // Urgency Dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: DropdownButton<String>(
                      value: _urgency,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: Text(
                        'Urgency',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'urgent',
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('Urgent'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'important',
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCA311),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('Important'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'low-priority',
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.onSurfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('Low Priority'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _urgency = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Save Button
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.isLoading
                          ? null
                          : () => widget.onNoteSaved(_urgency),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Center(
                          child: widget.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
