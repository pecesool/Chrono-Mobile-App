import '../../data/models/task.dart';

class TimeFilter {
  final int? beforeHour;
  final int? afterHour;
  final (int, int)? between;

  TimeFilter({this.beforeHour, this.afterHour, this.between});

  bool matches(DateTime? scheduledTime) {
    if (scheduledTime == null) return true;
    final hour = scheduledTime.hour;
    if (beforeHour != null) return hour < beforeHour!;
    if (afterHour != null) return hour >= afterHour!;
    if (between != null) return hour >= between!.$1 && hour < between!.$2;
    return true;
  }
}

class DurationFilter {
  final int? minMinutes;
  final int? maxMinutes;

  DurationFilter({this.minMinutes, this.maxMinutes});

  bool matches(int minutes) {
    if (minMinutes != null && minutes < minMinutes!) return false;
    if (maxMinutes != null && minutes > maxMinutes!) return false;
    return true;
  }
}

enum DayScope { today, tomorrow, thisWeek, overdue, unscheduled }

class DayFilter {
  final DayScope scope;

  DayFilter(this.scope);

  bool matches(Task task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    switch (scope) {
      case DayScope.today:
        if (task.scheduledStart == null) return false;
        final s = task.scheduledStart!;
        return s.year == today.year && s.month == today.month && s.day == today.day;

      case DayScope.tomorrow:
        if (task.scheduledStart == null) return false;
        final s = task.scheduledStart!;
        return s.year == tomorrow.year &&
            s.month == tomorrow.month &&
            s.day == tomorrow.day;

      case DayScope.thisWeek:
        if (task.scheduledStart == null) return false;
        final s = DateTime(task.scheduledStart!.year, task.scheduledStart!.month,
            task.scheduledStart!.day);
        return !s.isBefore(today) && s.isBefore(weekEnd);

      case DayScope.overdue:
        final deadline = DateTime(
            task.deadline.year, task.deadline.month, task.deadline.day);
        return deadline.isBefore(today) && !task.isCompleted;

      case DayScope.unscheduled:
        return task.scheduledStart == null && !task.isCompleted;
    }
  }
}

class VoiceCommand {
  final TimeFilter? timeFilter;
  final DurationFilter? durationFilter;
  final Priority? priorityFilter;
  final DayFilter? dayFilter;
  final String action;

  VoiceCommand({
    this.timeFilter,
    this.durationFilter,
    this.priorityFilter,
    this.dayFilter,
    this.action = 'schedule',
  });
}

class VoiceIntentParser {
  VoiceCommand parse(String text) {
    final lower = text.toLowerCase();
    return VoiceCommand(
      timeFilter: _extractTime(lower),
      durationFilter: _extractDuration(lower),
      priorityFilter: _extractPriority(lower),
      dayFilter: _extractDay(lower),
      action: _extractAction(lower),
    );
  }

  TimeFilter? _extractTime(String text) {
    if (text.contains('morning') || text.contains('утром') ||
        text.contains('утр') || text.contains('am')) {
      return TimeFilter(beforeHour: 12);
    }
    if (text.contains('afternoon') || text.contains('noon') ||
        text.contains('днем') || text.contains('день')) {
      return TimeFilter(between: (12, 17));
    }
    if (text.contains('evening') || text.contains('вечер') ||
        text.contains('вечером') || text.contains('pm')) {
      return TimeFilter(afterHour: 17);
    }
    if (text.contains('night') || text.contains('ночью') ||
        text.contains('ночь')) {
      return TimeFilter(afterHour: 22);
    }
    return null;
  }

  DurationFilter? _extractDuration(String text) {
    if (text.contains('long') || text.contains('big') ||
        text.contains('lengthy') || text.contains('длинн') ||
        text.contains('долг') || text.contains('большие')) {
      return DurationFilter(minMinutes: 90);
    }
    if (text.contains('quick') || text.contains('short') ||
        text.contains('small') || text.contains('коротк') ||
        text.contains('быстр') || text.contains('маленьк')) {
      return DurationFilter(maxMinutes: 60);
    }
    if (text.contains('medium') || text.contains('средн')) {
      return DurationFilter(minMinutes: 60, maxMinutes: 120);
    }
    return null;
  }

  Priority? _extractPriority(String text) {
    // High priority — many natural ways to say it
    if (text.contains('high') || text.contains('important') ||
        text.contains('urgent') || text.contains('critical') ||
        text.contains('top') || text.contains('most') ||
        text.contains('priorit') || // covers "priority", "prioritized", "prioritized"
        text.contains('высок') || text.contains('важн') ||
        text.contains('срочн') || text.contains('главн') ||
        text.contains('первоочеред')) {
      // If they said "low" alongside "most", skip to low check below
      if (!text.contains('low') && !text.contains('низк')) {
        return Priority.high;
      }
    }
    if (text.contains('low') || text.contains('низк') ||
        text.contains('необязательн') || text.contains('unimportant') ||
        text.contains('least')) {
      return Priority.low;
    }
    if (text.contains('medium') || text.contains('средн') ||
        text.contains('normal') || text.contains('regular')) {
      return Priority.medium;
    }
    return null;
  }

  DayFilter? _extractDay(String text) {
    if (text.contains('tomorrow') || text.contains('завтра')) {
      return DayFilter(DayScope.tomorrow);
    }
    if (text.contains('today') || text.contains('сегодня') ||
        text.contains('this day')) {
      return DayFilter(DayScope.today);
    }
    if (text.contains('this week') || text.contains('week') ||
        text.contains('эту неделю') || text.contains('недел')) {
      return DayFilter(DayScope.thisWeek);
    }
    if (text.contains('overdue') || text.contains('late') ||
        text.contains('missed') || text.contains('просрочен') ||
        text.contains('опоздал')) {
      return DayFilter(DayScope.overdue);
    }
    if (text.contains('unscheduled') || text.contains('not scheduled') ||
        text.contains('without time') || text.contains('незапланиров') ||
        text.contains('без времени')) {
      return DayFilter(DayScope.unscheduled);
    }
    return null;
  }

  String _extractAction(String text) {
    if (text.contains('move') || text.contains('shift') ||
        text.contains('перенеси') || text.contains('передвинь')) return 'move';
    if (text.contains('complete') || text.contains('finish') ||
        text.contains('done') || text.contains('выполни') ||
        text.contains('сделано')) return 'complete';
    return 'schedule';
  }

  List<Task> applyFilter(List<Task> tasks, VoiceCommand command) {
    return tasks.where((t) {
      final timeOk = command.timeFilter?.matches(t.scheduledStart) ?? true;
      final durationOk =
          command.durationFilter?.matches(t.estimatedMinutes) ?? true;
      final priorityOk = command.priorityFilter == null ||
          t.priority == command.priorityFilter;
      final dayOk = command.dayFilter?.matches(t) ?? true;
      return timeOk && durationOk && priorityOk && dayOk;
    }).toList();
  }

  String generateExplanation(VoiceCommand command) {
    final parts = <String>[];

    if (command.dayFilter != null) {
      switch (command.dayFilter!.scope) {
        case DayScope.today: parts.add('today'); break;
        case DayScope.tomorrow: parts.add('tomorrow'); break;
        case DayScope.thisWeek: parts.add('this week'); break;
        case DayScope.overdue: parts.add('overdue tasks'); break;
        case DayScope.unscheduled: parts.add('unscheduled tasks'); break;
      }
    }

    if (command.timeFilter != null) {
      if (command.timeFilter!.beforeHour == 12) parts.add('morning');
      else if (command.timeFilter!.afterHour == 22) parts.add('night');
      else if (command.timeFilter!.afterHour == 17) parts.add('evening');
      else if (command.timeFilter!.between != null) parts.add('afternoon');
    }

    if (command.priorityFilter != null) {
      switch (command.priorityFilter!) {
        case Priority.high: parts.add('high priority'); break;
        case Priority.medium: parts.add('medium priority'); break;
        case Priority.low: parts.add('low priority'); break;
      }
    }

    if (command.durationFilter != null) {
      if (command.durationFilter!.minMinutes != null &&
          command.durationFilter!.maxMinutes == null)
        parts.add('long tasks (≥${command.durationFilter!.minMinutes}min)');
      else if (command.durationFilter!.maxMinutes != null &&
          command.durationFilter!.minMinutes == null)
        parts.add('short tasks (≤${command.durationFilter!.maxMinutes}min)');
      else
        parts.add('medium tasks');
    }

    if (parts.isEmpty) return 'Showing all tasks';
    return 'Filtered: ${parts.join(', ')}';
  }
}
