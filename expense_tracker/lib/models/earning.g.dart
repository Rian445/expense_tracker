// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earning.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EarningAdapter extends TypeAdapter<Earning> {
  @override
  final int typeId = 1;

  @override
  Earning read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Earning(
      id: fields[0] as String,
      incomeSource: fields[1] as String,
      amount: fields[2] as double,
      receiveMethod: fields[3] as String,
      date: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Earning obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.incomeSource)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.receiveMethod)
      ..writeByte(4)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarningAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
