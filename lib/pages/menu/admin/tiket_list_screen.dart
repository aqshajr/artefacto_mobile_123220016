import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../model/tiket_model.dart';
import '../../../service/tiket_service.dart';
import 'package:artefacto/pages/menu/admin/tiket_form_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await TicketService.getTickets();
      if (response.status == 'sukses') {
        setState(() {
          _tickets = response.data?.tickets ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Gagal memuat tiket';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDeleteTicket(int id) async {
    try {
      final response = await TicketService.deleteTicket(id);
      if (response.status == 'sukses') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Tiket berhasil dihapus')),
        );
        await _loadTickets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Gagal menghapus tiket')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
      );
    }
  }

  void _confirmDelete(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Konfirmasi Hapus", style: GoogleFonts.merriweather(fontWeight: FontWeight.bold)),
        content: Text(
          "Apakah Anda yakin ingin menghapus tiket untuk candi ${ticket.temple?.templeName ?? 'ID ${ticket.ticketID}'}?",
          style: GoogleFonts.openSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: GoogleFonts.openSans(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDeleteTicket(ticket.ticketID!);
            },
            child: Text("Hapus", style: GoogleFonts.openSans(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToForm({Ticket? ticket}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketFormScreen(ticket: ticket)),
    );

    if (result == true) {
      await _loadTickets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kelola Tiket", style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff233743),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () => _navigateToForm(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildError()
            : _tickets.isEmpty
            ? _buildEmptyState()
            : _buildTicketList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage!, style: GoogleFonts.openSans(fontSize: 16, color: Colors.red)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _loadTickets,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "Belum ada data tiket.",
        style: GoogleFonts.openSans(fontSize: 18, color: Colors.black54),
      ),
    );
  }

  Widget _buildTicketList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ID: ${ticket.ticketID}",
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Harga: Rp${ticket.price?.toStringAsFixed(0) ?? 'N/A'}",
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket.description ?? 'Tanpa deskripsi',
                        style: GoogleFonts.openSans(fontSize: 14, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ticket.temple != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Candi: ${ticket.temple?.templeName ?? '-'}",
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Lokasi: ${ticket.temple?.location ?? '-'}",
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _navigateToForm(ticket: ticket),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, ticket),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
