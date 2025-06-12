import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// Simple debug info widget - just shows basic notification status
class DebugInfoWidget extends StatelessWidget {
  const DebugInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PendingNotificationRequest>>(
      future: FlutterLocalNotificationsPlugin().pendingNotificationRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final currentTime = DateTime.now();
        final jakartaTime =
            DateTime.now().toUtc().add(const Duration(hours: 7));
        final jakartaTz = tz.TZDateTime.now(tz.getLocation('Asia/Jakarta'));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("=== DETAILED SCHEDULED NOTIFICATIONS ===",
                style: TextStyle(
                    fontFamily: 'Courier', fontWeight: FontWeight.bold)),
            Text("=== TIMING DEBUG INFO ===",
                style: TextStyle(
                    fontFamily: 'Courier', fontWeight: FontWeight.bold)),
            Text("System time: $currentTime",
                style: TextStyle(fontFamily: 'Courier')),
            Text("Jakarta manual (+7): $jakartaTime",
                style: TextStyle(fontFamily: 'Courier')),
            Text("Jakarta TZ: $jakartaTz",
                style: TextStyle(fontFamily: 'Courier')),
            Text("TZ Location: ${tz.getLocation('Asia/Jakarta').name}",
                style: TextStyle(fontFamily: 'Courier')),
            Text("TZ Offset: ${jakartaTz.timeZoneOffset}",
                style: TextStyle(fontFamily: 'Courier')),
            Text(
                "Processing timestamp: ${DateTime.now().millisecondsSinceEpoch}",
                style: TextStyle(fontFamily: 'Courier')),
            const SizedBox(height: 10),
            Text("Total pending: ${snapshot.data!.length}",
                style: TextStyle(fontFamily: 'Courier')),
            Text("", style: TextStyle(fontFamily: 'Courier')),
            ...snapshot.data!.map((notification) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ID: ${notification.id}",
                      style: TextStyle(fontFamily: 'Courier')),
                  Text("Title: ${notification.title}",
                      style: TextStyle(fontFamily: 'Courier')),
                  Text("Body: ${notification.body}",
                      style: TextStyle(fontFamily: 'Courier')),
                  Text("Payload: ${notification.payload ?? 'null'}",
                      style: TextStyle(fontFamily: 'Courier')),
                  Text("---", style: TextStyle(fontFamily: 'Courier')),
                ],
              );
            }).toList(),
            Text("=== END DETAILED NOTIFICATIONS ===",
                style: TextStyle(
                    fontFamily: 'Courier', fontWeight: FontWeight.bold)),
          ],
        );
      },
    );
  }
}
