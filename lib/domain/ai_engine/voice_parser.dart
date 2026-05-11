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

class VoiceCommand {
  final TimeFilter? timeFilter;
  final DurationFilter? durationFilter;
  final Priority? priorityFilter;
  final String scope;
  final String action;

  VoiceCommand({
    this.timeFilter,
    this.durationFilter,
    this.priorityFilter,
    this.scope = 'all',
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
      scope: _extractScope(lower),
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
    if (text.contains('high') || text.contains('important') ||
        text.contains('urgent') || text.contains('высок') ||
        text.contains('важн') || text.contains('срочн')) {
      return Priority.high;
    }
    if (text.contains('low') || text.contains('низк') ||
        text.contains('необязательн')) {
      return Priority.low;
    }
    if (text.contains('medium') || text.contains('средн')) {
      return Priority.medium;
    }
    return null;
  }

  String _extractScope(String text) {
    if (text.contains('all') || text.contains('every') ||
        text.contains('все') || text.contains('всех')) return 'all';
    return 'all';
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
      return timeOk && durationOk && priorityOk;
    }).toList();
  }

  String generateExplanation(VoiceCommand command) {
    final parts = <String>[];

    if (command.timeFilter != null) {
      if (command.timeFilter!.beforeHour == 12) parts.add('morning slots');
      else if (command.timeFilter!.afterHour == 17) parts.add('evening slots');
      else if (command.timeFilter!.afterHour == 22) parts.add('night slots');
      else if (command.timeFilter!.between != null) parts.add('afternoon slots');
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

    if (command.priorityFilter != null) {
      switch (command.priorityFilter!) {
        case Priority.high: parts.add('high priority'); break;
        case Priority.medium: parts.add('medium priority'); break;
        case Priority.low: parts.add('low priority'); break;
      }
    }

    if (parts.isEmpty) return 'Showing all tasks';
    return 'Filtered: ${parts.join(', ')}';
  }
}
