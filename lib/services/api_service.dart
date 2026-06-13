import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/item.dart';

class ApiService {
  // Change this to your Render URL after deployment
  static const String _baseUrl = 'http://localhost:3000';
  static const String _apiKey = 'dev-key'; // Match your server .env API_KEY

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
      };

  // ─── Items ───

  /// Create a new item (triggers processing pipeline)
  static Future<Map<String, dynamic>> createItem(String content) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/items'),
      headers: _headers,
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create item: ${response.body}');
  }

  /// Create item with file attachments (multipart upload)
  static Future<Item> createItemWithFiles(
    String content, {
    String? title,
    List<File> files = const [],
  }) async {
    if (files.isEmpty) {
      throw Exception('At least one file is required');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/items/upload'),
    );

    // Add headers (except Content-Type as MultipartRequest sets it)
    request.headers['x-api-key'] = _apiKey;

    // Add form fields
    request.fields['content'] = content;
    if (title != null) request.fields['title'] = title;

    // Add files
    for (final file in files) {
      request.files.add(
        await http.MultipartFile.fromPath('files', file.path),
      );
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return Item.fromJson(data['item']);
      }
      throw Exception('Failed to upload item: $responseBody');
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Get all items (paginated)
  static Future<List<Item>> getItems({int limit = 50, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/items?limit=$limit&offset=$offset'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['items'] as List)
          .map((item) => Item.fromJson(item))
          .toList();
    }
    throw Exception('Failed to fetch items: ${response.body}');
  }

  /// Get single enriched item
  static Future<Item> getItem(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/items/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Item.fromJson(data['item']);
    }
    throw Exception('Failed to fetch item: ${response.body}');
  }

  /// Delete an item
  static Future<void> deleteItem(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/items/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete item: ${response.body}');
    }
  }

  // ─── Notes ───

  /// Add a note to an item
  static Future<Map<String, dynamic>> createNote(String itemId, String content, {String urgency = 'low-priority'}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/items/$itemId/notes'),
      headers: _headers,
      body: jsonEncode({
        'content': content,
        'urgency': urgency,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['note'];
    }
    throw Exception('Failed to create note: ${response.body}');
  }

  /// Get all notes for an item
  static Future<List<Map<String, dynamic>>> getNotes(String itemId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/items/$itemId/notes'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['notes'] ?? []);
    }
    throw Exception('Failed to fetch notes: ${response.body}');
  }

  /// Update a note
  static Future<Map<String, dynamic>> updateNote(String itemId, String noteId, {String? content, String? urgency}) async {
    final body = <String, dynamic>{};
    if (content != null) body['content'] = content;
    if (urgency != null) body['urgency'] = urgency;

    final response = await http.put(
      Uri.parse('$_baseUrl/api/items/$itemId/notes/$noteId'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['note'];
    }
    throw Exception('Failed to update note: ${response.body}');
  }

  /// Delete a note
  static Future<void> deleteNote(String itemId, String noteId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/items/$itemId/notes/$noteId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete note: ${response.body}');
    }
  }

  // ─── Viewing Tracker ───

  /// Mark an item as opened/viewed
  static Future<Map<String, dynamic>> markItemAsOpened(String itemId) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/items/$itemId/view'),
      headers: _headers,
      body: jsonEncode({'opened': true}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['item'];
    }
    throw Exception('Failed to mark as opened: ${response.body}');
  }

  // ─── Entities ───

  /// Get all entities extracted from an item
  static Future<List<Map<String, dynamic>>> getEntities(String itemId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/items/$itemId/entities'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['entities'] ?? []);
    }
    throw Exception('Failed to fetch entities: ${response.body}');
  }

  // ─── Reminders ───

  /// Get all reminders for an item
  static Future<List<Map<String, dynamic>>> getReminders(String itemId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/items/$itemId/reminders'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['reminders'] ?? []);
    }
    throw Exception('Failed to fetch reminders: ${response.body}');
  }

  /// Get all pending reminders across all items
  static Future<List<Map<String, dynamic>>> getPendingReminders() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/reminders?limit=100'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['reminders'] ?? []);
    }
    throw Exception('Failed to fetch reminders: ${response.body}');
  }

  /// Create a manual reminder
  static Future<Map<String, dynamic>> createReminder(
    String itemId,
    String taskName,
    String dueDate, {
    String priority = 'medium',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/reminders'),
      headers: _headers,
      body: jsonEncode({
        'itemId': itemId,
        'taskName': taskName,
        'dueDate': dueDate,
        'priority': priority,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['reminder'];
    }
    throw Exception('Failed to create reminder: ${response.body}');
  }

  /// Update reminder status
  static Future<Map<String, dynamic>> updateReminderStatus(
    String reminderId,
    String status,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/reminders/$reminderId'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reminder'];
    }
    throw Exception('Failed to update reminder: ${response.body}');
  }

  /// Dismiss a reminder
  static Future<void> dismissReminder(String reminderId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/reminders/$reminderId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to dismiss reminder: ${response.body}');
    }
  }

  // ─── Recommendations ───

  /// Get today's recommendations
  static Future<List<dynamic>> getTodayRecommendations() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/recommendations/today'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data['recommendations'] ?? []);
    }
    throw Exception('Failed to fetch recommendations: ${response.body}');
  }

  /// Dismiss a recommendation
  static Future<void> dismissRecommendation(
    String recommendationId,
    String itemId, {
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/recommendations/$recommendationId/dismiss'),
      headers: _headers,
      body: jsonEncode({
        'itemId': itemId,
        if (reason != null) 'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to dismiss recommendation: ${response.body}');
    }
  }

  /// Trigger daily recommendations generation (admin only, for testing)
  static Future<Map<String, dynamic>> triggerRecommendationsGeneration() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/admin/trigger'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    }
    throw Exception('Failed to trigger recommendations: ${response.body}');
  }

  // ─── Search ───

  /// Semantic search
  static Future<List<Map<String, dynamic>>> search(String query, {double threshold = 0.4, int limit = 10}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/search'),
      headers: _headers,
      body: jsonEncode({
        'query': query,
        'threshold': threshold,
        'limit': limit,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['results'] ?? []);
    }
    throw Exception('Search failed: ${response.body}');
  }

  // ─── Tags & Categories ───

  static Future<List<Tag>> getTags() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/tags'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['tags'] as List).map((t) => Tag.fromJson(t)).toList();
    }
    throw Exception('Failed to fetch tags: ${response.body}');
  }

  static Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/categories'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['categories'] as List).map((c) => Category.fromJson(c)).toList();
    }
    throw Exception('Failed to fetch categories: ${response.body}');
  }

  // ─── Profile ───

  static Future<Map<String, dynamic>?> getProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/profile'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['profile'];
    }
    return null;
  }

  static Future<Map<String, dynamic>> createProfile(String displayName) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/profile'),
      headers: _headers,
      body: jsonEncode({'displayName': displayName}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create profile: ${response.body}');
  }

  // ─── Health Check ───

  static Future<bool> isServerRunning() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
