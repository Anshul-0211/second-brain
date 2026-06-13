import 'package:flutter/material.dart';
import 'dart:io';
import '../models/item.dart';
import '../services/api_service.dart';

class ItemsProvider extends ChangeNotifier {
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All';

  List<Item> get items {
    if (_selectedCategory == 'All') return _items;
    return _items.where((item) =>
      item.categories.any((c) => c.name == _selectedCategory)
    ).toList();
  }

  List<Item> get allItems => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  int get totalCount => _items.length;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await ApiService.getItems();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> addItem(String content) async {
    try {
      final result = await ApiService.createItem(content);
      // Reload items to get the full enriched list
      await loadItems();
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Item> addItemWithFiles(String content, {
    List<File> files = const [],
    String? title,
  }) async {
    try {
      final item = await ApiService.createItemWithFiles(
        content,
        title: title,
        files: files,
      );
      // Reload items to get the full enriched list
      await loadItems();
      return item;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await ApiService.deleteItem(id);
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addNoteToItem(String itemId, String content, {String urgency = 'low-priority'}) async {
    try {
      final note = await ApiService.createNote(itemId, content, urgency: urgency);
      // Reload items to get the updated notes
      await loadItems();
      return note;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

class SearchProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  String _query = '';
  String? _error;

  List<Map<String, dynamic>> get results => _results;
  bool get isSearching => _isSearching;
  String get query => _query;
  String? get error => _error;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _results = [];
      _query = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _query = query;
    _error = null;
    notifyListeners();

    try {
      _results = await ApiService.search(query);
    } catch (e) {
      _error = e.toString();
      _results = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _results = [];
    _query = '';
    _error = null;
    notifyListeners();
  }
}
