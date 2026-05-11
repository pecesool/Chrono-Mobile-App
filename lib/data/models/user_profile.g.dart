
part of 'user_profile.dart';

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      wakeUpTime: fields[0] as String,
      peakHours: fields[1] as ProductivityPeak,
      maxFocusMinutes: fields[2] as int,
      commonTasks: (fields[3] as List).cast<String>(),
      timeManagementIssue: fields[4] as String,
      isOnboardingCompleted: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.wakeUpTime)
      ..writeByte(1)
      ..write(obj.peakHours)
      ..writeByte(2)
      ..write(obj.maxFocusMinutes)
      ..writeByte(3)
      ..write(obj.commonTasks)
      ..writeByte(4)
      ..write(obj.timeManagementIssue)
      ..writeByte(5)
      ..write(obj.isOnboardingCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductivityPeakAdapter extends TypeAdapter<ProductivityPeak> {
  @override
  final int typeId = 1;

  @override
  ProductivityPeak read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProductivityPeak.morning;
      case 1:
        return ProductivityPeak.day;
      case 2:
        return ProductivityPeak.evening;
      default:
        return ProductivityPeak.morning;
    }
  }

  @override
  void write(BinaryWriter writer, ProductivityPeak obj) {
    switch (obj) {
      case ProductivityPeak.morning:
        writer.writeByte(0);
        break;
      case ProductivityPeak.day:
        writer.writeByte(1);
        break;
      case ProductivityPeak.evening:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductivityPeakAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
