import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/tiket_model.dart';
import '../../model/transaction_model.dart';
import '../../service/transaksi_service.dart';
import '../menu/currency_converter_page.dart';
import '../menu/home.dart';

class TicketPurchasePage extends StatefulWidget {
  final Ticket ticket;

  const TicketPurchasePage({Key? key, required this.ticket}) : super(key: key);

  @override
  State<TicketPurchasePage> createState() => _TicketPurchasePageState();
}

class _TicketPurchasePageState extends State<TicketPurchasePage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String _validDate = '';
  String _message = '';
  bool _isLoading = false;

  // State untuk menyimpan hasil konversi terakhir
  double? _lastConvertedAmount;
  String? _lastConvertedCurrencyCode;
  final Map<String, String> _currencyNames = {
    // Salin dari CurrencyConverterPage untuk display
    'USD': 'Dolar Amerika',
    'EUR': 'Euro',
    'JPY': 'Yen Jepang',
    'GBP': 'Pound Sterling',
    'AUD': 'Dolar Australia',
    'CAD': 'Dolar Kanada',
    'CHF': 'Franc Swiss',
    'CNY': 'Yuan Tiongkok',
    'IDR': 'Rupiah Indonesia',
    'SGD': 'Dolar Singapura',
    'MYR': 'Ringgit Malaysia',
  };

  @override
  void dispose() {
    _dateController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        // Optional: Themeing the date picker
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xffB69574), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Color(0xff233743), // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xffB69574), // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _validDate = DateFormat('yyyy-MM-dd').format(picked);
        _dateController.text = _validDate;
      });
    }
  }

  Future<void> _handlePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final request = TransactionRequest(
        ticketId: widget.ticket.ticketID!.toString(),
        quantity: int.parse(_quantityController.text),
        validDate: DateTime.parse(_validDate),
      );

      final response = await TransaksiService.createTransaction(request);

      if (mounted) {
        if (response.status == 'sukses') {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tiket berhasil dibeli!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to Home page which has the bottom navigation
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        } else {
          setState(() => _message = response.message ?? 'Gagal membeli tiket');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final priceFormatted =
        NumberFormat('#,##0', 'id_ID').format(ticket.price ?? 0);

    String displayPrice = 'Rp $priceFormatted';
    if (_lastConvertedAmount != null && _lastConvertedCurrencyCode != null) {
      String convertedAmountFormatted =
          NumberFormat('#,##0.00', 'en_US').format(_lastConvertedAmount);
      displayPrice +=
          '\n≈ $_lastConvertedCurrencyCode $convertedAmountFormatted';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pembelian Tiket',
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ticket Info Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                                const Icon(
                                  Icons.confirmation_number_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Detail Tiket',
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
                                  ticket.temple?.templeName ?? 'Tiket Wisata',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xff233743),
                                  ),
                                ),
                                if (ticket.description != null &&
                                    ticket.description!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    ticket.description!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        displayPrice,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          height: 1.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xffB69574),
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(top: 8),
                                        child: TextButton.icon(
                                          icon: const Icon(
                                            Icons.currency_exchange,
                                            size: 18,
                                            color: Color(0xff233743),
                                          ),
                                          label: Text(
                                            'Konversi Mata Uang',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: const Color(0xff233743),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                              horizontal: 16,
                                            ),
                                            backgroundColor: Colors.grey[100],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CurrencyConverterPage(
                                                  initialAmount: ticket.price,
                                                ),
                                              ),
                                            );
                                            if (result != null &&
                                                result
                                                    is Map<String, dynamic>) {
                                              setState(() {
                                                _lastConvertedAmount =
                                                    result['amount'] as double?;
                                                _lastConvertedCurrencyCode =
                                                    result['currency']
                                                        as String?;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Purchase Form Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                                const Icon(
                                  Icons.edit_note_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Form Pembelian',
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
                                  'Tanggal Kunjungan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xff233743),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _dateController,
                                  readOnly: true,
                                  onTap: () => _selectDate(context),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xff233743),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Pilih tanggal kunjungan',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.calendar_today,
                                      size: 22,
                                      color: Color(0xff233743),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade200),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade200),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Color(0xffB69574)),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Pilih tanggal kunjungan';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Jumlah Tiket',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xff233743),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xff233743),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan jumlah tiket',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.group_outlined,
                                      size: 22,
                                      color: Color(0xff233743),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade200),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade200),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Color(0xffB69574)),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Masukkan jumlah tiket';
                                    }
                                    final number = int.tryParse(value);
                                    if (number == null || number < 1) {
                                      return 'Jumlah tiket minimal 1';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Purchase Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handlePurchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffB69574),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Beli Tiket',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
