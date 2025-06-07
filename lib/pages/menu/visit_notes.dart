import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../model/visit_note_model.dart';
import '../../model/temple_model.dart';
import '../../service/visit_note_service.dart';
import '../../service/temple_service.dart';

class VisitNotesPage extends StatefulWidget {
  const VisitNotesPage({super.key});

  @override
  State<VisitNotesPage> createState() => _VisitNotesPageState();
}

class _VisitNotesPageState extends State<VisitNotesPage> {
  List<VisitNote> notes = [];
  List<Temple> temples = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final loadedNotes = await VisitNoteService.getAllNotes();
      final loadedTemples = await TempleService.getTemples();
      setState(() {
        notes = loadedNotes;
        temples = loadedTemples;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showAddEditNoteDialog([VisitNote? note]) async {
    final formKey = GlobalKey<FormState>();
    Temple? selectedTemple;
    if (note != null && temples.isNotEmpty) {
      selectedTemple = temples.firstWhere(
        (temple) => temple.title == note.namaCandi,
        orElse: () => temples.first,
      );
    }
    final kesanPesanController = TextEditingController(text: note?.kesanPesan);
    DateTime selectedDate = note?.tanggalKunjungan ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          note == null ? 'Tambah Catatan' : 'Edit Catatan',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Temple>(
                  value: selectedTemple,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Candi',
                    border: OutlineInputBorder(),
                  ),
                  items: temples.map((temple) {
                    return DropdownMenuItem(
                      value: temple,
                      child: Text(temple.title ?? 'Tidak ada nama'),
                    );
                  }).toList(),
                  onChanged: (Temple? value) {
                    selectedTemple = value;
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Silakan pilih candi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Kunjungan',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      DateFormat('dd MMMM yyyy').format(selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: kesanPesanController,
                  decoration: const InputDecoration(
                    labelText: 'Kesan & Pesan',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kesan & pesan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && selectedTemple != null) {
                if (note == null) {
                  // Tambah catatan baru
                  await VisitNoteService.addNote(
                    namaCandi: selectedTemple?.title ?? 'Tidak ada nama',
                    tanggalKunjungan: selectedDate,
                    kesanPesan: kesanPesanController.text,
                  );
                } else {
                  // Buat catatan baru dengan ID yang sama untuk update
                  final updatedNote = VisitNote(
                    id: note.id,
                    namaCandi: selectedTemple?.title ?? 'Tidak ada nama',
                    tanggalKunjungan: selectedDate,
                    kesanPesan: kesanPesanController.text,
                    userID: note.userID,
                  );
                  await VisitNoteService.updateNote(updatedNote);
                }
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              }
            },
            child: Text(note == null ? 'Simpan' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(VisitNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await VisitNoteService.deleteNote(note.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Catatan Kunjungan',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff233743),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada catatan kunjungan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(
                          note.namaCandi,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Tanggal: ${DateFormat('dd MMMM yyyy').format(note.tanggalKunjungan)}',
                            ),
                            const SizedBox(height: 4),
                            Text(note.kesanPesan),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditNoteDialog(note),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _deleteNote(note),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditNoteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
