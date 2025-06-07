import 'package:hive/hive.dart';
import '../model/visit_note_model.dart';
import 'auth_service.dart';

class VisitNoteService {
  static const String _boxName = 'visitNotesBox';
  static final AuthService _authService = AuthService();

  // Membuka box Hive
  static Future<Box<VisitNote>> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<VisitNote>(_boxName);
    }
    return Hive.box<VisitNote>(_boxName);
  }

  // Mendapatkan semua catatan untuk user yang sedang login
  static Future<List<VisitNote>> getAllNotes() async {
    final box = await _openBox();
    final currentUserId = await _authService.getUserId();
    if (currentUserId == null) {
      return []; // Return empty list if user is not logged in
    }
    // Filter notes by userID
    return box.values.where((note) => note.userID == currentUserId).toList();
  }

  // Menambah catatan baru
  static Future<void> addNote({
    required String namaCandi,
    required DateTime tanggalKunjungan,
    required String kesanPesan,
  }) async {
    final box = await _openBox();
    final currentUserId = await _authService.getUserId();
    if (currentUserId == null) {
      throw Exception("User tidak terautentikasi.");
    }

    final newNote = VisitNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      namaCandi: namaCandi,
      tanggalKunjungan: tanggalKunjungan,
      kesanPesan: kesanPesan,
      userID: currentUserId,
    );

    await box.put(newNote.id, newNote);
  }

  // Memperbarui catatan yang ada
  static Future<void> updateNote(VisitNote note) async {
    final box = await _openBox();
    final currentUserId = await _authService.getUserId();

    // Verify ownership
    if (currentUserId == null || note.userID != currentUserId) {
      throw Exception("Tidak memiliki akses untuk mengubah catatan ini.");
    }

    await box.put(note.id, note);
  }

  // Menghapus catatan
  static Future<void> deleteNote(String id) async {
    final box = await _openBox();
    final note = box.get(id);
    final currentUserId = await _authService.getUserId();

    // Verify ownership before deletion
    if (note != null && currentUserId != null && note.userID == currentUserId) {
      await box.delete(id);
    } else {
      throw Exception("Tidak memiliki akses untuk menghapus catatan ini.");
    }
  }
}
