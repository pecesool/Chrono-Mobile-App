import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/task.dart';
import '../data/models/scheduled_task.dart';
import '../data/repositories/task_repository.dart';
import '../core/services/hive_service.dart';
import '../domain/ai_engine/scheduler.dart';

final taskRepositoryProvider = Provider((ref) => TaskRepository());

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier(ref.read(taskRepositoryProvider));
});

final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

final selectedDayTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskNotifierProvider);
  final day = ref.watch(selectedDayProvider);
  return tasks.where((t) {
    if (t.scheduledStart == null) return false;
    final s = t.scheduledStart!;
    return s.year == day.year && s.month == day.month && s.day == day.day;
  }).toList()
    ..sort((a, b) => (a.scheduledStart ?? DateTime(0))
        .compareTo(b.scheduledStart ?? DateTime(0)));
});

final todayTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskNotifierProvider);
  final today = DateTime.now();
  return tasks.where((t) {
    if (t.scheduledStart == null) return false;
    final s = t.scheduledStart!;
    return s.year == today.year && s.month == today.month && s.day == today.day;
  }).toList()
    ..sort((a, b) => (a.scheduledStart ?? DateTime(0))
        .compareTo(b.scheduledStart ?? DateTime(0)));
});

final unscheduledTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskNotifierProvider);
  return tasks
      .where((t) => t.scheduledStart == null && !t.isCompleted)
      .toList();
});

final scheduledDaysProvider = Provider<List<DateTime>>((ref) {
  final tasks = ref.watch(taskNotifierProvider);
  final days = <DateTime>{};
  for (final t in tasks) {
    if (t.scheduledStart != null) {
      days.add(DateTime(
          t.scheduledStart!.year,
          t.scheduledStart!.month,
          t.scheduledStart!.day));
    }
  }
  final sorted = days.toList()..sort();
  return sorted;
});

class TaskNotifier extends StateNotifier<List<Task>> {
  final TaskRepository _repository;

  TaskNotifier(this._repository) : super([]) {
    loadTasks();
  }

  void loadTasks() {
    state = _repository.getAllTasks();
  }

  Future<void> addTask(Task task) async {
    await _repository.addTask(task);
    loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _repository.updateTask(task);
    loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    loadTasks();
  }

  Future<void> toggleComplete(String id) async {
    final task = state.firstWhere((t) => t.id == id);
    await _repository.updateTask(
        task.copyWith(isCompleted: !task.isCompleted));
    loadTasks();
  }

  Future<void> scheduleTask(String id, DateTime startTime) async {
    final task = state.firstWhere((t) => t.id == id);
    await _repository.updateTask(task.copyWith(scheduledStart: startTime));
    loadTasks();
  }

  Future<void> updateDuration(String id, int minutes) async {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final updated = state[idx].copyWith(estimatedMinutes: minutes);
    await _repository.updateTask(updated);
    loadTasks();
  }

  // ── APPLY SUGGESTIONS ────────────────────────────────────────────────────
  /// Применяет предложения AI:
  /// 1. Удаляет все старые _part_ задачи
  /// 2. Сбрасывает scheduledStart у всех задач которые переоптимизируются
  /// 3. Применяет новые времена из suggestions
  Future<void> applySuggestions(List<ScheduledTask> suggestions) async {
    // Собираем оригинальные ID (без _part_)
    final originalIds = <String>{};
    for (final s in suggestions) {
      final originalId = s.task.id.contains('_part_')
          ? s.task.id.split('_part_').first
          : s.task.id;
      originalIds.add(originalId);
    }

    // Шаг 1: удаляем все _part_ задачи для этих оригинальных ID
    final allTasks = _repository.getAllTasks();
    for (final t in allTasks) {
      if (t.id.contains('_part_')) {
        final originalId = t.id.split('_part_').first;
        if (originalIds.contains(originalId)) {
          await _repository.deleteTask(t.id);
        }
      }
    }

    // Шаг 2: сбрасываем scheduledStart у всех оригинальных задач
    // (чтобы они не висели на старом времени)
    for (final originalId in originalIds) {
      final idx = state.indexWhere((t) => t.id == originalId);
      if (idx != -1) {
        await _repository.updateTask(
          state[idx].copyWith(scheduledStart: null),
        );
      }
    }

    // Шаг 3: перезагружаем state после удалений/сбросов
    loadTasks();

    // Шаг 4: группируем suggestions по оригинальному ID
    final grouped = <String, List<ScheduledTask>>{};
    for (final s in suggestions) {
      final originalId = s.task.id.contains('_part_')
          ? s.task.id.split('_part_').first
          : s.task.id;
      grouped.putIfAbsent(originalId, () => []).add(s);
    }

    // Шаг 5: применяем каждую группу
    for (final entry in grouped.entries) {
      final originalId = entry.key;
      final parts = entry.value
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      // Находим оригинальную задачу в ТЕКУЩЕМ state
      final currentState = _repository.getAllTasks();
      final originalTask = currentState.firstWhere(
        (t) => t.id == originalId,
        orElse: () => parts.first.task.copyWith(
          id: originalId,
          title: parts.first.task.title.replaceAll(RegExp(r' \(ч\. \d+\)$'), ''),
        ),
      );

      if (parts.length == 1) {
        // Одна часть — просто обновляем оригинал
        final updated = originalTask.copyWith(
          scheduledStart: parts.first.startTime,
          estimatedMinutes: parts.first.task.estimatedMinutes,
        );
        await _repository.updateTask(updated);
      } else {
        // Несколько частей
        // Первая часть → обновляем оригинал
        final first = parts.first;
        await _repository.updateTask(originalTask.copyWith(
          scheduledStart: first.startTime,
          estimatedMinutes: first.task.estimatedMinutes,
          title: originalTask.title, // Сохраняем оригинальное название
        ));

        // Остальные части → новые задачи
        for (var i = 1; i < parts.length; i++) {
          final part = parts[i];
          // Генерируем уникальный ID для части
          final partId = '${originalId}_part_$i';
          final partTask = Task(
            id: partId,
            title: '${originalTask.title} (ч. ${i + 1})',
            priority: originalTask.priority,
            deadline: originalTask.deadline,
            estimatedMinutes: part.task.estimatedMinutes,
            scheduledStart: part.startTime,
            isCompleted: originalTask.isCompleted,
            createdAt: originalTask.createdAt,
          );
          await _repository.addTask(partTask);
        }
      }
    }

    loadTasks();
  }

  // ── SCHEDULE UNSCHEDULED ──────────────────────────────────────────────────
  Future<List<ScheduledTask>> scheduleUnscheduled() async {
    final profile = HiveService.getUserProfile();
    if (profile == null) throw Exception('No profile');

    final scheduler = AIScheduler(profile);
    final unscheduled =
        state.where((t) => t.scheduledStart == null && !t.isCompleted).toList();
    if (unscheduled.isEmpty) return [];

    final alreadyScheduled =
        state.where((t) => t.scheduledStart != null).toList();

    return scheduler.scheduleMultiDay(
      unscheduled,
      alreadyScheduled,
      DateTime.now(),
    );
  }

  // ── OPTIMIZE SCHEDULED ───────────────────────────────────────────────────
  /// Переоптимизирует уже запланированные задачи.
  /// Полностью сбрасывает расписание и строит заново по выбранным критериям.
  Future<List<ScheduledTask>> optimizeScheduled({
    bool priorityFirst = false,
    bool byDeadline = false,
    bool byDuration = false,
  }) async {
    final profile = HiveService.getUserProfile();
    if (profile == null) throw Exception('No profile');

    final scheduler = AIScheduler(profile);

    // Берём только оригинальные задачи (без _part_), не завершённые
    final scheduled = state
        .where((t) =>
            t.scheduledStart != null &&
            !t.isCompleted &&
            !t.id.contains('_part_'))
        .toList();

    // Добавляем незапланированные тоже (если есть)
    final unscheduled = state
        .where((t) => t.scheduledStart == null && !t.isCompleted)
        .toList();

    final allToOptimize = [...scheduled, ...unscheduled];
    if (allToOptimize.isEmpty) return [];

    // Восстанавливаем полную продолжительность задач, которые были разбиты:
    // оригинальная задача хранит только первый кусок, остальное в _part_ задачах.
    final virtualTasks = allToOptimize.map((t) {
      final parts = state
          .where((p) => p.id.startsWith('${t.id}_part_') && !p.isCompleted)
          .toList();
      final totalMinutes = parts.fold(
        t.estimatedMinutes,
        (sum, p) => sum + p.estimatedMinutes,
      );
      return t.copyWith(scheduledStart: null, estimatedMinutes: totalMinutes);
    }).toList();

    // Строим расписание заново с нуля
    final suggestions = scheduler.scheduleMultiDay(
      virtualTasks,
      [], // Передаём пустой список — перестраиваем полностью
      DateTime.now(),
      priorityFirst: priorityFirst || byDeadline,
      shortFirst: byDuration,
      byDeadline: byDeadline,
      fromDayStart: false,
    );

    return suggestions;
  }

  List<Task> getFilteredTasks({
    Priority? priority,
    int? maxDuration,
    int? minDuration,
    bool? unscheduledOnly,
  }) {
    var result = List<Task>.from(state);
    if (priority != null) result = result.where((t) => t.priority == priority).toList();
    if (maxDuration != null) result = result.where((t) => t.estimatedMinutes <= maxDuration).toList();
    if (minDuration != null) result = result.where((t) => t.estimatedMinutes >= minDuration).toList();
    if (unscheduledOnly == true) result = result.where((t) => t.scheduledStart == null).toList();
    result.sort((a, b) {
      final d = a.deadline.compareTo(b.deadline);
      if (d != 0) return d;
      return a.priority.index.compareTo(b.priority.index);
    });
    return result;
  }
}