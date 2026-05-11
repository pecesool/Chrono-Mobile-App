import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String wakeUpTime;

  @HiveField(1)
  ProductivityPeak peakHours;

  @HiveField(2)
  int maxFocusMinutes;

  @HiveField(3)
  List<String> commonTasks;

  @HiveField(4)
  String timeManagementIssue;

  @HiveField(5)
  bool isOnboardingCompleted;

  UserProfile({
    required this.wakeUpTime,
    required this.peakHours,
    required this.maxFocusMinutes,
    required this.commonTasks,
    required this.timeManagementIssue,
    this.isOnboardingCompleted = false,
  });

  UserProfile copyWith({
    String? wakeUpTime,
    ProductivityPeak? peakHours,
    int? maxFocusMinutes,
    List<String>? commonTasks,
    String? timeManagementIssue,
    bool? isOnboardingCompleted,
  }) {
    return UserProfile(
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      peakHours: peakHours ?? this.peakHours,
      maxFocusMinutes: maxFocusMinutes ?? this.maxFocusMinutes,
      commonTasks: commonTasks ?? this.commonTasks,
      timeManagementIssue: timeManagementIssue ?? this.timeManagementIssue,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
    );
  }
}

@HiveType(typeId: 1)
enum ProductivityPeak {
  @HiveField(0)
  morning,
  @HiveField(1)
  day,
  @HiveField(2)
  evening,
}
