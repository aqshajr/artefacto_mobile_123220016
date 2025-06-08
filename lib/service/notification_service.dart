import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../model/owned_ticket_model.dart';
import '../model/notification_history.dart';
import 'notification_history_service.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tiket_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      print('[NotificationService] Initializing notification service...');

      // Request notification permissions
      await _requestNotificationPermissions();

      // Initialize time zones
      tz.initializeTimeZones();

      // Use local timezone (simpler approach)
      tz.setLocalLocation(tz.local);

      print('[NotificationService] Timezone set to: ${tz.local}');

      // Initialize notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(initializationSettings);

      // Test if notifications are working
      bool isEnabled = await _areNotificationsEnabled();
      print('[NotificationService] Notifications enabled: $isEnabled');

      print('[NotificationService] ✅ Initialization completed successfully');
    } catch (e) {
      print('[NotificationService] ❌ Initialization failed: $e');
    }

    // Initialize notification history service
    await NotificationHistoryService.initialize();

    // Request permissions for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request permissions for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request exact alarm permission for Android 12+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  // Request notification permissions
  static Future<void> _requestNotificationPermissions() async {
    try {
      // Request Android 13+ notification permission
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      // Request exact alarm permission for precise scheduling
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }

      final notificationStatus = await Permission.notification.status;
      final alarmStatus = await Permission.scheduleExactAlarm.status;

      print(
          '[NotificationService] Notification permission: $notificationStatus');
      print('[NotificationService] Exact alarm permission: $alarmStatus');
    } catch (e) {
      print('[NotificationService] Permission request error: $e');
    }
  }

  // Check if notifications are enabled
  static Future<bool> _areNotificationsEnabled() async {
    try {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    } catch (e) {
      print('[NotificationService] Error checking notification status: $e');
      return false;
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('[NotificationService] Notification tapped: ${response.payload}');

    // Parse payload to get notification info
    if (response.payload != null) {
      try {
        final parts = response.payload!.split('|');
        if (parts.length >= 2) {
          final notificationId = int.parse(parts[0]);
          final type = parts[1];

          // Mark as read in history
          NotificationHistoryService.markAsRead(notificationId);

          // Log notification received
          _logNotificationReceived(notificationId, type);
        }
      } catch (e) {
        print('[NotificationService] Error parsing notification payload: $e');
      }
    }
  }

  // Log when notification is actually received/tapped
  static void _logNotificationReceived(int notificationId, String type) {
    print(
        '[NotificationService] Notification received - ID: $notificationId, Type: $type');
  }

  static Future<void> scheduleTicketNotifications(OwnedTicket ticket) async {
    final validDate = tz.TZDateTime.from(ticket.validDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    print('=== SIMPLE NOTIFICATION SCHEDULING ===');
    print('[NotificationService] Ticket ID: ${ticket.ownedTicketID}');
    print('[NotificationService] Valid date: ${ticket.validDate}');
    print('[NotificationService] Current time: ${DateTime.now()}');
    print('[NotificationService] Status: ${ticket.usageStatus}');

    // Skip if already used or expired
    if (ticket.usageStatus == 'Sudah Digunakan' ||
        ticket.usageStatus == 'Kadaluarsa') {
      print('[NotificationService] ❌ Skipping - ticket already used/expired');
      return;
    }

    // HANYA NOTIFIKASI HARI H JAM 8 PAGI
    final dayH = tz.TZDateTime(
      tz.local,
      validDate.year,
      validDate.month,
      validDate.day,
      8, // 8 AM
      0,
      0,
    );

    print('[NotificationService] Day-H notification time: $dayH');
    print('[NotificationService] Will schedule: ${dayH.isAfter(now)}');

    if (dayH.isAfter(now)) {
      // Simple notification ID
      final notificationId = ticket.ownedTicketID;
      final title = '🎫 Tiket Siap Digunakan!';
      final body =
          'Tiket ${ticket.ticket.temple?.title ?? 'Wisata'} aktif hari ini. Selamat berkunjung!';

      print('[NotificationService] 🚀 Scheduling Day-H notification...');

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        dayH,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ticket_dayh',
            'Tiket Hari H',
            channelDescription: 'Notifikasi tiket aktif hari ini',
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'dayh_${ticket.ownedTicketID}',
      );

      // Save to HIVE history
      try {
        final history = NotificationHistory(
          notificationId: notificationId,
          ticketId: ticket.ownedTicketID,
          title: title,
          body: body,
          type: 'Day-H',
          scheduledTime: dayH.toLocal(),
          sentTime: dayH.toLocal(),
          ticketTitle: ticket.ticket.description ?? '',
          templeTitle: ticket.ticket.temple?.title ?? '',
        );
        await NotificationHistoryService.saveNotification(history);
        print(
            '[NotificationService] ✅ Day-H notification scheduled and saved to HIVE');
      } catch (e) {
        print('[NotificationService] ❌ Error saving to HIVE: $e');
      }
    } else {
      print('[NotificationService] ❌ Day-H time has passed');
    }

    print('=== END SIMPLE NOTIFICATION ===');
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancelTicketNotifications(int ticketId) async {
    await _notifications.cancel(ticketId * 3); // H-1 notification
    await _notifications.cancel(ticketId * 3 + 1); // Day of notification
    await _notifications.cancel(ticketId * 3 + 2); // Expiry notification
  }

  // Helper method untuk testing notification immediately
  static Future<void> showTestNotification() async {
    await _notifications.show(
      999999,
      '🧪 Test Notification',
      'Ini adalah test notification untuk memastikan sistem berjalan dengan baik.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Channel untuk testing notifikasi',
          importance: Importance.high,
          priority: Priority.high,
          enableLights: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // Test scheduled notification (5 seconds from now)
  static Future<void> showTestScheduledNotification() async {
    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

    print(
        '[NotificationService] Scheduling test notification for: $scheduledTime');

    await _notifications.zonedSchedule(
      888888,
      '⏰ Test Scheduled Notification',
      'Ini adalah test scheduled notification yang dijadwalkan 5 detik dari sekarang.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_scheduled',
          'Test Scheduled Notifications',
          channelDescription: 'Channel untuk testing scheduled notifikasi',
          importance: Importance.high,
          priority: Priority.high,
          enableLights: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
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

  // Get scheduled notifications count for debugging
  static Future<int> getScheduledNotificationsCount() async {
    final pendingNotifications =
        await _notifications.pendingNotificationRequests();
    return pendingNotifications.length;
  }

  // Get scheduled notifications for debugging
  static Future<List<PendingNotificationRequest>>
      getScheduledNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Detailed debugging for all scheduled notifications
  static Future<String> getDetailedScheduledNotifications() async {
    final pendingNotifications =
        await _notifications.pendingNotificationRequests();
    final now = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);

    String debug = '=== DETAILED SCHEDULED NOTIFICATIONS ===\n';
    debug += 'Current time (system): $now\n';
    debug += 'Current time (TZ): $tzNow\n';
    debug += 'Timezone: ${tz.local}\n';
    debug += 'Timezone offset: ${tzNow.timeZoneOffset}\n';

    // Check permissions
    bool notificationsEnabled = await _areNotificationsEnabled();
    var notificationStatus = await Permission.notification.status;
    var alarmStatus = await Permission.scheduleExactAlarm.status;

    debug += 'Notifications enabled: $notificationsEnabled\n';
    debug += 'Notification permission: $notificationStatus\n';
    debug += 'Exact alarm permission: $alarmStatus\n';
    debug += 'Total pending: ${pendingNotifications.length}\n\n';

    if (pendingNotifications.isEmpty) {
      debug += 'No scheduled notifications found.\n';
      debug += 'This could mean:\n';
      debug += '- Notifications were not scheduled\n';
      debug += '- Permissions are denied\n';
      debug += '- System cleared them\n';
    } else {
      for (var notification in pendingNotifications) {
        debug += 'ID: ${notification.id}\n';
        debug += 'Title: ${notification.title}\n';
        debug += 'Body: ${notification.body}\n';
        debug += 'Payload: ${notification.payload}\n';
        debug += '---\n';
      }
    }

    debug += '=== END DETAILED NOTIFICATIONS ===';
    return debug;
  }

  // Simple test notification
  static Future<void> showTestTicketNotification(OwnedTicket ticket) async {
    final notificationId = 99999; // Simple ID for test

    await _notifications.show(
      notificationId,
      '🧪 Test Notification',
      'Test untuk tiket ${ticket.ticket.temple?.title ?? 'Wisata'}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_simple',
          'Test Notifications',
          channelDescription: 'Simple test notifications',
          importance: Importance.high,
          priority: Priority.high,
          enableLights: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    // Save to HIVE history
    try {
      final history = NotificationHistory(
        notificationId: notificationId,
        ticketId: ticket.ownedTicketID,
        title: '🧪 Test Notification',
        body: 'Test untuk tiket ${ticket.ticket.temple?.title ?? 'Wisata'}',
        type: 'Test',
        scheduledTime: DateTime.now(),
        sentTime: DateTime.now(),
        ticketTitle: ticket.ticket.description ?? '',
        templeTitle: ticket.ticket.temple?.title ?? '',
      );
      await NotificationHistoryService.saveNotification(history);
      print('[NotificationService] ✅ Test notification sent and saved to HIVE');
    } catch (e) {
      print('[NotificationService] ❌ Error saving test notification: $e');
    }
  }

  // Check and show immediate notifications for tickets that should notify today
  static Future<void> checkAndShowTodayTicketNotifications() async {
    try {
      print(
          '[NotificationService] 🔍 Checking REAL user tickets for today notifications...');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      print('[NotificationService] Today date: $today');
      print('[NotificationService] Current time: $now');

      // Get user's actual tickets
      final tickets = await TicketService.getMyTickets();
      print('[NotificationService] Found ${tickets.length} tickets for user');

      if (tickets.isEmpty) {
        print(
            '[NotificationService] ❌ No tickets found for user - no notification needed');
        return;
      }

      // Check if any ticket is valid for today AND not used
      List<OwnedTicket> todayTickets = [];
      for (var ticket in tickets) {
        final ticketDate = DateTime(ticket.validDate.year,
            ticket.validDate.month, ticket.validDate.day);
        print(
            '[NotificationService] Checking ticket ${ticket.ownedTicketID}: valid date ${ticketDate} vs today ${today}, status: ${ticket.usageStatus}');

        if (ticketDate.isAtSameMomentAs(today)) {
          // ALSO CHECK IF NOT USED
          if (ticket.usageStatus != 'Sudah Digunakan' &&
              ticket.usageStatus != 'Kadaluarsa') {
            todayTickets.add(ticket);
            print(
                '[NotificationService] ✅ Found UNUSED ticket for today: ${ticket.ownedTicketID} - ${ticket.ticket.temple?.title}');
          } else {
            print(
                '[NotificationService] ❌ Ticket already used/expired: ${ticket.ownedTicketID} - ${ticket.usageStatus}');
          }
        }
      }

      if (todayTickets.isEmpty) {
        print(
            '[NotificationService] ❌ No tickets valid for today - no notification needed');
        return;
      }

      // Only show notification if it's past 8 AM and there are tickets for today
      if (now.hour >= 8) {
        print(
            '[NotificationService] ✅ Time is ${now.hour}:${now.minute} (>=8 AM) and found ${todayTickets.length} tickets for today');

        for (var ticket in todayTickets) {
          await showRealTicketNotification(ticket);

          // Save to history
          try {
            final history = NotificationHistory(
              notificationId: ticket.ownedTicketID + 10000, // Unique ID
              ticketId: ticket.ownedTicketID,
              title: '🎫 Tiket Siap Digunakan!',
              body:
                  'Tiket ${ticket.ticket.temple?.title ?? 'candi'} aktif hari ini. Selamat berkunjung!',
              type: 'Day-H-Auto',
              scheduledTime: DateTime(today.year, today.month, today.day, 8, 0),
              sentTime: now,
              ticketTitle: ticket.ticket.description ?? 'Tiket Wisata',
              templeTitle: ticket.ticket.temple?.title ?? 'Candi',
            );
            await NotificationHistoryService.saveNotification(history);
            print(
                '[NotificationService] ✅ Real ticket notification saved to history');
          } catch (e) {
            print('[NotificationService] ❌ Error saving to history: $e');
          }
        }
      } else {
        print(
            '[NotificationService] ⏰ It\'s not 8 AM yet (current: ${now.hour}:${now.minute}) - tickets found but too early');
      }
    } catch (e) {
      print('[NotificationService] ❌ Error checking today tickets: $e');
    }
  }

  // Show immediate notification for today's tickets
  static Future<void> showTodayTicketNotification() async {
    await _notifications.show(
      88888, // Simple ID
      '🎫 Tiket Siap Digunakan!',
      'Tiket anda aktif hari ini. Selamat berkunjung!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ticket_today',
          'Tiket Hari Ini',
          channelDescription: 'Notifikasi tiket yang aktif hari ini',
          importance: Importance.high,
          priority: Priority.high,
          enableLights: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    print(
        '[NotificationService] ✅ Today ticket notification shown immediately');
  }

  // Show real ticket notification for specific ticket
  static Future<void> showRealTicketNotification(OwnedTicket ticket) async {
    final notificationId = ticket.ownedTicketID + 10000; // Unique ID
    await _notifications.show(
      notificationId,
      '🎫 Tiket Siap Digunakan!',
      'Tiket ${ticket.ticket.temple?.title ?? 'candi'} aktif hari ini. Selamat berkunjung!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ticket_real',
          'Tiket Real',
          channelDescription: 'Notifikasi tiket yang benar-benar aktif',
          importance: Importance.high,
          priority: Priority.high,
          enableLights: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    print(
        '[NotificationService] ✅ Real ticket notification shown for ${ticket.ticket.temple?.title}');
  }

  // AUTO SCHEDULE NOTIFICATION WHEN TICKET IS PURCHASED
  static Future<void> autoScheduleWhenTicketPurchased() async {
    try {
      print(
          '[NotificationService] 🎫 Auto-scheduling notifications for newly purchased tickets...');

      // Get all user tickets
      final tickets = await TicketService.getMyTickets();
      print(
          '[NotificationService] Found ${tickets.length} tickets to check for scheduling');

      final now = tz.TZDateTime.now(tz.local);

      for (var ticket in tickets) {
        // Skip if already used/expired
        if (ticket.usageStatus == 'Sudah Digunakan' ||
            ticket.usageStatus == 'Kadaluarsa') {
          print(
              '[NotificationService] ❌ Skipping ticket ${ticket.ownedTicketID} - already ${ticket.usageStatus}');
          continue;
        }

        // Schedule for Day-H at 8 AM
        final dayH = tz.TZDateTime(
          tz.local,
          ticket.validDate.year,
          ticket.validDate.month,
          ticket.validDate.day,
          8, // 8 AM
          0,
          0,
        );

        // Only schedule if the time hasn't passed yet
        if (dayH.isAfter(now)) {
          final notificationId = ticket.ownedTicketID;
          final title = '🎫 Tiket Siap Digunakan!';
          final body =
              'Tiket ${ticket.ticket.temple?.title ?? 'Wisata'} aktif hari ini. Selamat berkunjung!';

          print(
              '[NotificationService] 🚀 Scheduling notification for ticket ${ticket.ownedTicketID} at $dayH');

          // Schedule the notification
          await _notifications.zonedSchedule(
            notificationId,
            title,
            body,
            dayH,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'ticket_auto',
                'Tiket Otomatis',
                channelDescription:
                    'Notifikasi tiket yang dijadwalkan otomatis',
                importance: Importance.high,
                priority: Priority.high,
                enableLights: true,
                enableVibration: true,
                playSound: true,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );

          print(
              '[NotificationService] ✅ Successfully scheduled notification for ticket ${ticket.ownedTicketID}');
        } else {
          print(
              '[NotificationService] ⏰ Not scheduling ticket ${ticket.ownedTicketID} - time has passed ($dayH)');
        }
      }
    } catch (e) {
      print('[NotificationService] ❌ Error auto-scheduling notifications: $e');
    }
  }

  // FOR TESTING ONLY - Manual trigger today's ticket notifications
  static Future<void> debugManualTriggerTodayNotifications() async {
    try {
      print(
          '[NotificationService] 🧪 DEBUG: Manually triggering today\'s notifications...');

      // Get user's actual tickets
      final tickets = await TicketService.getMyTickets();
      print(
          '[NotificationService] Found ${tickets.length} tickets for debugging');

      if (tickets.isEmpty) {
        print('[NotificationService] ❌ No tickets found for debugging');
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // For each ticket, if it's for today, show notification regardless of time
      for (var ticket in tickets) {
        final ticketDate = DateTime(ticket.validDate.year,
            ticket.validDate.month, ticket.validDate.day);

        if (ticketDate.isAtSameMomentAs(today) &&
            ticket.usageStatus != 'Sudah Digunakan' &&
            ticket.usageStatus != 'Kadaluarsa') {
          print(
              '[NotificationService] 🧪 DEBUG: Showing notification for ticket ${ticket.ownedTicketID}');

          // Show notification immediately
          await showRealTicketNotification(ticket);

          // Save to history
          final history = NotificationHistory(
            notificationId: ticket.ownedTicketID + 20000, // Debug ID
            ticketId: ticket.ownedTicketID,
            title: '🧪 DEBUG: Tiket Siap Digunakan!',
            body:
                'DEBUG MODE: Tiket ${ticket.ticket.temple?.title ?? 'candi'} aktif hari ini.',
            type: 'Debug-Manual',
            scheduledTime: DateTime(today.year, today.month, today.day, 8, 0),
            sentTime: now,
            ticketTitle: ticket.ticket.description ?? 'Tiket Wisata',
            templeTitle: ticket.ticket.temple?.title ?? 'Candi',
          );
          await NotificationHistoryService.saveNotification(history);
        } else {
          print(
              '[NotificationService] ❌ DEBUG: Skipping ticket ${ticket.ownedTicketID} - not for today or already used');
        }
      }
    } catch (e) {
      print('[NotificationService] ❌ DEBUG ERROR: $e');
    }
  }
}
