import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;
import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../app/theme.dart';

class FileDetailModal extends StatelessWidget {
  final FileAttachment file;
  final String itemTitle;

  const FileDetailModal({
    Key? key,
    required this.file,
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

  bool _isImageFile() {
    return file.mimeType.startsWith('image/');
  }

  bool _isPdfFile() {
    return file.mimeType == 'application/pdf';
  }

  Future<void> _downloadFile() async {
    try {
      if (kIsWeb) {
        // For web: Open the signed URL in a new tab
        // Browser will handle download automatically for most file types
        html.window.open(file.url, '_blank');
      } else {
        print('Download: Opening file ${file.name}');
      }
    } catch (e) {
      print('Download error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getFileIcon(file.mimeType);
    final isImage = _isImageFile();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
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
                  Text(icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'From: $itemTitle',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

            // ─── Preview/Content Area ───
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview
                    if (isImage)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.2),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            file.url,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported,
                                          size: 48,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Preview unavailable',
                                          style: GoogleFonts.inter(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    else if (_isPdfFile())
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('📄', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                'PDF File',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Click Download to view',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getFileIcon(file.mimeType),
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'File Preview',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Click Download to open',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // File details section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'File Details',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Name', file.name),
                          const SizedBox(height: 8),
                          _buildDetailRow('Size', file.sizeFormatted),
                          const SizedBox(height: 8),
                          _buildDetailRow('Type', file.mimeType),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Uploaded',
                            file.uploadedAt.toString().split('.').first,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Action Buttons ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _downloadFile(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.download, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Download',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      foregroundColor: AppTheme.onSurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Show file detail modal
void showFileDetailModal(
  BuildContext context, {
  required FileAttachment file,
  required String itemTitle,
}) {
  showDialog(
    context: context,
    builder: (context) => FileDetailModal(
      file: file,
      itemTitle: itemTitle,
    ),
  );
}
