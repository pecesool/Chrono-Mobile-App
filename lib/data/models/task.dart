import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  Priority priority;

  @HiveField(3)
  DateTime deadline;

  @HiveField(4)
  int estimatedMinutes;

  @HiveField(5)
  DateTime? scheduledStart;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  DateTime createdAt;

  Task({
    String? id,
    required this.title,
    required this.priority,
    required this.deadline,
    required this.estimatedMinutes,
    this.scheduledStart,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    Priority? priority,
    DateTime? deadline,
    int? estimatedMinutes,
    DateTime? scheduledStart,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  DateTime? get scheduledEnd {
    if (scheduledStart == null) return null;
    return scheduledStart!.add(Duration(minutes: estimatedMinutes));
  }
}

@HiveType(typeId: 3)
enum Priority {
  @HiveField(0)
  high,
  @HiveField(1)
  medium,
  @HiveField(2)
  low,
}
