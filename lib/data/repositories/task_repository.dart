import '../../data/models/task.dart';
import '../../core/services/hive_service.dart';

class TaskRepository {
  Future<void> addTask(Task task) async {
    await HiveService.addTask(task);
  }

  Future<void> updateTask(Task task) async {
    await HiveService.updateTask(task);
  }

  Future<void> deleteTask(String id) async {
    await HiveService.deleteTask(id);
  }

  List<Task> getAllTasks() {
    return HiveService.getAllTasks();
  }

  List<Task> getTasksForDay(DateTime date) {
    return HiveService.getTasksForDay(date);
  }

  List<Task> getUnscheduledTasks() {
    return HiveService.getUnscheduledTasks();
  }

  Future<void> markComplete(String id, bool completed) async {
    final tasks = getAllTasks();
    final task = tasks.firstWhere((t) => t.id == id);
    await updateTask(task.copyWith(isCompleted: completed));
  }
}
