// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VisitNoteAdapter extends TypeAdapter<VisitNote> {
  @override
  final int typeId = 1;

  @override
  VisitNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VisitNote(
      id: fields[0] as String,
      namaCandi: fields[1] as String,
      tanggalKunjungan: fields[2] as DateTime,
      kesanPesan: fields[3] as String,
      userID: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, VisitNote obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.namaCandi)
      ..writeByte(2)
      ..write(obj.tanggalKunjungan)
      ..writeByte(3)
      ..write(obj.kesanPesan)
      ..writeByte(4)
      ..write(obj.userID);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
