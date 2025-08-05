// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChallengeEntryAdapter extends TypeAdapter<ChallengeEntry> {
  @override
  final int typeId = 0;

  @override
  ChallengeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChallengeEntry(
      challengeText: fields[0] as String,
      date: fields[1] as DateTime,
      modifiers: (fields[2] as List).cast<String>(),
      completed: fields[3] as bool,
      category: fields[4] as String,
      difficulty: fields[5] as String,
      id: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ChallengeEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.challengeText)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.modifiers)
      ..writeByte(3)
      ..write(obj.completed)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.difficulty)
      ..writeByte(6)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ModifierAdapter extends TypeAdapter<Modifier> {
  @override
  final int typeId = 1;

  @override
  Modifier read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Modifier(
      id: fields[0] as String,
      text: fields[1] as String,
      points: fields[2] as int,
      icon: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Modifier obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.points)
      ..writeByte(3)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModifierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
