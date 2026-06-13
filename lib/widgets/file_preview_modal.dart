import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item.dart';
import '../app/theme.dart';
import 'file_detail_modal.dart';

class FilePreviewModal extends StatelessWidget {
  final List<FileAttachment> files;
  final String itemTitle;

  const FilePreviewModal({
    Key? key,
    required this.files,
    required this.itemTitle,
  }) : super(key: key);

  String _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return '🖼️';
    if (mimeType == 'application/pdf') return '📄';
    if (mimeType.contains('word')) return '📝';
    if (mimeType.contains('sheet') || mimeType.contains('excel')) return '📊';
    if (mimeType.startsWith('text/')) return '📋';
    if (mimeType.contains('zip') || mimeType.contains('rar') || mimeType.contains('7z')) return '📦';
    return '📎';
  }

  void _openFile(BuildContext context, FileAttachment file) {
    showFileDetailModal(
      context,
      file: file,
      itemTitle: itemTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attachments',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          '${files.length} file${files.length > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppTheme.onSurface,
                  ),
                ],
              ),
            ),

            // ─── Files List ───
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(files.length, (index) {
                    final file = files[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildFileItem(context, file),
                    );
                  }),
                ),
              ),
            ),

            // ─── Info Text ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                border: Border(
                  top: BorderSide(
                    color: Colors.blue.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Text(
                'ℹ️ Files are stored securely in Supabase Storage with 7-day signed URLs',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.blue[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, FileAttachment file) {
    final icon = _getFileIcon(file.mimeType);
    
    return GestureDetector(
      onTap: () => _openFile(context, file),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File name and icon
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // File metadata
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.sizeFormatted,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        file.mimeType,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.blue,
                ),
              ],
            ),

            // Upload date
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Uploaded: ${file.uploadedAt.toString().split('.').first}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show file preview modal
void showFilePreviewModal(
  BuildContext context, {
  required List<FileAttachment> files,
  required String itemTitle,
}) {
  showDialog(
    context: context,
    builder: (context) => FilePreviewModal(
      files: files,
      itemTitle: itemTitle,
    ),
  );
}
