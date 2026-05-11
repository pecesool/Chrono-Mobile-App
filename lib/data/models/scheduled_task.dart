import 'package:hive/hive.dart';
import 'task.dart';

part 'scheduled_task.g.dart';

@HiveType(typeId: 4)
class ScheduledTask extends HiveObject {
  @HiveField(0)
  Task task;

  @HiveField(1)
  DateTime startTime;

  @HiveField(2)
  int? actualDuration;

  ScheduledTask({
    required this.task,
    required this.startTime,
    this.actualDuration,
  });

  DateTime get endTime => startTime.add(Duration(minutes: task.estimatedMinutes));
}
