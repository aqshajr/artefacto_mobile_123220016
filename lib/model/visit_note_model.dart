import 'package:hive/hive.dart';

part 'visit_note_model.g.dart';

@HiveType(typeId: 1)
class VisitNote {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String namaCandi;

  @HiveField(2)
  final DateTime tanggalKunjungan;

  @HiveField(3)
  final String kesanPesan;

  @HiveField(4)
  final int userID; // Changed from String? to int to match auth_service

  VisitNote({
    required this.id,
    required this.namaCandi,
    required this.tanggalKunjungan,
    required this.kesanPesan,
    required this.userID,
  });

  // Helper method untuk mengkonversi userID
  static String normalizeUserId(dynamic userId) {
    if (userId == null) return '';
    return userId.toString();
  }
}
