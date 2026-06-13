import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';
import '../models/item.dart';
import 'file_preview_modal.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;

  const ItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap ?? () {
          Navigator.pushNamed(context, '/detail', arguments: item.id);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: glassDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Type icon + Title ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDim.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.type == 'link' ? Icons.link : Icons.edit_note,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.displayTitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ─── Description ───
              Text(
                item.displayDescription,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // ─── Note Preview (if exists) ───
              if (item.notePreview != null && item.notePreview!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                    border: Border(
                      left: BorderSide(
                        color: _getNoteUrgencyColor(item.noteUrgency),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getNoteUrgencyEmoji(item.noteUrgency),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.notePreview!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // ─── File Attachment Indicator ───
              if (item.hasAttachment && item.fileCount > 0)
                GestureDetector(
                  onTap: () => showFilePreviewModal(
                    context,
                    files: item.files,
                    itemTitle: item.displayTitle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.attach_file,
                          size: 14,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.fileCount} file${item.fileCount > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight:FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (item.hasAttachment && item.fileCount > 0) const SizedBox(height: 12),

              // ─── Bottom Row: Categories + Tags + Time ───
              Row(
                children: [
                  // Category badge
                  if (item.categories.isNotEmpty) ...[
                    _buildCategoryBadge(item.categories.first),
                    const SizedBox(width: 8),
                  ],
                  // Tags
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: item.tags.take(3).map((tag) => Text(
                        '#${tag.name}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.secondary.withValues(alpha: 0.7),
                        ),
                      )).toList(),
                    ),
                  ),
                  // Source + timestamp
                  Text(
                    item.timeAgo,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),

              // ─── Source domain ───
              if (item.sourceUrl != null) ...[
                const SizedBox(height: 6),
                Text(
                  _extractDomain(item.sourceUrl!),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(Category category) {
    final color = AppTheme.categoryColors[category.name] ?? AppTheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.name,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _extractDomain(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  Color _getNoteUrgencyColor(String? urgency) {
    switch (urgency) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'important':
        return const Color(0xFFFCA311);
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  String _getNoteUrgencyEmoji(String? urgency) {
    switch (urgency) {
      case 'urgent':
        return '🔴';
      case 'important':
        return '🟡';
      default:
        return '⚪';
    }
  }
}
