class Item {
  final String id;
  final String type;
  final String contentRaw;
  final String? title;
  final String? description;
  final String? sourceUrl;
  final String? aiSummary;
  final double? confidenceScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Tag> tags;
  final List<Category> categories;
  final List<ItemNote> notes;
  final String? notePreview;
  final int noteCount;
  final String? noteUrgency;
  final bool opened;
  final int viewCount;
  final DateTime? lastViewedAt;
  final List<FileAttachment> files;
  final int fileCount;
  final bool hasAttachment;

  Item({
    required this.id,
    required this.type,
    required this.contentRaw,
    this.title,
    this.description,
    this.sourceUrl,
    this.aiSummary,
    this.confidenceScore,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.categories = const [],
    this.notes = const [],
    this.notePreview,
    this.noteCount = 0,
    this.noteUrgency,
    this.opened = false,
    this.viewCount = 0,
    this.lastViewedAt,
    this.files = const [],
    this.fileCount = 0,
    this.hasAttachment = false,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? '',
      type: json['type'] ?? 'note',
      contentRaw: json['content_raw'] ?? '',
      title: json['title'],
      description: json['description'],
      sourceUrl: json['source_url'],
      aiSummary: json['ai_summary'],
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      tags: (json['tags'] as List?)
              ?.map((t) => Tag.fromJson(t is Map<String, dynamic> ? t : {}))
              .toList() ??
          [],
      categories: (json['categories'] as List?)
              ?.map((c) => Category.fromJson(c is Map<String, dynamic> ? c : {}))
              .toList() ??
          [],
      notes: (json['notes'] as List?)
              ?.map((n) => ItemNote.fromJson(n is Map<String, dynamic> ? n : {}))
              .toList() ??
          [],
      notePreview: json['notePreview'],
      noteCount: json['noteCount'] ?? 0,
      noteUrgency: json['noteUrgency'],
      opened: json['opened'] ?? false,
      viewCount: json['view_count'] ?? 0,
      lastViewedAt: json['last_viewed_at'] != null ? DateTime.parse(json['last_viewed_at'] as String) : null,
      files: (json['files'] as List?)
              ?.map((f) => FileAttachment.fromJson(f is Map<String, dynamic> ? f : {}))
              .toList() ??
          [],
      fileCount: json['file_count'] ?? 0,
      hasAttachment: json['has_attachment'] ?? false,
    );
  }

  String get displayTitle => title ?? contentRaw.split('\n').first.substring(
      0, contentRaw.split('\n').first.length.clamp(0, 80));

  String get displayDescription =>
      description ?? contentRaw.substring(0, contentRaw.length.clamp(0, 200));

  String get typeEmoji {
    switch (type) {
      case 'link':
        return '🔗';
      case 'note':
        return '📝';
      case 'file':
        return '📁';
      default:
        return '📄';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

class FileAttachment {
  final String id;
  final String name;
  final String url;
  final int size;
  final String mimeType;
  final String storagePath;
  final DateTime uploadedAt;

  FileAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.size,
    required this.mimeType,
    required this.storagePath,
    required this.uploadedAt,
  });

  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      id: json['id'] ?? '',
      name: json['name'] ?? 'File',
      url: json['url'] ?? '',
      size: json['size'] ?? 0,
      mimeType: json['mime_type'] ?? 'application/octet-stream',
      storagePath: json['storage_path'] ?? '',
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileIcon {
    if (mimeType.startsWith('image/')) return '🖼️';
    if (mimeType == 'application/pdf') return '📄';
    if (mimeType.contains('word')) return '📝';
    if (mimeType.contains('sheet') || mimeType.contains('excel')) return '📊';
    if (mimeType.startsWith('text/')) return '📋';
    if (mimeType.contains('zip') || mimeType.contains('rar') || mimeType.contains('7z')) return '📦';
    return '📎';
  }
}

class Tag {
  final String id;
  final String name;

  Tag({required this.id, required this.name});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class Category {
  final String id;
  final String name;
  final String? color;

  Category({required this.id, required this.name, this.color});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'],
    );
  }
}

class ItemNote {
  final String id;
  final String itemId;
  final String content;
  final String urgency;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemNote({
    required this.id,
    required this.itemId,
    required this.content,
    required this.urgency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemNote.fromJson(Map<String, dynamic> json) {
    return ItemNote(
      id: json['id'] ?? '',
      itemId: json['item_id'] ?? '',
      content: json['content'] ?? '',
      urgency: json['urgency'] ?? 'low-priority',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get urgencyEmoji {
    switch (urgency) {
      case 'urgent':
        return '🔴';
      case 'important':
        return '🟡';
      default:
        return '⚪';
    }
  }

  String get urgencyLabel {
    switch (urgency) {
      case 'urgent':
        return 'Urgent';
      case 'important':
        return 'Important';
      default:
        return 'Low Priority';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}
