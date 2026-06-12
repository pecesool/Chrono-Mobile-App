import '../../data/models/user_profile.dart';
import '../../data/models/task.dart';
import '../../data/models/scheduled_task.dart';

class TimeSlot {
  final DateTime start;
  final DateTime end;
  TimeSlot(this.start, this.end);
  Duration get duration => end.difference(start);
  bool overlaps(TimeSlot other) =>
      start.isBefore(other.end) && end.isAfter(other.start);
}

/// Настройки планировщика — можно будет вынести в UI
class SchedulerConfig {
  /// Минимальный перерыв между задачами (минут)
  final int breakBetweenTasks;

  /// Перерыв между частями одной задачи (минут)
  final int breakBetweenChunks;

  /// Максимум часов задач в день (чтобы не перегружать)
  final int maxTaskHoursPerDay;

  /// Распределять задачи равномерно по дням (не кидать всё в один день)
  final bool distributeEvenly;

  const SchedulerConfig({
    this.breakBetweenTasks = 30,
    this.breakBetweenChunks = 30,
    this.maxTaskHoursPerDay = 6,
    this.distributeEvenly = true,
  });
}

class AIScheduler {
  final UserProfile profile;
  final SchedulerConfig config;

  AIScheduler(this.profile, {this.config = const SchedulerConfig()});

  // ── Static keyword estimator ──────────────────────────────────────────────
  static int estimateTime(String taskTitle) {
    final lower = taskTitle.toLowerCase();
    if (lower.contains('essay') || lower.contains('реферат') || lower.contains('эссе')) return 180;
    if (lower.contains('lab') || lower.contains('лаб') || lower.contains('лаборатор')) return 120;
    if (lower.contains('exam') || lower.contains('экзамен') || lower.contains('зачёт') || lower.contains('зачет')) return 240;
    if (lower.contains('test') || lower.contains('тест') || lower.contains('quiz') || lower.contains('контрольн')) return 90;
    if (lower.contains('presentation') || lower.contains('презентац') || lower.contains('доклад') || lower.contains('report')) return 90;
    if (lower.contains('reading') || lower.contains('чтение') || lower.contains('читать')) return 45;
    if (lower.contains('homework') || lower.contains('домашн') || lower.contains('assignment')) return 90;
    if (lower.contains('project') || lower.contains('проект')) return 150;
    if (lower.contains('gym') || lower.contains('спорт') || lower.contains('тренировк')) return 90;
    if (lower.contains('meeting') || lower.contains('встреч')) return 60;
    return 60;
  }

  // ── Main scheduling method ────────────────────────────────────────────────
  List<ScheduledTask> scheduleMultiDay(
    List<Task> unscheduled,
    List<Task> alreadyScheduled,
    DateTime startDate, {
    bool priorityFirst = false,
    bool shortFirst = false,
    bool byDeadline = false,
    bool fromDayStart = false,
  }) {
    final result = <ScheduledTask>[];

    // Карта занятых слотов по дням (из уже запланированных задач)
    final occupiedByDay = <DateTime, List<TimeSlot>>{};
    // Счётчик минут задач в день (для равномерного распределения)
    final minutesByDay = <DateTime, int>{};

    for (final t in alreadyScheduled) {
      if (t.scheduledStart == null) continue;
      final day = _dayKey(t.scheduledStart!);
      final slotEnd = t.scheduledStart!.add(Duration(minutes: t.estimatedMinutes));
      // Добавляем задачу + перерыв после неё
      occupiedByDay.putIfAbsent(day, () => []).add(TimeSlot(t.scheduledStart!, slotEnd));
      minutesByDay[day] = (minutesByDay[day] ?? 0) + t.estimatedMinutes;
    }

    final sorted = _sortTasks(
      unscheduled,
      priorityFirst: priorityFirst,
      shortFirst: shortFirst,
      byDeadline: byDeadline,
    );

    for (final task in sorted) {
      if (task.isCompleted) continue;

      final placed = _placeTask(
        task: task,
        result: result,
        occupiedByDay: occupiedByDay,
        minutesByDay: minutesByDay,
        startDate: startDate,
        fromDayStart: fromDayStart,
      );

      if (!placed) {
        final daysUntilDeadline = _dayKey(task.deadline)
            .difference(_dayKey(DateTime.now()))
            .inDays;
        bool placed2 = false;
        if (daysUntilDeadline <= 3) {
          // Near-deadline: relax load limits but still respect the deadline day
          placed2 = _placeTask(
            task: task,
            result: result,
            occupiedByDay: occupiedByDay,
            minutesByDay: minutesByDay,
            startDate: startDate,
            fromDayStart: fromDayStart,
            relaxLoad: true,
          );
        } else {
          // Far deadline: allow a limited range beyond it
          placed2 = _placeTask(
            task: task,
            result: result,
            occupiedByDay: occupiedByDay,
            minutesByDay: minutesByDay,
            startDate: startDate,
            fromDayStart: fromDayStart,
            extendedRange: true,
          );
        }

        // Last resort: relax load limits and, only for truly overdue tasks
        // (deadline already passed), also extend past the deadline.
        // Never push a future-deadline task past its deadline.
        if (!placed2) {
          final isOverdue = daysUntilDeadline < 0;
          _placeTask(
            task: task,
            result: result,
            occupiedByDay: occupiedByDay,
            minutesByDay: minutesByDay,
            startDate: startDate,
            fromDayStart: fromDayStart,
            relaxLoad: true,
            extendedRange: isOverdue,
          );
        }
      }
    }

    return result;
  }

  // ── Place single task (possibly split across days) ────────────────────────
  bool _placeTask({
    required Task task,
    required List<ScheduledTask> result,
    required Map<DateTime, List<TimeSlot>> occupiedByDay,
    required Map<DateTime, int> minutesByDay,
    required DateTime startDate,
    required bool fromDayStart,
    bool extendedRange = false,
    bool relaxLoad = false,
  }) {
    final deadline = task.deadline;
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day, 23, 59);
    final maxDays = extendedRange ? 14 : 30;

    final today = _dayKey(DateTime.now());
    final daysUntilDeadline = _dayKey(deadlineDay).difference(today).inDays;
    final isUrgent = daysUntilDeadline <= 1;

    final chunks = _splitIntoChunks(task);

    if (chunks.length == 1) {
      return _placeSingleChunk(
        chunk: chunks[0],
        originalTask: task,
        result: result,
        occupiedByDay: occupiedByDay,
        minutesByDay: minutesByDay,
        startDate: startDate,
        deadlineDay: deadlineDay,
        fromDayStart: fromDayStart,
        maxDays: maxDays,
        extendedRange: extendedRange,
        relaxLoad: relaxLoad,
        partIndex: 0,
        totalParts: 1,
      );
    }

    // Spread chunks starting from today.
    // allowSameDay=true for urgent tasks so multiple chunks can share one day,
    // filling today's free slots before spilling into the deadline day.
    return _spreadChunksAcrossDifferentDays(
      task: task,
      chunks: chunks,
      result: result,
      occupiedByDay: occupiedByDay,
      minutesByDay: minutesByDay,
      startDate: startDate,
      deadlineDay: deadlineDay,
      fromDayStart: fromDayStart,
      maxDays: maxDays,
      extendedRange: extendedRange,
      relaxLoad: relaxLoad,
      allowSameDay: isUrgent,
    );
  }

  bool _placeSingleChunk({
    required Task chunk,
    required Task originalTask,
    required List<ScheduledTask> result,
    required Map<DateTime, List<TimeSlot>> occupiedByDay,
    required Map<DateTime, int> minutesByDay,
    required DateTime startDate,
    required DateTime deadlineDay,
    required bool fromDayStart,
    required int maxDays,
    required bool extendedRange,
    required int partIndex,
    required int totalParts,
    bool relaxLoad = false,
  }) {
    final candidates = <_DayCandidate>[];

    for (var d = 0; d <= maxDays; d++) {
      final targetDay = startDate.add(Duration(days: d));
      final targetDayKey = _dayKey(targetDay);

      if (!extendedRange && targetDayKey.isAfter(deadlineDay)) break;

      final dayMinutes = minutesByDay[targetDayKey] ?? 0;
      final maxDayMinutes = config.maxTaskHoursPerDay * 60;

      // Skip overloaded days unless we're relaxing load limits
      if (!relaxLoad && config.distributeEvenly && dayMinutes >= maxDayMinutes && candidates.isNotEmpty) {
        continue;
      }

      final occupied = List<TimeSlot>.from(occupiedByDay[targetDayKey] ?? []);
      final freeSlots = _generateFreeSlots(
        targetDay,
        occupied,
        fromDayStart: fromDayStart && d == 0,
      );

      final slot = _findBestSlot(chunk, freeSlots);
      if (slot != null) {
        candidates.add(_DayCandidate(
          day: d,
          targetDay: targetDay,
          slot: slot,
          dayMinutes: dayMinutes,
        ));
      }
    }

    if (candidates.isEmpty) return false;

    // Выбираем день с наименьшей нагрузкой (если равномерное распределение)
    // Но учитываем приоритет: high priority → peak hours важнее
    final best = _selectBestCandidate(candidates, chunk);

    final targetDayKey = _dayKey(best.targetDay);
    final slotEnd = best.slot.start.add(Duration(minutes: chunk.estimatedMinutes));

    // Помечаем слот как занятый + добавляем перерыв после
    occupiedByDay.putIfAbsent(targetDayKey, () => []).add(
      TimeSlot(best.slot.start, slotEnd),
    );

    // Добавляем перерыв между задачами
    final breakEnd = slotEnd.add(Duration(minutes: config.breakBetweenTasks));
    if (breakEnd.hour < 23) {
      occupiedByDay[targetDayKey]!.add(TimeSlot(slotEnd, breakEnd));
    }

    minutesByDay[targetDayKey] = (minutesByDay[targetDayKey] ?? 0) + chunk.estimatedMinutes;

    result.add(ScheduledTask(task: chunk, startTime: best.slot.start));
    return true;
  }

  /// Распределяем части задачи по дням с перерывом между сессиями.
  /// allowSameDay=true (urgent): все части могут лечь в один день.
  ///
  /// Works on COPIES of occupiedByDay/minutesByDay so that a partial failure
  /// (chunks 1–2 placed, chunk 3 fails) leaves the original maps untouched.
  /// Changes are committed only when ALL chunks are successfully placed.
  bool _spreadChunksAcrossDifferentDays({
    required Task task,
    required List<Task> chunks,
    required List<ScheduledTask> result,
    required Map<DateTime, List<TimeSlot>> occupiedByDay,
    required Map<DateTime, int> minutesByDay,
    required DateTime startDate,
    required DateTime deadlineDay,
    required bool fromDayStart,
    required int maxDays,
    required bool extendedRange,
    bool relaxLoad = false,
    bool allowSameDay = false,
  }) {
    final placedChunks = <ScheduledTask>[];

    // Work on temporary copies — commit only when all chunks succeed
    final tempOccupied = Map<DateTime, List<TimeSlot>>.fromEntries(
      occupiedByDay.entries.map((e) => MapEntry(e.key, List<TimeSlot>.from(e.value))),
    );
    final tempMinutes = Map<DateTime, int>.from(minutesByDay);

    int searchFromDay = 0;
    int? lastPlacedDay;

    for (int chunkIdx = 0; chunkIdx < chunks.length; chunkIdx++) {
      final chunk = chunks[chunkIdx];
      bool chunkPlaced = false;

      for (var d = searchFromDay; d <= maxDays; d++) {
        final targetDay = startDate.add(Duration(days: d));
        final targetDayKey = _dayKey(targetDay);

        if (!extendedRange && targetDayKey.isAfter(deadlineDay)) break;

        // Enforce different days unless urgent (allowSameDay)
        if (!allowSameDay && lastPlacedDay != null && d == lastPlacedDay) continue;

        final dayMinutes = tempMinutes[targetDayKey] ?? 0;
        final maxDayMinutes = config.maxTaskHoursPerDay * 60;

        // Skip overloaded days unless relaxing load limits
        if (!relaxLoad && config.distributeEvenly && dayMinutes + chunk.estimatedMinutes > maxDayMinutes) {
          continue;
        }

        final occupied = List<TimeSlot>.from(tempOccupied[targetDayKey] ?? []);
        final freeSlots = _generateFreeSlots(
          targetDay,
          occupied,
          fromDayStart: fromDayStart && d == 0,
        );

        final slot = _findBestSlot(chunk, freeSlots);
        if (slot != null) {
          final slotEnd = slot.start.add(Duration(minutes: chunk.estimatedMinutes));

          tempOccupied.putIfAbsent(targetDayKey, () => []).add(TimeSlot(slot.start, slotEnd));

          final breakEnd = slotEnd.add(Duration(minutes: config.breakBetweenChunks));
          if (breakEnd.hour < 23) {
            tempOccupied[targetDayKey]!.add(TimeSlot(slotEnd, breakEnd));
          }

          tempMinutes[targetDayKey] = dayMinutes + chunk.estimatedMinutes;

          placedChunks.add(ScheduledTask(task: chunk, startTime: slot.start));
          lastPlacedDay = d;
          searchFromDay = allowSameDay ? d : d + 1;
          chunkPlaced = true;
          break;
        }
      }

      if (!chunkPlaced) {
        // Temp maps are simply discarded — original maps stay clean
        return false;
      }
    }

    // All chunks placed — commit temp maps to actual maps
    for (final entry in tempOccupied.entries) {
      occupiedByDay[entry.key] = entry.value;
    }
    for (final entry in tempMinutes.entries) {
      minutesByDay[entry.key] = entry.value;
    }
    result.addAll(placedChunks);
    return true;
  }



  _DayCandidate _selectBestCandidate(List<_DayCandidate> candidates, Task task) {
    if (!config.distributeEvenly) return candidates.first;

    // Для высокоприоритетных задач — предпочитаем пиковые часы
    if (task.priority == Priority.high) {
      final peakCandidates = candidates.where((c) => _isPeak(c.slot.start)).toList();
      if (peakCandidates.isNotEmpty) {
        // Среди пиковых — выбираем наименее загруженный день
        peakCandidates.sort((a, b) => a.dayMinutes.compareTo(b.dayMinutes));
        return peakCandidates.first;
      }
    }

    // Для низкого приоритета — предпочитаем вечерние слоты
    if (task.priority == Priority.low) {
      final eveningCandidates = candidates.where((c) => c.slot.start.hour >= 17).toList();
      if (eveningCandidates.isNotEmpty) {
        eveningCandidates.sort((a, b) => a.dayMinutes.compareTo(b.dayMinutes));
        return eveningCandidates.first;
      }
    }

    // Least loaded day; prefer earlier day when loads are equal
    final sorted = List<_DayCandidate>.from(candidates);
    sorted.sort((a, b) {
      final loadDiff = a.dayMinutes.compareTo(b.dayMinutes);
      if (loadDiff != 0) return loadDiff;
      return a.day.compareTo(b.day);
    });
    return sorted.first;
  }

  DateTime _dayKey(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  List<Task> _sortTasks(
    List<Task> tasks, {
    bool priorityFirst = false,
    bool shortFirst = false,
    bool byDeadline = false,
  }) {
    final sorted = List<Task>.from(tasks);
    sorted.sort((a, b) {
      // По дедлайну первым делом
      if (byDeadline) {
        final d = a.deadline.compareTo(b.deadline);
        if (d != 0) return d;
      }

      // Короткие задачи первыми
      if (shortFirst) {
        final d = a.estimatedMinutes.compareTo(b.estimatedMinutes);
        if (d != 0) return d;
      }

      // Приоритет
      if (priorityFirst) {
        final d = a.priority.index.compareTo(b.priority.index); // high=0, low=2
        if (d != 0) return d;
      }

      // Дефолт: сначала дедлайн, потом приоритет
      final deadlineD = a.deadline.compareTo(b.deadline);
      if (deadlineD != 0) return deadlineD;
      return a.priority.index.compareTo(b.priority.index);
    });
    return sorted;
  }

  /// Делим задачу на части по maxFocusMinutes.
  /// ВАЖНО: части идут на РАЗНЫЕ дни — это и есть смысл деления.
  /// Минимальный размер части — 30 минут (иначе не делим).
  List<Task> _splitIntoChunks(Task task) {
    final maxFocus = profile.maxFocusMinutes;

    // Не делим короткие задачи
    if (task.estimatedMinutes <= maxFocus) return [task];

    // Не делим, если оставшийся кусок слишком мал (< 30 мин)
    final remainder = task.estimatedMinutes % maxFocus;
    if (remainder > 0 && remainder < 30) {
      // Добавляем остаток к последнему нормальному куску
      // вместо создания крохотного куска
      final fullChunks = task.estimatedMinutes ~/ maxFocus;
      if (fullChunks == 1) return [task]; // Нет смысла делить

      final chunks = <Task>[];
      for (int i = 0; i < fullChunks - 1; i++) {
        chunks.add(task.copyWith(
          id: i == 0 ? task.id : '${task.id}_part_$i',
          estimatedMinutes: maxFocus,
          title: i == 0 ? task.title : '${task.title} (ч. ${i + 1})',
        ));
      }
      // Последний чанк: maxFocus + remainder
      chunks.add(task.copyWith(
        id: '${task.id}_part_${fullChunks - 1}',
        estimatedMinutes: maxFocus + remainder,
        title: '${task.title} (ч. $fullChunks)',
      ));
      return chunks;
    }

    final chunks = <Task>[];
    var remaining = task.estimatedMinutes;
    var order = 0;

    while (remaining > 0) {
      final dur = remaining > maxFocus ? maxFocus : remaining;
      if (dur < 30) {
        // Добавляем к предыдущему чанку
        if (chunks.isNotEmpty) {
          final last = chunks.last;
          chunks[chunks.length - 1] = last.copyWith(
            estimatedMinutes: last.estimatedMinutes + dur,
          );
        }
        break;
      }
      chunks.add(task.copyWith(
        id: order == 0 ? task.id : '${task.id}_part_$order',
        estimatedMinutes: dur,
        title: order == 0 ? task.title : '${task.title} (ч. ${order + 1})',
      ));
      remaining -= dur;
      order++;
    }
    return chunks;
  }

  /// Генерируем свободные 30-минутные слоты для дня.
  List<TimeSlot> _generateFreeSlots(
    DateTime date,
    List<TimeSlot> occupied, {
    bool fromDayStart = false,
  }) {
    final parts = profile.wakeUpTime.split(':');
    final wakeH = int.tryParse(parts[0]) ?? 8;
    final wakeM = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    DateTime current;
    if (fromDayStart) {
      current = DateTime(date.year, date.month, date.day, wakeH, wakeM);
    } else {
      final wakeUp = DateTime(date.year, date.month, date.day, wakeH, wakeM);
      final now = DateTime.now().add(const Duration(minutes: 15));
      final nowRounded = _roundUpTo30(now);
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;
      current = isToday
          ? (nowRounded.isAfter(wakeUp) ? nowRounded : wakeUp)
          : wakeUp;
    }

    // Конец дня — 22:30
    final endOfDay = DateTime(date.year, date.month, date.day, 22, 30);
    final slots = <TimeSlot>[];

    while (current.isBefore(endOfDay)) {
      final slotEnd = current.add(const Duration(minutes: 30));
      final candidate = TimeSlot(current, slotEnd);
      if (!occupied.any((o) => o.overlaps(candidate))) {
        slots.add(candidate);
      }
      current = current.add(const Duration(minutes: 30));
    }
    return slots;
  }

  DateTime _roundUpTo30(DateTime dt) {
    final minute = dt.minute;
    if (minute == 0) return dt.copyWith(second: 0, millisecond: 0, microsecond: 0);
    final roundedMinute = ((minute / 30).ceil()) * 30;
    if (roundedMinute >= 60) {
      return DateTime(dt.year, dt.month, dt.day, dt.hour + 1, 0);
    }
    return DateTime(dt.year, dt.month, dt.day, dt.hour, roundedMinute);
  }

  /// Находим лучший слот для задачи из доступных.
  TimeSlot? _findBestSlot(Task task, List<TimeSlot> freeSlots) {
    final needed = task.estimatedMinutes;
    final slotsNeeded = (needed / 30).ceil();
    final candidates = <TimeSlot>[];

    // Ищем последовательные слоты
    for (var i = 0; i <= freeSlots.length - slotsNeeded; i++) {
      bool consecutive = true;
      for (var j = 0; j < slotsNeeded - 1; j++) {
        if (!freeSlots[i + j].end.isAtSameMomentAs(freeSlots[i + j + 1].start)) {
          consecutive = false;
          break;
        }
      }
      if (consecutive) {
        candidates.add(TimeSlot(
          freeSlots[i].start,
          freeSlots[i + slotsNeeded - 1].end,
        ));
      }
    }

    if (candidates.isEmpty) return null;

    final isHigh = task.priority == Priority.high;
    final isMedium = task.priority == Priority.medium;
    final isLong = task.estimatedMinutes >= 60;
    final isLow = task.priority == Priority.low;

    // Высокий приоритет + длинная задача → пиковые часы
    if (isHigh && isLong) {
      final peak = candidates.where((s) => _isPeak(s.start)).toList();
      if (peak.isNotEmpty) return peak.first;
    }

    // Средний приоритет → тоже пиковые, если длинная
    if (isMedium && isLong) {
      final peak = candidates.where((s) => _isPeak(s.start)).toList();
      if (peak.isNotEmpty) return peak.first;
    }

    // Низкий приоритет → вечер, не-пиковое время
    if (isLow) {
      final eve = candidates.where((s) => s.start.hour >= 17).toList();
      if (eve.isNotEmpty) return eve.first;
      final nonPeak = candidates.where((s) => !_isPeak(s.start)).toList();
      if (nonPeak.isNotEmpty) return nonPeak.first;
    }

    return candidates.first;
  }

  bool _isPeak(DateTime dt) {
    final h = dt.hour;
    switch (profile.peakHours) {
      case ProductivityPeak.morning: return h >= 8 && h < 12;
      case ProductivityPeak.day: return h >= 12 && h < 17;
      case ProductivityPeak.evening: return h >= 17 && h < 22;
    }
  }
}

class _DayCandidate {
  final int day;
  final DateTime targetDay;
  final TimeSlot slot;
  final int dayMinutes;

  _DayCandidate({
    required this.day,
    required this.targetDay,
    required this.slot,
    required this.dayMinutes,
  });
}