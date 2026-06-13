import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

class ClipboardContent {
  final String? text;
  final List<File> images;
  final bool hasText;
  final bool hasImages;

  ClipboardContent({
    this.text,
    this.images = const [],
  })  : hasText = text != null && text.isNotEmpty,
        hasImages = images.isNotEmpty;

  bool get isEmpty => !hasText && !hasImages;
  bool get isMixed => hasText && hasImages;

  @override
  String toString() {
    return 'ClipboardContent(text: $text, images: ${images.length}, hasText: $hasText, hasImages: $hasImages)';
  }
}

class ClipboardService {
  /// Detect and retrieve clipboard content
  /// Returns ClipboardContent with text, images, or both
  static Future<ClipboardContent> getClipboardContent() async {
    try {
      if (kIsWeb) {
        return await _getClipboardContentWeb();
      } else {
        return await _getClipboardContentNative();
      }
    } catch (e) {
      print('Clipboard error: $e');
      return ClipboardContent();
    }
  }

  /// Web implementation using JavaScript clipboard API
  static Future<ClipboardContent> _getClipboardContentWeb() async {
    try {
      // Try to read text from clipboard
      String? text;
      try {
        final dynamic clipboard = html.window.navigator.clipboard;
        final dynamic promise = clipboard.readText();
        text = await Future.value(promise).then((dynamic result) => result.toString()).timeout(
          const Duration(seconds: 2),
          onTimeout: () => '',
        );
        if (text == null || text.isEmpty) text = null;
      } catch (e) {
        print('Failed to read text from web clipboard: $e');
      }

      // Try to read images from clipboard
      List<File> images = [];
      try {
        // This is a simplified approach - full implementation would require more JS interop
        // For now, we focus on text content which is more reliable
      } catch (e) {
        print('Failed to read images from web clipboard: $e');
      }

      if (text != null && text.isNotEmpty) {
        return ClipboardContent(text: text, images: images);
      }

      return ClipboardContent(text: text, images: images);
    } catch (e) {
      print('Web clipboard error: $e');
      return ClipboardContent();
    }
  }

  /// Native implementation for mobile/desktop
  static Future<ClipboardContent> _getClipboardContentNative() async {
    String? text;
    List<File> images = [];

    try {
      // Get text from clipboard
      final data = await Clipboard.getData('text/plain');
      text = data?.text?.toString();
    } catch (e) {
      print('Failed to read text from native clipboard: $e');
    }

    // Note: Getting images from clipboard on native is complex
    // and requires platform-specific code. For now, we handle text.
    // Users can still use the file picker for images.

    return ClipboardContent(text: text, images: images);
  }

  /// Just get text from clipboard
  static Future<String?> getClipboardText() async {
    try {
      final content = await getClipboardContent();
      return content.text;
    } catch (e) {
      print('Error getting clipboard text: $e');
      return null;
    }
  }

  /// Clear clipboard (if supported)
  static Future<void> clearClipboard() async {
    try {
      if (!kIsWeb) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } catch (e) {
      print('Error clearing clipboard: $e');
    }
  }

  /// Detect content type
  static String detectContentType(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'empty';

    final urlRegex =
        RegExp(r'^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w\-./?%&=]*)?$', caseSensitive: false);
    final hasUrl = RegExp(r'https?:\/\/[^\s]+', caseSensitive: false);

    if (urlRegex.hasMatch(trimmed) || trimmed.startsWith('http') || trimmed.startsWith('www')) {
      return 'link';
    } else if (hasUrl.hasMatch(trimmed)) {
      return 'link';
    } else {
      return 'text';
    }
  }
}
