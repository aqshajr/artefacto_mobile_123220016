import 'package:hive/hive.dart';

// part 'notification_history.g.dart'; // Commented until build_runner works

@HiveType(typeId: 3)
class NotificationHistory extends HiveObject {
  @HiveField(0)
  int notificationId;

  @HiveField(1)
  int ticketId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String body;

  @HiveField(4)
  String type; // 'H-1', 'Day-H', 'Expiry'

  @HiveField(5)
  DateTime scheduledTime;

  @HiveField(6)
  DateTime sentTime;

  @HiveField(7)
  bool isRead;

  @HiveField(8)
  String ticketTitle;

  @HiveField(9)
  String templeTitle;

  @HiveField(10)
  int userId; // Add user ID to isolate notifications per user

  NotificationHistory({
    required this.notificationId,
    required this.ticketId,
    required this.title,
    required this.body,
    required this.type,
    required this.scheduledTime,
    required this.sentTime,
    this.isRead = false,
    this.ticketTitle = '',
    this.templeTitle = '',
    this.userId = 0, // Default to 0 for backward compatibility
  });

  // Format tanggal untuk display
  String get formattedSentTime {
    final now = DateTime.now();
    final difference = now.difference(sentTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} menit yang lalu';
      } else {
        return '${difference.inHours} jam yang lalu';
      }
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else {
      return '${difference.inDays} hari yang lalu';
    }
  }

  // Get icon based on notification type
  String get typeIcon {
    switch (type) {
      case 'H-1':
        return '⏰';
      case 'Day-H':
        return '🎉';
      case 'Expiry':
        return '⚠️';
      default:
        return '🔔';
    }
  }

  // Get type description
  String get typeDescription {
    switch (type) {
      case 'H-1':
        return 'Pengingat H-1';
      case 'Day-H':
        return 'Tiket Aktif';
      case 'Expiry':
        return 'Akan Berakhir';
      default:
        return 'Notifikasi';
    }
  }
}

// Manual adapter implementation since build_runner is not used
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
      userId:
          fields[10] as int? ?? 0, // Default to 0 for backward compatibility
    );
  }

  @override
  void write(BinaryWriter writer, NotificationHistory obj) {
    writer
      ..writeByte(11) // Updated field count
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
      ..write(obj.templeTitle)
      ..writeByte(10)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
