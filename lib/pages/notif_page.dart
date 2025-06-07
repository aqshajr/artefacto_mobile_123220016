import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // untuk format tanggal

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool hasTicketToday = false;
  String ticketInfo = '';

  @override
  void initState() {
    super.initState();

    // Contoh data tiket yang dimiliki user (bisa diganti dengan data asli)
    List<DateTime> userTicketsDates = [
      DateTime.now().subtract(const Duration(days: 1)),
      DateTime.now(), // ada tiket untuk hari ini
      DateTime.now().add(const Duration(days: 2)),
    ];

    // Cek apakah ada tiket untuk hari ini
    DateTime today = DateTime.now();
    hasTicketToday = userTicketsDates.any((date) =>
    date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);

    if (hasTicketToday) {
      ticketInfo = "Kamu punya tiket untuk hari ini!";
    }
  }

  void showTicketPurchasedNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tiket berhasil dibeli!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi Tiket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Tampilkan notifikasi tiket hari ini jika ada
            if (hasTicketToday)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticketInfo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Tombol simulasi beli tiket
            ElevatedButton(
              onPressed: () {
                // Panggil fungsi notifikasi pembelian tiket
                showTicketPurchasedNotification();
              },
              child: const Text('Beli Tiket'),
            ),
          ],
        ),
      ),
    );
  }
}
