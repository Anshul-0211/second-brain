import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

// Web-only import using conditional compilation
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show FileUploadInputElement;

class FilePickerService {
  static const List<String> allowedExtensions = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'txt', 'csv', 'json', 'xml',
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg',
    'zip', 'rar', '7z'
  ];

  /// Pick multiple files from device storage (web and mobile/desktop compatible)
  static Future<List<File>> pickFiles({
    String dialogTitle = 'Select Files',
    bool allowMultiple = true,
  }) async {
    try {
      // For web platform, use HTML file input instead of FilePicker
      if (kIsWeb) {
        return _pickFilesWeb(allowMultiple: allowMultiple);
      }

      // For mobile and desktop platforms
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: dialogTitle,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .map((file) => File(file.path!))
            .toList();
      }
      return [];
    } catch (e) {
      print('File picker error: $e');
      return [];
    }
  }

  /// Web-specific file picker using HTML file input
  static Future<List<File>> _pickFilesWeb({
    required bool allowMultiple,
  }) async {
    final completer = Completer<List<File>>();
    final input = html.FileUploadInputElement();
    input.accept = allowedExtensions.map((ext) => '.$ext').join(',');
    input.multiple = allowMultiple;

    final files = <File>[];

    input.onChange.listen((e) {
      final inputTarget = e.target as html.FileUploadInputElement;
      final filesList = inputTarget.files;

      if (filesList != null && filesList.isNotEmpty) {
        for (int i = 0; i < filesList.length; i++) {
          final file = filesList[i];
          // Create a File object from web File
          files.add(File(file.name));
        }
      }

      completer.complete(files);
    });

    input.click();
    return completer.future;
  }

  /// Pick image from camera or gallery
  static Future<File?> pickImage({
    required ImageSource source,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Image picker error: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  static Future<List<File>> pickImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultipleMedia();

      if (pickedFiles.isNotEmpty) {
        return pickedFiles
            .map((file) => File(file.path))
            .toList();
      }
      return [];
    } catch (e) {
      print('Image picker error: $e');
      return [];
    }
  }

  /// Get file size in readable format
  static String getFileSizeFormatted(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get file icon based on extension
  static String getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    
    switch (ext) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'ppt':
      case 'pptx':
        return '🎯';
      case 'txt':
      case 'csv':
      case 'json':
      case 'xml':
        return '📋';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'svg':
        return '🖼️';
      case 'zip':
      case 'rar':
      case '7z':
        return '📦';
      default:
        return '📎';
    }
  }
}
