import 'package:flutter/material.dart';
import 'package:artefacto/model/tiket_model.dart';
import 'package:artefacto/service/tiket_service.dart';
import 'package:artefacto/model/temple_model.dart';
import 'package:artefacto/service/temple_service.dart';
// import 'package:google_fonts/google_fonts.dart'; // opsional

class TicketFormScreen extends StatefulWidget {
  final Ticket? ticket; // Null means add mode
  const TicketFormScreen({super.key, this.ticket});

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _templeIdController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  List<Temple> _templeList = [];
  bool _isTempleLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.ticket != null) {
      _templeIdController.text = widget.ticket!.templeID?.toString() ?? '';
      _priceController.text = widget.ticket!.price?.toString() ?? '';
      _descriptionController.text = widget.ticket!.description ?? '';
    }
    _fetchTemples();
  }

  Future<void> _fetchTemples() async {
    setState(() => _isTempleLoading = true);
    try {
      final temples = await TempleService.getTemples();
      setState(() {
        _templeList = temples;
        _isTempleLoading = false;
      });
    } catch (e) {
      setState(() => _isTempleLoading = false);
      _errorMessage = 'Gagal memuat daftar candi: $e';
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final ticketRequest = TicketRequest(
          templeID: int.parse(_templeIdController.text),
          price: double.parse(_priceController.text),
          description: _descriptionController.text,
        );

        late TicketResponse response;
        if (widget.ticket != null) {
          response = await TicketService.updateTicket(
            widget.ticket!.ticketID!,
            ticketRequest,
          );
        } else {
          response = await TicketService.createTicket(ticketRequest);
        }

        if (response.status == 'sukses') {
          if (!mounted) return;
          Navigator.pop(context, true);
        } else {
          if (!mounted) return;
          setState(() {
            _errorMessage = response.message ?? 'Operasi gagal';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _templeIdController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.ticket != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Tiket' : 'Buat Tiket Baru'),
        backgroundColor: const Color(0xff233743),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _isTempleLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                    value:
                        _templeIdController.text.isNotEmpty
                            ? int.tryParse(_templeIdController.text)
                            : null,
                    items:
                        _templeList
                            .map(
                              (temple) => DropdownMenuItem<int>(
                                value: temple.templeID,
                                child: Text(
                                  temple.title ?? 'Candi ${temple.templeID}',
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _templeIdController.text = value?.toString() ?? '';
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Pilih Candi',
                      hintText: 'Pilih candi untuk tiket',
                    ),
                    validator: (value) {
                      if (value == null) {
                        return 'Pilih candi terlebih dahulu';
                      }
                      return null;
                    },
                  ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  hintText: 'Masukkan harga tiket',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Harga tiket wajib diisi';
                  final price = double.tryParse(value);
                  if (price == null) return 'Harga harus berupa angka';
                  if (price < 0)
                    return 'Harga tiket harus berupa angka positif';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Masukkan deskripsi tiket',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Deskripsi tiket wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff233743),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(isEditMode ? 'Simpan Perubahan' : 'Buat Tiket'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
