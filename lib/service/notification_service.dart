import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../model/owned_ticket_model.dart';
import '../model/notification_history.dart';
import 'notification_history_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tiket_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

      // Set to Jakarta timezone (UTC+7) instead of local/UTC
      final jakarta = tz.getLocation('Asia/Jakarta');
      tz.setLocalLocation(jakarta);

      print('[NotificationService] Timezone set to: ${tz.local}');
      print(
          '[NotificationService] Current time (Jakarta): ${tz.TZDateTime.now(tz.local)}');

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

  // Log when notification is actually received/tapped

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
        print('[NotificationService] 🔍 History object created, saving...');

        // TEST: Check if NotificationHistoryService is working
        print('[NotificationService] 🔍 Testing NotificationHistoryService...');
        final testHistory = NotificationHistory(
          notificationId: 99999,
          ticketId: 0,
          title: 'Test',
          body: 'Test notification history save',
          type: 'Test',
          scheduledTime: DateTime.now(),
          sentTime: DateTime.now(),
          ticketTitle: 'Test',
          templeTitle: 'Test',
        );
        await NotificationHistoryService.saveNotification(testHistory);
        print(
            '[NotificationService] ✅ Test save successful, proceeding with real save...');

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

  // SIMPLER Test scheduled notification using system time
  static Future<void> showSimpleTestScheduledNotification() async {
    try {
      // Cancel any existing test notifications
      await _notifications.cancel(777777);

      // Use Jakarta timezone consistently
      final jakarta = tz.getLocation('Asia/Jakarta');
      final now = tz.TZDateTime.now(jakarta);

      // ADD BUFFER TIME: 10 seconds instead of 5 to avoid race condition
      final scheduledTime = now.add(const Duration(seconds: 10));

      print('[NotificationService] 🚀 SIMPLE TEST (Fixed TZ + Buffer):');
      print('[NotificationService] 🚀 Jakarta timezone: ${jakarta.name}');
      print('[NotificationService] 🚀 Current time (Jakarta): $now');
      print('[NotificationService] 🚀 Scheduled for (Jakarta): $scheduledTime');
      print(
          '[NotificationService] 🚀 Time difference: ${scheduledTime.difference(now).inSeconds} seconds');
      print('[NotificationService] 🚀 Buffer added to prevent race condition');

      await _notifications.zonedSchedule(
        777777, // Different ID for simple test
        '🚀 SIMPLE Test (10s Buffer)',
        'Fixed timing! Will appear at ${scheduledTime.toString().substring(11, 19)} (in 10 seconds from ${now.toString().substring(11, 19)})',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'simple_test_fixed',
            'Simple Test Fixed TZ',
            channelDescription:
                'Fixed timezone test for scheduled notifications',
            importance: Importance.max,
            priority: Priority.max,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            ledOnMs: 1000,
            ledOffMs: 500,
            showWhen: true,
            when: null,
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
          '[NotificationService] ✅ SIMPLE TEST (Fixed TZ + Buffer): Scheduled successfully!');

      // IMMEDIATELY VERIFY the notification was actually scheduled
      final pendingNotifications =
          await _notifications.pendingNotificationRequests();
      final ourNotification =
          pendingNotifications.where((n) => n.id == 777777).toList();

      print('[NotificationService] 🔍 VERIFICATION AFTER SCHEDULING:');
      print(
          '[NotificationService] 🔍 Total pending notifications: ${pendingNotifications.length}');
      print(
          '[NotificationService] 🔍 Our notification (777777) found: ${ourNotification.isNotEmpty}');

      if (ourNotification.isNotEmpty) {
        print(
            '[NotificationService] ✅ Notification successfully registered in system');
        print('[NotificationService] ✅ Title: ${ourNotification.first.title}');
        print('[NotificationService] ✅ Body: ${ourNotification.first.body}');
      } else {
        print(
            '[NotificationService] ❌ CRITICAL: Notification NOT found in pending list!');
        print(
            '[NotificationService] ❌ This means the system rejected the scheduling');

        // Check permissions again
        bool notificationsEnabled = await _areNotificationsEnabled();
        var notificationStatus = await Permission.notification.status;
        var alarmStatus = await Permission.scheduleExactAlarm.status;

        print(
            '[NotificationService] 🔍 Notifications enabled: $notificationsEnabled');
        print(
            '[NotificationService] 🔍 Notification permission: $notificationStatus');
        print('[NotificationService] 🔍 Exact alarm permission: $alarmStatus');
      }

      // Save to history for tracking
      final history = NotificationHistory(
        notificationId: 777777,
        ticketId: 0,
        title: '🚀 SIMPLE Test (10s Buffer) - ATTEMPT',
        body:
            'Fixed timing! Scheduled for ${scheduledTime.toString().substring(11, 19)} from ${now.toString().substring(11, 19)}',
        type: 'Simple-Test-Buffer',
        scheduledTime: scheduledTime.toLocal(),
        sentTime: now.toLocal(),
        ticketTitle: 'Test Ticket',
        templeTitle: 'Test Temple',
      );
      await NotificationHistoryService.saveNotification(history);
    } catch (e) {
      print(
          '[NotificationService] ❌ SIMPLE TEST (Fixed TZ + Buffer) ERROR: $e');

      // Save error to history
      final history = NotificationHistory(
        notificationId: 777777,
        ticketId: 0,
        title: '❌ SIMPLE Test (10s Buffer) - ERROR',
        body: 'Error with timing fix: $e',
        type: 'Simple-Test-Buffer-Error',
        scheduledTime: DateTime.now(),
        sentTime: DateTime.now(),
        ticketTitle: 'Test Ticket',
        templeTitle: 'Test Temple',
      );
      await NotificationHistoryService.saveNotification(history);
    }
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

      // Show notification immediately if there are unused tickets for today (remove 8 AM restriction)
      if (todayTickets.isNotEmpty) {
        print(
            '[NotificationService] ✅ Found ${todayTickets.length} unused tickets for today - showing notifications immediately');

        for (var ticket in todayTickets) {
          await showRealTicketNotification(ticket);

          // Save to history
          try {
            print(
                '[NotificationService] 🔍 Preparing to save notification history...');
            print(
                '[NotificationService] 🔍 Ticket ID: ${ticket.ownedTicketID}');
            print(
                '[NotificationService] 🔍 Temple: ${ticket.ticket.temple?.title}');
            print(
                '[NotificationService] 🔍 Description: ${ticket.ticket.description}');

            // Get current user ID for proper filtering
            final prefs = await SharedPreferences.getInstance();
            final currentUserId = prefs.getInt('userId') ?? 0;
            print('[NotificationService] 🔍 Current User ID: $currentUserId');

            final history = NotificationHistory(
              notificationId: ticket.ownedTicketID + 10000, // Unique ID
              ticketId: ticket.ownedTicketID,
              title: '🎫 Tiket Siap Digunakan!',
              body:
                  'Tiket ${ticket.ticket.temple?.title ?? 'candi'} aktif hari ini. Selamat berkunjung!',
              type: 'Day-H-Immediate',
              scheduledTime: DateTime(today.year, today.month, today.day, 8, 0),
              sentTime: now,
              ticketTitle: ticket.ticket.description ?? 'Tiket Wisata',
              templeTitle: ticket.ticket.temple?.title ?? 'Candi',
              userId: currentUserId, // Include current user ID
            );

            print('[NotificationService] 🔍 History object created, saving...');

            // TEST: Check if NotificationHistoryService is working
            print(
                '[NotificationService] 🔍 Testing NotificationHistoryService...');
            final testHistory = NotificationHistory(
              notificationId: 99999,
              ticketId: 0,
              title: 'Test',
              body: 'Test notification history save',
              type: 'Test',
              scheduledTime: DateTime.now(),
              sentTime: DateTime.now(),
              ticketTitle: 'Test',
              templeTitle: 'Test',
              userId: currentUserId, // Include user ID in test too
            );
            await NotificationHistoryService.saveNotification(testHistory);
            print(
                '[NotificationService] ✅ Test save successful, proceeding with real save...');

            await NotificationHistoryService.saveNotification(history);
            print(
                '[NotificationService] ✅ Real ticket notification saved to history successfully!');
          } catch (e) {
            print('[NotificationService] ❌ Error saving to history: $e');
            print('[NotificationService] ❌ Error type: ${e.runtimeType}');
            print('[NotificationService] ❌ Stack trace: ${StackTrace.current}');
          }
        }
      } else {
        print('[NotificationService] ❌ No unused tickets for today found');
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

  static Future<void> scheduleNotificationForTicket(
      OwnedTicket ownedTicket) async {
    try {
      // Use Asia/Jakarta timezone consistently
      final jakarta = tz.getLocation('Asia/Jakarta');

      // Parse the visit date and set time to 8 AM Jakarta time
      final visitDate = ownedTicket.validDate;
      final notificationTime = tz.TZDateTime(
        jakarta,
        visitDate.year,
        visitDate.month,
        visitDate.day,
        8, // 8 AM
        0, // 0 minutes
        0, // 0 seconds
      );

      final now = tz.TZDateTime.now(jakarta);

      // Add timing buffer for immediate test notifications (if within next hour)
      tz.TZDateTime actualNotificationTime = notificationTime;
      if (notificationTime.isBefore(now.add(const Duration(hours: 1)))) {
        // For near-future notifications, add 15 second buffer
        actualNotificationTime = now.add(const Duration(seconds: 15));
        print(
            '[NotificationService] ⚠️ Near-future notification: Added 15s buffer');
        print('[NotificationService] ⚠️ Original time: $notificationTime');
        print(
            '[NotificationService] ⚠️ Buffered time: $actualNotificationTime');
      }

      // Check if the notification time has already passed
      if (actualNotificationTime.isBefore(now)) {
        print(
            '[NotificationService] ⏰ Not scheduling ticket ${ownedTicket.ownedTicketID} - time has passed ($actualNotificationTime)');
        return;
      }

      // Check if ticket is already used
      if (ownedTicket.usageStatus == 'Sudah Digunakan') {
        print(
            '[NotificationService] ❌ Skipping ticket ${ownedTicket.ownedTicketID} - already ${ownedTicket.usageStatus}');
        return;
      }

      print(
          '[NotificationService] 🚀 Scheduling notification for ticket ${ownedTicket.ownedTicketID} at $actualNotificationTime');
      print('[NotificationService] 🚀 Current time: $now');
      print(
          '[NotificationService] 🚀 Time until notification: ${actualNotificationTime.difference(now).inMinutes} minutes');

      await _notifications.zonedSchedule(
        ownedTicket.ownedTicketID,
        '🎫 Reminder Kunjungan Pura',
        'Jangan lupa kunjungan Anda hari ini ke ${ownedTicket.ticket.temple?.title ?? 'Temple'} - ${ownedTicket.ticket.description ?? 'Ticket'}!',
        actualNotificationTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ticket_reminders',
            'Ticket Reminders',
            channelDescription:
                'Notifications to remind users about their temple visits',
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            ledOnMs: 1000,
            ledOffMs: 500,
            showWhen: true,
            when: null,
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
        payload: jsonEncode({
          'ownedTicketID': ownedTicket.ownedTicketID,
          'ticketID': ownedTicket.ticketID,
          'templeID': ownedTicket.ticket.templeID,
          'templeName': ownedTicket.ticket.temple?.title,
          'ticketDescription': ownedTicket.ticket.description,
          'validDate': ownedTicket.validDate.toIso8601String(),
        }),
      );

      print(
          '[NotificationService] ✅ Successfully scheduled notification for ticket ${ownedTicket.ownedTicketID}');

      // Save to notification history for tracking
      final history = NotificationHistory(
        notificationId: ownedTicket.ownedTicketID,
        ticketId: ownedTicket.ticketID,
        title: '🎫 Reminder Kunjungan Pura - ATTEMPT',
        body:
            'Scheduled for ${ownedTicket.ticket.temple?.title ?? 'Temple'} - ${ownedTicket.ticket.description ?? 'Ticket'}',
        type: 'Ticket-Reminder',
        scheduledTime: actualNotificationTime.toLocal(),
        sentTime: now.toLocal(),
        ticketTitle: ownedTicket.ticket.description ?? 'Ticket',
        templeTitle: ownedTicket.ticket.temple?.title ?? 'Temple',
      );
      await NotificationHistoryService.saveNotification(history);
    } catch (e) {
      print(
          '[NotificationService] ❌ Error scheduling notification for ticket ${ownedTicket.ownedTicketID}: $e');

      // Save error to history
      final history = NotificationHistory(
        notificationId: ownedTicket.ownedTicketID,
        ticketId: ownedTicket.ticketID,
        title: '❌ Reminder Kunjungan Pura - ERROR',
        body: 'Failed to schedule: $e',
        type: 'Ticket-Reminder-Error',
        scheduledTime: DateTime.now(),
        sentTime: DateTime.now(),
        ticketTitle: ownedTicket.ticket.description ?? 'Ticket',
        templeTitle: ownedTicket.ticket.temple?.title ?? 'Temple',
      );
      await NotificationHistoryService.saveNotification(history);
    }
  }
}
