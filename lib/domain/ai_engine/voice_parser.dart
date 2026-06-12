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

enum DayScope { today, tomorrow, thisWeek, overdue, unscheduled, completed, specific }

class DayFilter {
  final DayScope scope;
  final DateTime? specificDate;

  DayFilter(this.scope, {this.specificDate});

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
        return s.year == tomorrow.year && s.month == tomorrow.month && s.day == tomorrow.day;

      case DayScope.thisWeek:
        if (task.scheduledStart == null) return false;
        final s = DateTime(task.scheduledStart!.year, task.scheduledStart!.month,
            task.scheduledStart!.day);
        return !s.isBefore(today) && s.isBefore(weekEnd);

      case DayScope.overdue:
        final deadline = DateTime(task.deadline.year, task.deadline.month, task.deadline.day);
        return deadline.isBefore(today) && !task.isCompleted;

      case DayScope.unscheduled:
        return task.scheduledStart == null && !task.isCompleted;

      case DayScope.completed:
        return task.isCompleted;

      case DayScope.specific:
        if (specificDate == null || task.scheduledStart == null) return false;
        final s = task.scheduledStart!;
        return s.year == specificDate!.year &&
            s.month == specificDate!.month &&
            s.day == specificDate!.day;
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
    // Specific minute value: "30 min tasks", "45 minutes", "20 min"
    final minMatch = RegExp(r'\b(\d+)\s*min(?:ute)?s?\b').firstMatch(text);
    if (minMatch != null) {
      final mins = int.parse(minMatch.group(1)!);
      if (mins > 0 && mins <= 480) return DurationFilter(maxMinutes: mins);
    }

    // Specific hour value: "1 hour", "2h", "1.5 hours"
    final hourMatch = RegExp(r'\b(\d+(?:[.,]\d+)?)\s*h(?:our)?s?\b').firstMatch(text);
    if (hourMatch != null) {
      final raw = hourMatch.group(1)!.replaceAll(',', '.');
      final hours = double.tryParse(raw);
      if (hours != null && hours > 0) {
        return DurationFilter(maxMinutes: (hours * 60).round());
      }
    }

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
    // Only use 'medium' as a duration filter when it's NOT describing priority
    final isMediumPriority = text.contains('medium priority') ||
        text.contains('medium prior') ||
        (text.contains('средн') && text.contains('приоритет'));
    if (!isMediumPriority &&
        (text.contains('medium duration') ||
            text.contains('medium length') ||
            text.contains('medium task'))) {
      return DurationFilter(minMinutes: 60, maxMinutes: 120);
    }
    return null;
  }

  Priority? _extractPriority(String text) {
    // Check medium FIRST to prevent "medium priority" from matching high-priority keywords
    final hasMedium = text.contains('medium') || text.contains('средн') ||
        text.contains('normal') || text.contains('regular');
    final hasPriorityWord = text.contains('priority') || text.contains('приоритет') ||
        text.contains('prior');
    final hasHighWord = text.contains('high') || text.contains('important') ||
        text.contains('urgent') || text.contains('critical') ||
        text.contains('top ') || text.contains('most ') ||
        text.contains('высок') || text.contains('важн') ||
        text.contains('срочн');
    final hasLowWord = text.contains('low') || text.contains('низк') ||
        text.contains('least') || text.contains('необязательн');

    // "medium priority" → medium (not high)
    if (hasMedium && hasPriorityWord && !hasHighWord && !hasLowWord) {
      return Priority.medium;
    }

    // High priority
    if (hasHighWord && !hasLowWord) {
      return Priority.high;
    }

    // "most prioritized", "prioritized tasks", "top priority" (without 'medium')
    if (!hasMedium && (text.contains('prioritized') || text.contains('top priority') ||
        text.contains('главн') || text.contains('первоочеред'))) {
      return Priority.high;
    }

    // Low priority
    if (hasLowWord) return Priority.low;

    // Medium priority standalone
    if (hasMedium) return Priority.medium;

    return null;
  }

  DayFilter? _extractDay(String text) {
    // Specific date first (e.g. "14th of June", "June 14", "14 june")
    final specificDate = _parseSpecificDate(text);
    if (specificDate != null) return DayFilter(DayScope.specific, specificDate: specificDate);

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
    if (text.contains('done') || text.contains('completed') ||
        text.contains('finished') || text.contains('выполнен') ||
        text.contains('завершен') || text.contains('сделан')) {
      return DayFilter(DayScope.completed);
    }
    return null;
  }

  /// Parses phrases like "14th of June", "June 14", "14 june", "on the 14th of june"
  DateTime? _parseSpecificDate(String text) {
    const months = {
      'january': 1, 'jan': 1, 'январ': 1,
      'february': 2, 'feb': 2, 'феврал': 2, 'февр': 2,
      'march': 3, 'mar': 3, 'март': 3,
      'april': 4, 'apr': 4, 'апрел': 4,
      'may': 5, 'май': 5,
      'june': 6, 'jun': 6, 'июн': 6,
      'july': 7, 'jul': 7, 'июл': 7,
      'august': 8, 'aug': 8, 'август': 8,
      'september': 9, 'sep': 9, 'сентябр': 9,
      'october': 10, 'oct': 10, 'октябр': 10,
      'november': 11, 'nov': 11, 'ноябр': 11,
      'december': 12, 'dec': 12, 'декабр': 12,
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final entry in months.entries) {
      if (!text.contains(entry.key)) continue;
      final monthNum = entry.value;

      // Find a 1-2 digit number anywhere in the text
      final dayMatches = RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)?\b').allMatches(text);
      for (final m in dayMatches) {
        final day = int.tryParse(m.group(1) ?? '');
        if (day == null || day < 1 || day > 31) continue;
        // Prefer current year; use next year if date is already past
        int year = now.year;
        try {
          final candidate = DateTime(year, monthNum, day);
          if (candidate.isBefore(today)) year++;
          return DateTime(year, monthNum, day);
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  String _extractAction(String text) {
    if (text.contains('move') || text.contains('shift') ||
        text.contains('перенеси') || text.contains('передвинь')) return 'move';
    if (text.contains('complete') || text.contains('finish') ||
        text.contains('выполни') || text.contains('сделано')) return 'complete';
    return 'schedule';
  }

  List<Task> applyFilter(List<Task> tasks, VoiceCommand command) {
    return tasks.where((t) {
      final timeOk = command.timeFilter?.matches(t.scheduledStart) ?? true;
      final durationOk = command.durationFilter?.matches(t.estimatedMinutes) ?? true;
      final priorityOk = command.priorityFilter == null || t.priority == command.priorityFilter;
      final dayOk = command.dayFilter?.matches(t) ?? true;
      return timeOk && durationOk && priorityOk && dayOk;
    }).toList();
  }

  String generateExplanation(VoiceCommand command) {
    final parts = <String>[];

    if (command.dayFilter != null) {
      switch (command.dayFilter!.scope) {
        case DayScope.today:
          parts.add('today');
        case DayScope.tomorrow:
          parts.add('tomorrow');
        case DayScope.thisWeek:
          parts.add('this week');
        case DayScope.overdue:
          parts.add('overdue tasks');
        case DayScope.unscheduled:
          parts.add('unscheduled tasks');
        case DayScope.completed:
          parts.add('completed tasks');
        case DayScope.specific:
          final d = command.dayFilter!.specificDate;
          if (d != null) parts.add('${d.day}.${d.month}');
      }
    }

    if (command.timeFilter != null) {
      if (command.timeFilter!.beforeHour == 12) {
        parts.add('morning');
      } else if (command.timeFilter!.afterHour == 22) {
        parts.add('night');
      } else if (command.timeFilter!.afterHour == 17) {
        parts.add('evening');
      } else if (command.timeFilter!.between != null) {
        parts.add('afternoon');
      }
    }

    if (command.priorityFilter != null) {
      switch (command.priorityFilter!) {
        case Priority.high:
          parts.add('high priority');
        case Priority.medium:
          parts.add('medium priority');
        case Priority.low:
          parts.add('low priority');
      }
    }

    if (command.durationFilter != null) {
      if (command.durationFilter!.minMinutes != null &&
          command.durationFilter!.maxMinutes == null) {
        parts.add('long tasks (≥${command.durationFilter!.minMinutes}min)');
      } else if (command.durationFilter!.maxMinutes != null &&
          command.durationFilter!.minMinutes == null) {
        parts.add('short tasks (≤${command.durationFilter!.maxMinutes}min)');
      } else {
        parts.add('medium tasks');
      }
    }

    if (parts.isEmpty) return 'Showing all tasks';
    return 'Filtered: ${parts.join(', ')}';
  }
}
