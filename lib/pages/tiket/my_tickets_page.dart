import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../model/owned_ticket_model.dart';
import '../../service/tiket_service.dart';
import '../../service/notification_service.dart';

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  List<OwnedTicket> _tickets = [];
  bool _isLoading = true;
  String _message = '';
  String _selectedFilter = 'Belum Digunakan';
  List<OwnedTicket> _filteredTickets = [];

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'Belum Digunakan';
    _initializeNotifications();
    _fetchMyTickets();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.initialize();
  }

  Future<void> _fetchMyTickets() async {
    try {
      final response = await TicketService.getMyTickets();
      if (mounted) {
        setState(() {
          _tickets = _processTicketExpiration(response);
          _filterTickets(_selectedFilter);

          // Schedule notifications for all tickets
          for (var ticket in _tickets) {
            NotificationService.scheduleTicketNotifications(ticket);
          }

          _isLoading = false;
          if (_tickets.isEmpty) {
            _message = 'Anda belum memiliki tiket';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = 'Gagal memuat tiket: ${e.toString()}';
        });
      }
    }
  }

  List<OwnedTicket> _processTicketExpiration(List<OwnedTicket> tickets) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Sort tickets by status
    final activeTickets = tickets.where((ticket) {
      final ticketDate = DateTime(
        ticket.validDate.year,
        ticket.validDate.month,
        ticket.validDate.day,
      );
      return ticket.usageStatus == 'Belum Digunakan' &&
          ticketDate.isAtSameMomentAs(today);
    }).toList();

    final futureTickets = tickets.where((ticket) {
      final ticketDate = DateTime(
        ticket.validDate.year,
        ticket.validDate.month,
        ticket.validDate.day,
      );
      return ticket.usageStatus == 'Belum Digunakan' &&
          ticketDate.isAfter(today);
    }).toList();

    final expiredAndUsedTickets = tickets.where((ticket) {
      final ticketDate = DateTime(
        ticket.validDate.year,
        ticket.validDate.month,
        ticket.validDate.day,
      );
      return ticket.usageStatus == 'Sudah Digunakan' ||
          (ticket.usageStatus == 'Belum Digunakan' &&
              ticketDate.isBefore(today));
    }).toList();

    // Update expired tickets status
    for (var ticket in expiredAndUsedTickets) {
      if (ticket.usageStatus != 'Sudah Digunakan') {
        ticket.usageStatus = 'Kadaluarsa';
      }
    }

    // Update future tickets status
    for (var ticket in futureTickets) {
      ticket.usageStatus = 'Belum Dapat Digunakan';
    }

    // Combine all tickets with proper order
    return [...activeTickets, ...futureTickets, ...expiredAndUsedTickets];
  }

  bool _isTicketValid(DateTime validDate) {
    final now = DateTime.now();
    return now.year == validDate.year &&
        now.month == validDate.month &&
        now.day == validDate.day;
  }

  String _formatPrice(double? price) {
    if (price == null) return 'Harga tidak tersedia';
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(price);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  String _getStatusText(OwnedTicket ticket) {
    if (ticket.usageStatus == 'Sudah Digunakan') {
      return 'Sudah Digunakan';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final ticketDate = DateTime(
      ticket.validDate.year,
      ticket.validDate.month,
      ticket.validDate.day,
    );

    if (ticketDate.isBefore(today)) {
      return 'Kadaluarsa';
    } else if (ticketDate.isAfter(today)) {
      return 'Belum Dapat Digunakan';
    } else {
      return 'Dapat Digunakan';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Dapat Digunakan':
        return Colors.green;
      case 'Belum Dapat Digunakan':
        return Colors.orange;
      case 'Sudah Digunakan':
      case 'Kadaluarsa':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleUseTicket(OwnedTicket ticket) async {
    if (!_isTicketValid(ticket.validDate) ||
        ticket.usageStatus != 'Belum Digunakan') {
      return;
    }

    try {
      await TicketService.useTicket(ticket.ownedTicketID);

      // Cancel notifications for used ticket
      await NotificationService.cancelTicketNotifications(ticket.ownedTicketID);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tiket berhasil digunakan!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh tickets
      _fetchMyTickets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menggunakan tiket: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterTickets(String filter) {
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case 'Sudah Digunakan':
          _filteredTickets = _tickets.where((ticket) {
            return ticket.usageStatus == 'Sudah Digunakan' ||
                ticket.usageStatus == 'Kadaluarsa';
          }).toList();
          break;
        case 'Belum Digunakan':
          _filteredTickets = _tickets.where((ticket) {
            final status = _getStatusText(ticket);
            return status == 'Dapat Digunakan' ||
                status == 'Belum Dapat Digunakan';
          }).toList();
          break;
        default:
          _filteredTickets = _tickets;
      }
    });
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: TextButton(
          onPressed: () => _filterTickets(label),
          style: TextButton.styleFrom(
            backgroundColor:
                isSelected ? const Color(0xff233743) : Colors.white,
            foregroundColor:
                isSelected ? Colors.white : const Color(0xff233743),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color:
                    isSelected ? const Color(0xff233743) : Colors.grey.shade300,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiket Saya',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: const Color(0xff233743),
              ),
            ),
            Text(
              'Kelola tiket wisata Anda',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        toolbarHeight: 80,
      ),
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
                        _message,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      child: Row(
                        children: [
                          _buildFilterChip('Belum Digunakan'),
                          _buildFilterChip('Sudah Digunakan'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredTickets.isEmpty
                          ? Center(
                              child: Text(
                                'Tidak ada tiket dengan status $_selectedFilter',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              itemCount: _filteredTickets.length,
                              itemBuilder: (context, index) {
                                final ticket = _filteredTickets[index];
                                final isUsable =
                                    _isTicketValid(ticket.validDate) &&
                                        ticket.usageStatus == 'Belum Digunakan';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                spreadRadius: 1,
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .confirmation_number_outlined,
                                                                size: 18,
                                                                color: const Color(
                                                                        0xff233743)
                                                                    .withOpacity(
                                                                        0.7),
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                'E-TICKET',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: const Color(
                                                                          0xff233743)
                                                                      .withOpacity(
                                                                          0.6),
                                                                  letterSpacing:
                                                                      1,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Text(
                                                            ticket.uniqueCode,
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors
                                                                  .grey[600],
                                                              letterSpacing: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        ticket.ticket?.temple
                                                                ?.templeName ??
                                                            'Tiket Wisata',
                                                        style: GoogleFonts
                                                            .playfairDisplay(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: const Color(
                                                              0xff233743),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        ticket.ticket
                                                                ?.description ??
                                                            'Informasi detail tiket akan ditampilkan di halaman selanjutnya.',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(
                                                          height: 12),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                                  0xffB69574)
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          _formatPrice(ticket
                                                              .ticket?.price),
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: const Color(
                                                                0xffB69574),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 12),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .calendar_today_outlined,
                                                            size: 16,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                            'Berlaku pada: ${_formatDate(ticket.validDate)}',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 13,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                          height: 12),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: _getStatusColor(
                                                                  _getStatusText(
                                                                      ticket))
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(16),
                                                        ),
                                                        child: Text(
                                                          _getStatusText(
                                                              ticket),
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: _getStatusColor(
                                                                _getStatusText(
                                                                    ticket)),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              CustomPaint(
                                                painter: DashedLinePainter(
                                                  color: Colors.grey
                                                      .withOpacity(0.3),
                                                  dashHeight: 6,
                                                  dashSpace: 6,
                                                  strokeWidth: 1.5,
                                                ),
                                                child: SizedBox(
                                                  height: 200,
                                                  child: Container(
                                                    width: 1,
                                                    color: Colors.transparent,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 50,
                                                height: 200,
                                                decoration: BoxDecoration(
                                                  color: isUsable
                                                      ? const Color(0xffB69574)
                                                      : const Color(0xFFBDBDBD),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(12),
                                                    bottomRight:
                                                        Radius.circular(12),
                                                  ),
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: isUsable
                                                        ? () =>
                                                            _handleUseTicket(
                                                                ticket)
                                                        : null,
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      topRight:
                                                          Radius.circular(12),
                                                      bottomRight:
                                                          Radius.circular(12),
                                                    ),
                                                    child: RotatedBox(
                                                      quarterTurns: 1,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .check_circle_outline,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            'GUNAKAN',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.white,
                                                              letterSpacing: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          left: -8,
                                          top: 92,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 42,
                                          top: 92,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    NotificationService.cancelAllNotifications();
    super.dispose();
  }
}

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
