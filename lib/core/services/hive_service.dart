import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/task.dart';
import '../../data/models/scheduled_task.dart';

class HiveService {
  static Box<UserProfile> get userProfileBox => Hive.box<UserProfile>('userProfile');
  static Box<Task> get tasksBox => Hive.box<Task>('tasks');
  static Box<ScheduledTask> get scheduledBox => Hive.box<ScheduledTask>('scheduledTasks');
  static Box get settingsBox => Hive.box('settings');

  // User Profile
  static Future<void> saveUserProfile(UserProfile profile) async {
    await userProfileBox.put('current', profile);
  }

  static UserProfile? getUserProfile() {
    return userProfileBox.get('current');
  }

  static bool hasUserProfile() {
    return userProfileBox.containsKey('current');
  }

  static bool isOnboardingComplete() {
    final profile = getUserProfile();
    if (profile != null) {
      return profile.isOnboardingCompleted;
    }
    return settingsBox.get('onboardingComplete', defaultValue: false);
  }

  static Future<void> setOnboardingComplete(bool value) async {
    final profile = getUserProfile();
    if (profile != null) {
      profile.isOnboardingCompleted = value;
      await profile.save();
    }
    await settingsBox.put('onboardingComplete', value);
  }

  // Tasks
  static Future<void> addTask(Task task) async {
    await tasksBox.put(task.id, task);
  }

  static Future<void> updateTask(Task task) async {
    await tasksBox.put(task.id, task);
  }

  static Future<void> deleteTask(String id) async {
    await tasksBox.delete(id);

    // Only cascade-delete sibling parts when deleting an ORIGINAL task.
    // Deleting a _part_ task (e.g. "111 ч.2") must NOT touch other parts.
    if (!id.contains('_part_')) {
      final keysToDelete = <String>[];
      for (final entry in tasksBox.toMap().entries) {
        if (entry.value.id.startsWith('${id}_part_')) {
          keysToDelete.add(entry.key);
        }
      }
      for (final key in keysToDelete) {
        await tasksBox.delete(key);
      }
    }
  }

  static List<Task> getAllTasks() {
    return tasksBox.values.toList();
  }

  static List<Task> getTasksForDay(DateTime date) {
    return tasksBox.values.where((t) {
      return t.scheduledStart != null &&
             DateTime(t.scheduledStart!.year, t.scheduledStart!.month, t.scheduledStart!.day) ==
             DateTime(date.year, date.month, date.day);
    }).toList();
  }

  static List<Task> getUnscheduledTasks() {
    return tasksBox.values.where((t) => t.scheduledStart == null).toList();
  }

  // Scheduled Tasks
  static Future<void> saveScheduledTasks(List<ScheduledTask> tasks) async {
    await scheduledBox.clear();
    for (var i = 0; i < tasks.length; i++) {
      await scheduledBox.put(i.toString(), tasks[i]);
    }
  }

  static List<ScheduledTask> getScheduledTasks() {
    return scheduledBox.values.toList();
  }

  // Settings
  static Future<void> setSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue);
  }
}
