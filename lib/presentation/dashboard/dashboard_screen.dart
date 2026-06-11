import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/task.dart';
import '../../data/models/scheduled_task.dart';
import '../../providers/task_provider.dart';
import '../task_input/task_input_screen.dart';
import 'timeline_view.dart';
import 'voice_input_button.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final selectedDayTasks = ref.watch(selectedDayTasksProvider);
    final unscheduled = ref.watch(unscheduledTasksProvider);
    final scheduledDays = ref.watch(scheduledDaysProvider);

    final isToday = AppDateUtils.isSameDay(selectedDay, DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ref, selectedDayTasks.length, unscheduled.length),
            _DaySelector(
              selectedDay: selectedDay,
              scheduledDays: scheduledDays,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              isToday ? 'Today' : AppDateUtils.formatDate(selectedDay),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            AppDateUtils.formatDateShort(selectedDay),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TimelineView(tasks: selectedDayTasks),
                    if (unscheduled.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(AppStrings.unscheduled,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.mediumPriority.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${unscheduled.length}',
                                  style: const TextStyle(
                                      color: AppTheme.mediumPriority,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: unscheduled
                              .map((t) => _UnscheduledTaskCard(task: t))
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VoiceInputButton(),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: () => _showAddTaskSheet(context),
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            label: const Text(AppStrings.addTask,
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, int taskCount, int unscheduledCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: const Text('Chrono',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderButton(
                    label: 'Schedule',
                    icon: Icons.calendar_month,
                    color: AppTheme.accent,
                    onTap: () => _onSchedule(context, ref),
                  ),
                  const SizedBox(width: 6),
                  _HeaderButton(
                    label: 'Optimize',
                    icon: Icons.auto_awesome,
                    color: AppTheme.primary,
                    onTap: () => _onOptimize(context, ref),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniStat(
                label: 'Scheduled',
                value: '$taskCount',
                color: AppTheme.lowPriority,
              ),
              const SizedBox(width: 8),
              _MiniStat(
                label: 'Unscheduled',
                value: '$unscheduledCount',
                color: unscheduledCount > 0 ? AppTheme.mediumPriority : AppTheme.textMuted,
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Future<void> _onSchedule(BuildContext context, WidgetRef ref) async {
    final unscheduled = ref.read(unscheduledTasksProvider);
    if (unscheduled.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('All tasks are already scheduled'),
        backgroundColor: AppTheme.cardBg,
      ));
      return;
    }
    try {
      final suggestions = await ref.read(taskNotifierProvider.notifier).scheduleUnscheduled();
      if (!context.mounted) return;
      if (suggestions.isEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.mediumPriority, size: 20),
              SizedBox(width: 8),
              Text('No free slots', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
            ]),
            content: const Text(
              'Your schedule is packed for the deadline days of these tasks.\n\nTry:\n• Moving a task deadline to a later date\n• Deleting a scheduled task to free up time\n• Editing the task duration',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: AppTheme.primaryLight)),
              ),
            ],
          ),
        );
      } else {
        _showSuggestionsSheet(context, ref, suggestions, title: 'Schedule Plan', allowEdit: true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.highPriority,
        ));
      }
    }
  }

  Future<void> _onOptimize(BuildContext context, WidgetRef ref) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.35,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 14),
                const Row(children: [
                  Icon(Icons.auto_awesome, color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text('Optimize by...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ]),
                const SizedBox(height: 16),
                _OptimizeOption(icon: Icons.flag, title: 'Priority first', subtitle: 'High priority tasks get peak hours', onTap: () async { Navigator.pop(ctx); await _runOptimize(context, ref, priorityFirst: true); }),
                const SizedBox(height: 8),
                _OptimizeOption(icon: Icons.calendar_today, title: 'By deadline', subtitle: 'Tasks closer to deadline go earlier', onTap: () async { Navigator.pop(ctx); await _runOptimize(context, ref, byDeadline: true); }),
                const SizedBox(height: 8),
                _OptimizeOption(icon: Icons.timer, title: 'Short tasks first', subtitle: 'Quick wins early in the day', onTap: () async { Navigator.pop(ctx); await _runOptimize(context, ref, byDuration: true); }),
                const SizedBox(height: 8),
                _OptimizeOption(icon: Icons.auto_awesome, title: 'AI default', subtitle: 'Balance priority, deadline and peak hours', onTap: () async { Navigator.pop(ctx); await _runOptimize(context, ref); }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _runOptimize(BuildContext context, WidgetRef ref, {bool priorityFirst = false, bool byDeadline = false, bool byDuration = false}) async {
    try {
      final suggestions = await ref.read(taskNotifierProvider.notifier).optimizeScheduled(
            priorityFirst: priorityFirst,
            byDeadline: byDeadline,
            byDuration: byDuration,
          );
      if (!context.mounted) return;
      if (suggestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to optimize'), backgroundColor: AppTheme.surface));
      } else {
        _showSuggestionsSheet(context, ref, suggestions, title: 'Optimized Plan', allowEdit: true);
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showSuggestionsSheet(BuildContext context, WidgetRef ref, List<ScheduledTask> suggestions, {required String title, bool allowEdit = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SuggestionsSheet(suggestions: List.from(suggestions), title: title, ref: ref, allowEdit: allowEdit),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const TaskInputScreen());
  }
}

// --- Internal Classes ---

class _HeaderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HeaderButton({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ]),
    );
  }
}

class _DaySelector extends ConsumerWidget {
  final DateTime selectedDay;
  final List<DateTime> scheduledDays;
  const _DaySelector({required this.selectedDay, required this.scheduledDays});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final days = <DateTime>{};
    days.add(DateTime(today.year, today.month, today.day));
    for (var i = 1; i <= 14; i++) { 
      days.add(DateTime(today.year, today.month, today.day).add(Duration(days: i))); 
    }
    for (final d in scheduledDays) { 
      days.add(DateTime(d.year, d.month, d.day)); 
    }
    final sorted = days.toList()..sort();

    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sorted.length,
        itemBuilder: (_, i) {
          final day = sorted[i];
          final isSelected = AppDateUtils.isSameDay(day, selectedDay);
          final isToday = AppDateUtils.isSameDay(day, today);
          final hasTasks = scheduledDays.any((d) => AppDateUtils.isSameDay(d, day));

          return GestureDetector(
            onTap: () => ref.read(selectedDayProvider.notifier).state = day,
            child: Container(
              width: 52,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : hasTasks ? AppTheme.primaryLight.withOpacity(0.4) : AppTheme.surfaceLight.withOpacity(0.5),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'Today' : _weekday(day.weekday), 
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white70 : AppTheme.textMuted,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}', 
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _monthShort(day.month),
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected ? Colors.white60 : AppTheme.textMuted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _weekday(int w) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][(w - 1) % 7];
  String _monthShort(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}

class _OptimizeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _OptimizeOption({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceLight.withOpacity(0.5))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppTheme.primaryLight, size: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _UnscheduledTaskCard extends ConsumerWidget {
  final Task task;
  const _UnscheduledTaskCard({required this.task});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = task.priority == Priority.high ? AppTheme.highPriority : task.priority == Priority.medium ? AppTheme.mediumPriority : AppTheme.lowPriority;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceLight.withOpacity(0.5))),
      child: Row(
        children: [
          Container(width: 3, height: 32, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Text(AppDateUtils.formatDuration(task.estimatedMinutes), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    const SizedBox(width: 6),
                    Text(task.priority.name, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.read(taskNotifierProvider.notifier).deleteTask(task.id),
            icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsSheet extends StatefulWidget {
  final List<ScheduledTask> suggestions;
  final String title;
  final WidgetRef ref;
  final bool allowEdit;
  const _SuggestionsSheet({required this.suggestions, required this.title, required this.ref, this.allowEdit = false});
  @override State<_SuggestionsSheet> createState() => _SuggestionsSheetState();
}

class _SuggestionsSheetState extends State<_SuggestionsSheet> {
  late List<ScheduledTask> _suggestions;
  @override void initState() { super.initState(); _suggestions = List.from(widget.suggestions); }

  void _editSuggestion(int index) async {
    final suggestion = _suggestions[index];

    // Pick new date
    final newDate = await showDatePicker(
      context: context,
      initialDate: suggestion.startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.surface,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );

    if (newDate == null || !mounted) return;

    // Pick new time
    final newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(suggestion.startTime),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.surface,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );

    if (newTime != null && mounted) {
      setState(() {
        _suggestions[index] = ScheduledTask(
          task: suggestion.task,
          startTime: DateTime(
            newDate.year, newDate.month, newDate.day,
            newTime.hour, newTime.minute,
          ),
        );
      });
    }
  }

  @override Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.primaryLight, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        await widget.ref.read(taskNotifierProvider.notifier).applySuggestions(_suggestions);
                        if (mounted) nav.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lowPriority,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Accept All & Apply', style: TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _suggestions.length,
                itemBuilder: (_, i) {
                  final s = _suggestions[i];
                  final isMultiDay = s.task.title.contains('part');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isMultiDay ? AppTheme.accent.withOpacity(0.5) : AppTheme.surfaceLight.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 14,
                                  color: isMultiDay ? AppTheme.accent : AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMultiDay)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Part', style: TextStyle(fontSize: 9, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                              ),
                            if (widget.allowEdit)
                              IconButton(
                                onPressed: () => _editSuggestion(i),
                                icon: const Icon(Icons.edit, size: 16, color: AppTheme.primaryLight),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppDateUtils.formatTime(s.startTime)} - ${AppDateUtils.formatTime(s.endTime)} · ${AppDateUtils.getRelativeDay(s.startTime)}',
                          style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${AppDateUtils.formatDuration(s.task.estimatedMinutes)} · ${s.task.priority.name} priority',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
