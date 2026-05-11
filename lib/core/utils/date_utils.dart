import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatDate(DateTime date) {
    return DateFormat('d MMMM', 'en').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd.MM').format(date);
  }

  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}min';
    if (hours > 0) return '${hours}h';
    return '${mins}min';
  }

  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0);
  }

  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static List<DateTime> getTimeSlots(DateTime date, int intervalMinutes) {
    final slots = <DateTime>[];
    var current = DateTime(date.year, date.month, date.day, 8, 0);
    final end = DateTime(date.year, date.month, date.day, 23, 0);

    while (current.isBefore(end)) {
      slots.add(current);
      current = current.add(Duration(minutes: intervalMinutes));
    }
    return slots;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String getRelativeDay(DateTime date) {
    final now = DateTime.now();
    if (isSameDay(date, now)) return 'Today';
    if (isSameDay(date, now.add(const Duration(days: 1)))) return 'Tomorrow';
    if (isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return formatDate(date);
  }
}
