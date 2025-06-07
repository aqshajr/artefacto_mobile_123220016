import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../model/owned_ticket_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidInitialize =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSInitialize =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iOSInitialize,
    );

    await _notifications.initialize(initializationSettings);

    // Request permissions for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> scheduleTicketNotifications(OwnedTicket ticket) async {
    final validDate = tz.TZDateTime.from(ticket.validDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    // Notifikasi H-1 (jika masih ada waktu)
    final dayBefore = tz.TZDateTime(
      tz.local,
      validDate.year,
      validDate.month,
      validDate.day - 1,
      8, // 8 AM
      0,
      0,
    );

    if (dayBefore.isAfter(now)) {
      await _notifications.zonedSchedule(
        ticket.ownedTicketID.hashCode * 3,
        'Tiket Aktif Besok',
        'Tiket ${ticket.ticket?.temple?.templeName} akan aktif besok',
        dayBefore,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'ticket_reminder',
            'Pengingat Tiket',
            channelDescription: 'Notifikasi pengingat tiket wisata',
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Notifikasi saat hari-H
    final dayOf = tz.TZDateTime(
      tz.local,
      validDate.year,
      validDate.month,
      validDate.day,
      7, // 7 AM
      0,
      0,
    );

    if (dayOf.isAfter(now)) {
      await _notifications.zonedSchedule(
        ticket.ownedTicketID.hashCode * 3 + 1,
        'Tiket Dapat Digunakan',
        'Tiket ${ticket.ticket?.temple?.templeName} sudah dapat digunakan hari ini',
        dayOf,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'ticket_active',
            'Tiket Aktif',
            channelDescription: 'Notifikasi tiket yang sudah dapat digunakan',
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Notifikasi 1 jam sebelum kadaluarsa (17.00)
    final expiryNotification = tz.TZDateTime(
      tz.local,
      validDate.year,
      validDate.month,
      validDate.day,
      17, // 5 PM
      0,
      0,
    );

    if (expiryNotification.isAfter(now)) {
      await _notifications.zonedSchedule(
        ticket.ownedTicketID.hashCode * 3 + 2,
        'Tiket Akan Berakhir',
        'Tiket ${ticket.ticket?.temple?.templeName} akan berakhir dalam 1 jam',
        expiryNotification,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'ticket_expiry',
            'Tiket Berakhir',
            channelDescription: 'Notifikasi tiket yang akan berakhir',
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancelTicketNotifications(int ticketId) async {
    await _notifications.cancel(ticketId * 3); // H-1 notification
    await _notifications.cancel(ticketId * 3 + 1); // Day of notification
    await _notifications.cancel(ticketId * 3 + 2); // Expiry notification
  }
}
