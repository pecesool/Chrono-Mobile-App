
part of 'scheduled_task.dart';

class ScheduledTaskAdapter extends TypeAdapter<ScheduledTask> {
  @override
  final int typeId = 4;

  @override
  ScheduledTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduledTask(
      task: fields[0] as Task,
      startTime: fields[1] as DateTime,
      actualDuration: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduledTask obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.task)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.actualDuration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
