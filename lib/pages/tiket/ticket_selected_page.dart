import 'package:artefacto/model/temple_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:artefacto/model/tiket_model.dart';
import 'package:artefacto/service/tiket_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'buy_tiket.dart';

class TicketSelectionPage extends StatefulWidget {
  const TicketSelectionPage({super.key});

  @override
  State<TicketSelectionPage> createState() => _TicketSelectionPageState();
}

class _TicketSelectionPageState extends State<TicketSelectionPage> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String _message = '';
  String _selectedTimezone = 'Asia/Jakarta'; // Default ke WIB
  bool _isWithinServiceHours = true;

  // Daftar timezone yang sering digunakan
  final List<Map<String, String>> _timezones = [
    {'id': 'Asia/Jakarta', 'label': 'WIB'},
    {'id': 'Asia/Makassar', 'label': 'WITA'},
    {'id': 'Asia/Jayapura', 'label': 'WIT'},
    {'id': 'Asia/Singapore', 'label': 'Singapore'},
    {'id': 'Asia/Tokyo', 'label': 'Japan'},
    {'id': 'Australia/Sydney', 'label': 'Sydney'},
    {'id': 'Europe/London', 'label': 'London'},
    {'id': 'America/New_York', 'label': 'New York'},
  ];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _fetchTickets();
    _checkServiceHours();
  }

  void _checkServiceHours() {
    final jakartaTime = tz.TZDateTime.now(tz.getLocation('Asia/Jakarta'));
    final hour = jakartaTime.hour;
    setState(() {
      _isWithinServiceHours = hour >= 8 && hour < 17;
    });
  }

  String _convertServiceHours(String timezone) {
    final jakarta = tz.getLocation('Asia/Jakarta');
    final targetZone = tz.getLocation(timezone);

    // Konversi jam buka (08:00 WIB)
    final openTime = tz.TZDateTime(jakarta, DateTime.now().year,
        DateTime.now().month, DateTime.now().day, 8, 0);
    final openTimeConverted = tz.TZDateTime.from(openTime, targetZone);

    // Konversi jam tutup (17:00 WIB)
    final closeTime = tz.TZDateTime(jakarta, DateTime.now().year,
        DateTime.now().month, DateTime.now().day, 17, 0);
    final closeTimeConverted = tz.TZDateTime.from(closeTime, targetZone);

    return '${openTimeConverted.hour.toString().padLeft(2, '0')}:00 - '
        '${closeTimeConverted.hour.toString().padLeft(2, '0')}:00';
  }

  Widget _buildServiceHoursCard() {
    final selectedLabel =
        _timezones.firstWhere((tz) => tz['id'] == _selectedTimezone)['label'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xff233743),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Jam Layanan Tiket Online',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waktu Layanan: 08:00 - 17:00 WIB',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Di zonamu ($selectedLabel): ${_convertServiceHours(_selectedTimezone)}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: const Color(0xffB69574),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedTimezone,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    items: _timezones.map((tz) {
                      return DropdownMenuItem(
                        value: tz['id'],
                        child: Text(
                          '${tz['label']}',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTimezone = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pembelian tiket hanya dapat dilakukan pada jam layanan untuk memastikan tiket dapat digunakan pada tanggal yang dipilih.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchTickets() async {
    try {
      final response = await TicketService.getTickets();
      if (mounted) {
        if (response.status == 'sukses') {
          setState(() {
            _tickets = response.data?.tickets ?? [];
            if (_tickets.isEmpty) {
              _message = 'Tidak ada tiket tersedia saat ini.';
            }
          });
        } else {
          setState(() => _message = response.message ?? 'Gagal memuat tiket');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Terjadi kesalahan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTicketItem(Ticket ticket) {
    final priceFormatted =
        NumberFormat('#,##0', 'id_ID').format(ticket.price ?? 0);
    String description = ticket.description ??
        'Informasi detail tiket akan ditampilkan di halaman selanjutnya.';
    if (description.length > 75) {
      description = '${description.substring(0, 72)}...';
    }

    final bool isEnabled = _isWithinServiceHours;
    final Color cardColor = isEnabled ? Colors.white : Colors.grey[100]!;
    final Color textColor =
        isEnabled ? const Color(0xff233743) : Colors.grey[500]!;
    final Color priceColor =
        isEnabled ? const Color(0xffB69574) : Colors.grey[400]!;
    final Color stubColor =
        isEnabled ? const Color(0xffB69574) : Colors.grey[300]!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Main Ticket Container
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: isEnabled
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketPurchasePage(ticket: ticket),
                          ),
                        );
                      }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    // Ticket Content
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 18,
                                  color: textColor.withOpacity(0.7),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'E-TICKET',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textColor.withOpacity(0.6),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ticket.temple?.templeName ?? 'Tiket Wisata',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: textColor.withOpacity(0.8),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: priceColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Rp$priceFormatted',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: priceColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Perforation Line
                    CustomPaint(
                      painter: DashedLinePainter(
                        color: Colors.grey.withOpacity(0.3),
                        dashHeight: 6,
                        dashSpace: 6,
                        strokeWidth: 1.5,
                      ),
                      child: SizedBox(
                        height: 160,
                        child: Container(
                          width: 1,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    // Ticket Stub
                    Container(
                      width: 50,
                      height: 160,
                      decoration: BoxDecoration(
                        color: stubColor,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'BELI TIKET',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Circular notches for ticket effect
            Positioned(
              left: -8,
              top: 72,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 42,
              top: 72,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pilih Tiket',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xff233743),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFDFBF5),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xffB69574)))
          : _tickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.confirmation_number_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _message.isNotEmpty
                            ? _message
                            : 'Tidak ada tiket tersedia.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildServiceHoursCard(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _tickets.length,
                        itemBuilder: (_, i) => _buildTicketItem(_tickets[i]),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// Custom painter untuk garis putus-putus
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashSpace;
  final double strokeWidth;

  DashedLinePainter({
    required this.color,
    required this.dashHeight,
    required this.dashSpace,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) =>
      color != oldDelegate.color ||
      dashHeight != oldDelegate.dashHeight ||
      dashSpace != oldDelegate.dashSpace ||
      strokeWidth != oldDelegate.strokeWidth;
}
