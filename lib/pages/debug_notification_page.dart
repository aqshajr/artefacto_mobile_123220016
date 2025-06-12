import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/notification_service.dart';
import '../service/notification_history_service.dart';
import '../service/tiket_service.dart';
import '../model/notification_history.dart';
import '../model/owned_ticket_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

class DebugNotificationPage extends StatefulWidget {
  const DebugNotificationPage({super.key});

  @override
  State<DebugNotificationPage> createState() => _DebugNotificationPageState();
}

class _DebugNotificationPageState extends State<DebugNotificationPage> {
  String _debugInfo = 'Loading...';
  List<OwnedTicket> _tickets = [];
  List<NotificationHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() => _isLoading = true);

    try {
      // Get detailed debug info
      final debugText =
          await NotificationService.getDetailedScheduledNotifications();
      final tickets = await TicketService.getMyTickets();
      final history = await NotificationHistoryService.getAllNotifications();

      setState(() {
        _debugInfo = debugText;
        _tickets = tickets;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error loading debug info: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showTestNotification() async {
    await NotificationService.showTestNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test notification sent!')),
    );
  }

  Future<void> _showTestScheduledNotification() async {
    await NotificationService.showTestScheduledNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Test scheduled notification set for 5 seconds!')),
    );

    // Refresh debug info after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      _loadDebugInfo();
    });
  }

  Future<void> _checkTodayTickets() async {
    await NotificationService.checkAndShowTodayTicketNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checked today tickets for notifications')),
    );
    _loadDebugInfo();
  }

  Future<void> _debugManualTrigger() async {
    await NotificationService.debugManualTriggerTodayNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug manual trigger executed')),
    );
    _loadDebugInfo();
  }

  Future<void> _autoScheduleAllTickets() async {
    await NotificationService.autoScheduleWhenTicketPurchased();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Auto-scheduled all tickets')),
    );
    _loadDebugInfo();
  }

  Future<void> _clearAllNotifications() async {
    await NotificationService.cancelAllNotifications();
    await NotificationHistoryService.clearAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cleared all notifications and history')),
    );
    _loadDebugInfo();
  }

  Future<void> _testCameraPermission() async {
    final status = await Permission.camera.request();
    String message = 'Camera permission: ${status.toString()}';

    if (status.isGranted) {
      message += ' ✅ Granted - Camera should work';
    } else if (status.isDenied) {
      message += ' ❌ Denied - Please allow camera access';
    } else if (status.isPermanentlyDenied) {
      message += ' ⚠️ Permanently denied - Check app settings';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _testGalleryPermission() async {
    var status = await Permission.photos.request();
    if (status.isDenied) {
      status = await Permission.storage.request();
    }

    String message = 'Gallery permission: ${status.toString()}';

    if (status.isGranted) {
      message += ' ✅ Granted - Gallery should work';
    } else if (status.isDenied) {
      message += ' ❌ Denied - Please allow gallery access';
    } else if (status.isPermanentlyDenied) {
      message += ' ⚠️ Permanently denied - Check app settings';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _testCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Camera works! Image captured successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Camera cancelled or failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Camera error: $e')),
      );
    }
  }

  Future<void> _showHiveHistory() async {
    try {
      // Use new debug method to get all notifications without user filtering
      final allHistory =
          await NotificationHistoryService.getAllNotificationsDebug();

      if (!mounted) return;

      String historyText = '=== HIVE NOTIFICATION HISTORY (DEBUG) ===\n';
      historyText += 'Total notifications found: ${allHistory.length}\n\n';

      if (allHistory.isEmpty) {
        // Let's check the raw Hive box
        try {
          final box =
              await Hive.openBox<NotificationHistory>('notification_history');
          final rawValues = box.values.toList();
          historyText += 'Raw Hive box count: ${rawValues.length}\n';

          if (rawValues.isNotEmpty) {
            historyText += '\n🔍 RAW HIVE DATA:\n';
            for (int i = 0; i < rawValues.length && i < 5; i++) {
              final notif = rawValues[i];
              historyText += '${i + 1}. ${notif.title}\n';
              historyText += '   UserID: ${notif.userId}\n';
              historyText += '   Type: ${notif.type}\n';
              historyText += '   Sent: ${notif.sentTime}\n';
              historyText += '---\n';
            }
          }
        } catch (e) {
          historyText += 'Error accessing raw Hive: $e\n';
        }

        historyText += '\n❌ ISSUE: getAllNotificationsDebug() returned empty\n';
        historyText += 'Possible causes:\n';
        historyText += '- Hive box not initialized\n';
        historyText += '- Data corruption\n';
        historyText += '- Adapter registration problem\n';
      } else {
        historyText += '✅ FOUND NOTIFICATIONS:\n\n';
        for (int i = 0; i < allHistory.length; i++) {
          final notif = allHistory[i];
          historyText += '${i + 1}. ${notif.title}\n';
          historyText += '   Type: ${notif.type}\n';
          historyText += '   UserID: ${notif.userId}\n';
          historyText += '   Sent: ${notif.sentTime}\n';
          historyText += '   Ticket ID: ${notif.ticketId}\n';
          historyText += '   Read: ${notif.isRead ? "Yes" : "No"}\n';
          historyText += '   Body: ${notif.body}\n';
          historyText += '---\n';
        }
      }

      historyText += '\n=== END HIVE HISTORY DEBUG ===';

      // Show in dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Hive History (Debug Mode)',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Text(
                historyText,
                style: GoogleFonts.robotoMono(fontSize: 11),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error loading Hive history: $e')),
      );
    }
  }

  Future<void> _testScheduledWithBetterFeedback() async {
    // Save "attempt" record FIRST (even if scheduling fails)
    try {
      final attemptHistory = NotificationHistory(
        notificationId: 888888,
        ticketId: 0,
        title: '🕒 Test Scheduled - ATTEMPT',
        body: 'Attempting to schedule notification for 5 seconds...',
        type: 'Test-Attempt',
        scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
        sentTime: DateTime.now(),
        ticketTitle: 'Test Ticket',
        templeTitle: 'Test Temple',
      );
      await NotificationHistoryService.saveNotification(attemptHistory);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '📝 Saved ATTEMPT record to Hive. Now trying to schedule...'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error saving attempt record: $e');
    }

    // Now try to schedule
    try {
      await NotificationService.showTestScheduledNotification();

      // Save success record
      final successHistory = NotificationHistory(
        notificationId: 999999,
        ticketId: 0,
        title: '✅ Test Scheduled - SUCCESS',
        body: 'Successfully scheduled! Should appear in 5 seconds.',
        type: 'Test-Success',
        scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
        sentTime: DateTime.now(),
        ticketTitle: 'Test Ticket',
        templeTitle: 'Test Temple',
      );
      await NotificationHistoryService.saveNotification(successHistory);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '✅ Scheduling SUCCESS! Check Hive History and wait 5 seconds.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Save failure record
      try {
        final failHistory = NotificationHistory(
          notificationId: 111111,
          ticketId: 0,
          title: '❌ Test Scheduled - FAILED',
          body: 'Scheduling failed: $e',
          type: 'Test-Failed',
          scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
          sentTime: DateTime.now(),
          ticketTitle: 'Test Ticket',
          templeTitle: 'Test Temple',
        );
        await NotificationHistoryService.saveNotification(failHistory);
      } catch (saveError) {
        print('Error saving failure record: $saveError');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('❌ Scheduling FAILED: $e. Check Hive History for details.'),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    // Refresh debug info after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _loadDebugInfo();
      }
    });
  }

  Future<void> _testSimpleScheduled() async {
    await NotificationService.showTestScheduledNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Test scheduled notification set for 5 seconds!')),
    );

    // Refresh debug info after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      _loadDebugInfo();
    });
  }

  Future<void> _testSimpleScheduledNew() async {
    await NotificationService.showSimpleTestScheduledNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            '🚀 SIMPLE test scheduled! Check console and wait 10 seconds...'),
        duration: Duration(seconds: 3),
      ),
    );

    // Refresh debug info after 11 seconds to see if it worked
    Future.delayed(const Duration(seconds: 11), () {
      if (mounted) {
        _loadDebugInfo();
      }
    });
  }

  Future<void> _checkNotificationPermissions() async {
    String message = '=== NOTIFICATION PERMISSIONS ===\n';

    try {
      // Check notification permission
      final notifStatus = await Permission.notification.status;
      message += 'Notification: ${notifStatus.toString()}\n';

      // Check exact alarm permission (Android 12+)
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      message += 'Exact Alarm: ${alarmStatus.toString()}\n';

      // Check if notifications are enabled at system level
      final pendingNotifications =
          await NotificationService.getScheduledNotifications();
      message += 'Pending scheduled: ${pendingNotifications.length}\n';

      message += '\n=== RECOMMENDATIONS ===\n';

      if (notifStatus != PermissionStatus.granted) {
        message += '❌ Grant notification permission\n';
      } else {
        message += '✅ Notification permission OK\n';
      }

      if (alarmStatus != PermissionStatus.granted) {
        message +=
            '❌ Grant exact alarm permission for scheduled notifications\n';
        message += '⚠️ THIS IS WHY 5s test failed!\n';
      } else {
        message += '✅ Exact alarm permission OK\n';
      }

      if (pendingNotifications.isEmpty) {
        message += '⚠️ No scheduled notifications found\n';
        message += 'This is normal in debug mode\n';
      } else {
        message += '✅ ${pendingNotifications.length} notifications scheduled\n';
      }

      message += '\n💡 TIP: Scheduled notifications work best in release APK!';
    } catch (e) {
      message += 'Error checking permissions: $e';
    }

    // Show in dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Notification Permissions',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              message,
              style: GoogleFonts.robotoMono(fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestExactAlarmPermission() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔐 Checking Exact Alarm permission...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Use native method to check exact alarm permission
      const platform = MethodChannel('android_settings');

      try {
        final bool canSchedule =
            await platform.invokeMethod('canScheduleExactAlarms');

        if (canSchedule) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Exact Alarm permission already granted!'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // Open exact alarm settings
          final bool opened =
              await platform.invokeMethod('openExactAlarmSettings');

          if (opened) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '📱 Opening Exact Alarm Settings. Please enable the permission and return to the app.'),
                duration: Duration(seconds: 5),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '⚠️ Could not open settings. Please manually enable exact alarm permission.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error checking permission: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _checkBatteryOptimization() async {
    try {
      const platform = MethodChannel('android_settings');

      final bool isIgnoring =
          await platform.invokeMethod('isIgnoringBatteryOptimizations');

      if (isIgnoring) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('✅ Battery optimization already disabled for this app!'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Show dialog asking to disable battery optimization
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('⚡ Battery Optimization'),
              content: const Text(
                  'To ensure scheduled notifications work properly, this app needs to be excluded from battery optimization.\n\n'
                  'This will allow notifications to appear even when the device is in sleep mode.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _requestBatteryOptimizationExemption();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error checking battery optimization: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      const platform = MethodChannel('android_settings');

      final bool opened =
          await platform.invokeMethod('requestIgnoreBatteryOptimizations');

      if (opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '📱 Opening Battery Optimization Settings. Please disable optimization for this app.'),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        // Fallback to general battery settings
        await platform.invokeMethod('openBatteryOptimizationSettings');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '📱 Opening Battery Settings. Find this app and disable optimization.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error opening battery settings: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Debug Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff233743),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Test Buttons
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Actions',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: _showTestNotification,
                                child: const Text('Test Instant'),
                              ),
                              ElevatedButton(
                                onPressed: _testScheduledWithBetterFeedback,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Test 5s Better'),
                              ),
                              ElevatedButton(
                                onPressed: _testSimpleScheduledNew,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('🚀 Simple 10s Test'),
                              ),
                              ElevatedButton(
                                onPressed: _checkTodayTickets,
                                child: const Text('Check Today'),
                              ),
                              ElevatedButton(
                                onPressed: _debugManualTrigger,
                                child: const Text('Manual Trigger'),
                              ),
                              ElevatedButton(
                                onPressed: _autoScheduleAllTickets,
                                child: const Text('Auto Schedule'),
                              ),
                              // Camera test buttons
                              ElevatedButton(
                                onPressed: _testCameraPermission,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Test Camera Permission'),
                              ),
                              ElevatedButton(
                                onPressed: _testGalleryPermission,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Test Gallery Permission'),
                              ),
                              ElevatedButton(
                                onPressed: _testCamera,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Test Camera'),
                              ),
                              ElevatedButton(
                                onPressed: _clearAllNotifications,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Clear All'),
                              ),
                              ElevatedButton(
                                onPressed: _showHiveHistory,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Show Hive History'),
                              ),
                              ElevatedButton(
                                onPressed: _checkNotificationPermissions,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text(
                                    'Check Notification Permissions'),
                              ),
                              ElevatedButton(
                                onPressed: _requestExactAlarmPermission,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Request Exact Alarm'),
                              ),
                              ElevatedButton(
                                onPressed: _checkBatteryOptimization,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Check Battery Optimization'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Tickets
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Tickets (${_tickets.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_tickets.isEmpty)
                            Text(
                              'No tickets found',
                              style:
                                  GoogleFonts.poppins(color: Colors.grey[600]),
                            )
                          else
                            ..._tickets
                                .map((ticket) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ID: ${ticket.ownedTicketID}',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                              'Temple: ${ticket.ticket.temple?.title ?? "Unknown"}'),
                                          Text(
                                              'Valid Date: ${ticket.validDate}'),
                                          Text('Status: ${ticket.usageStatus}'),
                                          Text(
                                              'Is Today: ${DateTime.now().day == ticket.validDate.day && DateTime.now().month == ticket.validDate.month && DateTime.now().year == ticket.validDate.year ? "YES" : "NO"}'),
                                        ],
                                      ),
                                    ))
                                .toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notification History
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification History (${_history.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_history.isEmpty)
                            Text(
                              'No notification history',
                              style:
                                  GoogleFonts.poppins(color: Colors.grey[600]),
                            )
                          else
                            ..._history
                                .take(5)
                                .map((notif) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notif.title,
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(notif.body),
                                          Text('Type: ${notif.type}'),
                                          Text('Sent: ${notif.sentTime}'),
                                        ],
                                      ),
                                    ))
                                .toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Debug Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Debug Information',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _debugInfo,
                              style: GoogleFonts.robotoMono(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
