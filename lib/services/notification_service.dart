import 'dart:async';
import 'package:flutter/material.dart';

/// Mock notification service
/// In production, integrate with Firebase Cloud Messaging (FCM)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final StreamController<NotificationPayload> _notificationStream =
      StreamController<NotificationPayload>.broadcast();

  Stream<NotificationPayload> get onNotificationReceived =>
      _notificationStream.stream;

  bool _initialized = false;

  /// Initialize notification service
  /// In production, set up Firebase Cloud Messaging here
  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;
    print('[NotificationService] Initialized');

    // TODO: Add Firebase setup:
    // - Initialize Firebase
    // - Request notification permissions
    // - Listen for incoming messages

    // For development, listen for notification stream
    _setupDevelopmentListeners();
  }

  /// Setup development notification listeners (mock)
  void _setupDevelopmentListeners() {
    // Mock: simulate receiving notifications
    // In production, this would be Firebase Cloud Messaging
    print('[NotificationService] Development mode - listening for notifications');
  }

  /// Send a test notification (for testing)
  void sendTestNotification(NotificationPayload payload) {
    _notificationStream.add(payload);
  }

  /// Handle notification tap
  /// In production, this would be called by Firebase
  void handleNotificationTap(String reminderId, String itemId) {
    _notificationStream.add(
      NotificationPayload(
        reminderId: reminderId,
        itemId: itemId,
        taskName: 'Reminder',
        dueDate: DateTime.now(),
        priority: 'medium',
      ),
    );
  }

  /// Cleanup
  void dispose() {
    _notificationStream.close();
  }
}

class NotificationPayload {
  final String reminderId;
  final String itemId;
  final String taskName;
  final DateTime dueDate;
  final String priority;

  NotificationPayload({
    required this.reminderId,
    required this.itemId,
    required this.taskName,
    required this.dueDate,
    required this.priority,
  });

  /// Get readable due date string
  String get dueDateString {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays > 1) {
      return 'In ${difference.inDays} days';
    } else {
      return 'Overdue';
    }
  }

  /// Get priority color
  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Get priority emoji
  String get priorityEmoji {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return '🔴';
      case 'high':
        return '🟠';
      case 'medium':
        return '🟡';
      case 'low':
        return '⚪';
      default:
        return '⚪';
    }
  }
}
