import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/item.dart';

class FilePreviewWidget extends StatelessWidget {
  final List<FileAttachment> files;
  final VoidCallback? onTap;

  const FilePreviewWidget({
    Key? key,
    required this.files,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '📎 ${files.length} attachment${files.length > 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: files.map((file) {
            return GestureDetector(
              onTap: onTap,
              child: Chip(
                avatar: Text(file.fileIcon, style: const TextStyle(fontSize: 16)),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      file.sizeFormatted,
                      maxLines: 1,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
                onDeleted: null, // No delete in preview mode
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Preview of files selected for upload (before upload)
class FileSelectionPreview extends StatelessWidget {
  final List<File> selectedFiles;
  final Function(int) onRemove;

  const FileSelectionPreview({
    Key? key,
    required this.selectedFiles,
    required this.onRemove,
  }) : super(key: key);

  String _getFileIcon(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return '📄';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return '🖼️';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'txt':
        return '📋';
      case 'zip':
      case 'rar':
      case '7z':
        return '📦';
      default:
        return '📎';
    }
  }

  String _getFileSizeFormatted(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (selectedFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '📎 Selected files: ${selectedFiles.length}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(selectedFiles.length, (index) {
            final file = selectedFiles[index];
            final name = file.path.split('/').last;
            final icon = _getFileIcon(name);
            
            // On web, we can't get file size from disk
            int sizeFile = 0;
            String sizeFormat = '--';
            if (!kIsWeb) {
              try {
                sizeFile = file.statSync().size;
                sizeFormat = _getFileSizeFormatted(sizeFile);
              } catch (e) {
                sizeFormat = '--';
              }
            }

            return Chip(
              avatar: Text(icon, style: const TextStyle(fontSize: 16)),
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    sizeFormat,
                    maxLines: 1,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
              onDeleted: () => onRemove(index),
              backgroundColor: Colors.orange.withOpacity(0.1),
              deleteIconColor: Colors.orange,
            );
          }),
        ),
      ],
    );
  }
}
