import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/notification_history.dart';

class NotificationHistoryService {
  static const String _boxName = 'notification_history';
  static Box<NotificationHistory>? _box;

  // Initialize Hive box
  static Future<void> initialize() async {
    try {
      // Register adapter if not already registered
      if (!Hive.isAdapterRegistered(3)) {
        // Manual adapter registration - temporary until build_runner works
        Hive.registerAdapter(NotificationHistoryAdapter());
      }

      _box = await Hive.openBox<NotificationHistory>(_boxName);
    } catch (e) {
      print('[NotificationHistoryService] Error initializing: $e');
    }
  }

  // Get box instance
  static Box<NotificationHistory> get _getBox {
    if (_box == null || !_box!.isOpen) {
      throw Exception('NotificationHistory box not initialized');
    }
    return _box!;
  }

  // Get current user ID from SharedPreferences
  static Future<int> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('userId') ?? 0;
    } catch (e) {
      print('[NotificationHistoryService] Error getting user ID: $e');
      return 0;
    }
  }

  // Save notification to history
  static Future<void> saveNotification(NotificationHistory notification) async {
    try {
      await _getBox.add(notification);
      print(
          '[NotificationHistoryService] Saved notification: ${notification.title}');
    } catch (e) {
      print('[NotificationHistoryService] Error saving notification: $e');
    }
  }

  // Get all notifications for current user (sorted by sent time, newest first)
  static Future<List<NotificationHistory>> getAllNotifications() async {
    try {
      final currentUserId = await _getCurrentUserId();
      final notifications = _getBox.values
          .where((notification) => notification.userId == currentUserId)
          .toList();
      notifications.sort((a, b) => b.sentTime.compareTo(a.sentTime));
      return notifications;
    } catch (e) {
      print('[NotificationHistoryService] Error getting notifications: $e');
      return [];
    }
  }

  // DEBUG: Get all notifications without user filtering
  static Future<List<NotificationHistory>> getAllNotificationsDebug() async {
    try {
      final notifications = _getBox.values.toList();
      notifications.sort((a, b) => b.sentTime.compareTo(a.sentTime));

      // Debug info
      final currentUserId = await _getCurrentUserId();
      print('[NotificationHistoryService] DEBUG:');
      print('  Current User ID: $currentUserId');
      print('  Total notifications in Hive: ${notifications.length}');

      for (int i = 0; i < notifications.length && i < 3; i++) {
        final notif = notifications[i];
        print(
            '  Notification $i: userId=${notif.userId}, title=${notif.title}');
      }

      return notifications;
    } catch (e) {
      print(
          '[NotificationHistoryService] Error getting all notifications debug: $e');
      return [];
    }
  }

  // Get unread notifications count
  static int getUnreadCount() {
    try {
      return _getBox.values
          .where((notification) => !notification.isRead)
          .length;
    } catch (e) {
      print('[NotificationHistoryService] Error getting unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(int notificationId) async {
    try {
      final notifications = _getBox.values.where(
          (notification) => notification.notificationId == notificationId);

      for (var notification in notifications) {
        notification.isRead = true;
        await notification.save();
      }
    } catch (e) {
      print('[NotificationHistoryService] Error marking as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final notifications =
          _getBox.values.where((notification) => !notification.isRead);

      for (var notification in notifications) {
        notification.isRead = true;
        await notification.save();
      }
    } catch (e) {
      print('[NotificationHistoryService] Error marking all as read: $e');
    }
  }

  // Delete notification
  static Future<void> deleteNotification(int notificationId) async {
    try {
      final keys = _getBox.keys.toList();
      for (var key in keys) {
        final notification = _getBox.get(key);
        if (notification?.notificationId == notificationId) {
          await _getBox.delete(key);
          break;
        }
      }
    } catch (e) {
      print('[NotificationHistoryService] Error deleting notification: $e');
    }
  }

  // Clear all notifications
  static Future<void> clearAll() async {
    try {
      await _getBox.clear();
    } catch (e) {
      print('[NotificationHistoryService] Error clearing all: $e');
    }
  }

  // Get notifications by ticket ID
  static List<NotificationHistory> getNotificationsByTicket(int ticketId) {
    try {
      final notifications = _getBox.values
          .where((notification) => notification.ticketId == ticketId)
          .toList();
      notifications.sort((a, b) => b.sentTime.compareTo(a.sentTime));
      return notifications;
    } catch (e) {
      print(
          '[NotificationHistoryService] Error getting notifications by ticket: $e');
      return [];
    }
  }
}

// Manual adapter - temporary until build_runner works
class NotificationHistoryAdapter extends TypeAdapter<NotificationHistory> {
  @override
  final int typeId = 3;

  @override
  NotificationHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationHistory(
      notificationId: fields[0] as int,
      ticketId: fields[1] as int,
      title: fields[2] as String,
      body: fields[3] as String,
      type: fields[4] as String,
      scheduledTime: fields[5] as DateTime,
      sentTime: fields[6] as DateTime,
      isRead: fields[7] as bool? ?? false,
      ticketTitle: fields[8] as String? ?? '',
      templeTitle: fields[9] as String? ?? '',
      userId: fields[10] as int? ?? 0, // Default for backward compatibility
    );
  }

  @override
  void write(BinaryWriter writer, NotificationHistory obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.notificationId)
      ..writeByte(1)
      ..write(obj.ticketId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.body)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.scheduledTime)
      ..writeByte(6)
      ..write(obj.sentTime)
      ..writeByte(7)
      ..write(obj.isRead)
      ..writeByte(8)
      ..write(obj.ticketTitle)
      ..writeByte(9)
      ..write(obj.templeTitle);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
