import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/task.dart';
import '../../providers/task_provider.dart';

class TimelineView extends StatelessWidget {
  final List<Task> tasks;
  const TimelineView({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const _EmptyTimeline();

    final sorted = List<Task>.from(tasks)
      ..sort((a, b) => (a.scheduledStart ?? DateTime(0))
          .compareTo(b.scheduledStart ?? DateTime(0)));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: sorted.asMap().entries.map((e) {
          return _TimelineItem(
              task: e.value,
              isLast: e.key == sorted.length - 1,
              index: e.key);
        }).toList(),
      ),
    );
  }
}

class _TimelineItem extends ConsumerWidget {
  final Task task;
  final bool isLast;
  final int index;
  const _TimelineItem(
      {required this.task, required this.isLast, required this.index});

  Color _color(Priority p) {
    switch (p) {
      case Priority.high: return AppTheme.highPriority;
      case Priority.medium: return AppTheme.mediumPriority;
      case Priority.low: return AppTheme.lowPriority;
    }
  }

  String _label(Priority p) {
    switch (p) {
      case Priority.high: return AppStrings.priorityHigh;
      case Priority.medium: return AppStrings.priorityMedium;
      case Priority.low: return AppStrings.priorityLow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pc = _color(task.priority);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          child: Column(
            children: [
              const SizedBox(height: 2),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: pc,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: pc.withOpacity(0.4),
                        blurRadius: 5,
                        spreadRadius: 1)
                  ],
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 80, color: AppTheme.surfaceLight),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => _showOptions(context, ref),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: pc.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: pc.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: task.isCompleted
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (task.isCompleted) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.lowPriority.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(AppStrings.done,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.lowPriority,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (task.scheduledStart != null)
                        _Chip(
                          color: AppTheme.primary.withOpacity(0.15),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time,
                                  size: 11, color: AppTheme.primaryLight),
                              const SizedBox(width: 3),
                              Text(
                                '${AppDateUtils.formatTime(task.scheduledStart!)} – '
                                '${AppDateUtils.formatTime(task.scheduledStart!.add(Duration(minutes: task.estimatedMinutes)))}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryLight,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      _Chip(
                        color: AppTheme.surfaceLight.withOpacity(0.5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 11, color: AppTheme.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              AppDateUtils.formatDuration(task.estimatedMinutes),
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      _Chip(
                        color: pc.withOpacity(0.12),
                        child: Text(_label(task.priority),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: pc)),
                      ),
                      _Chip(
                        color: AppTheme.surfaceLight.withOpacity(0.4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flag_outlined,
                                size: 10, color: AppTheme.textMuted),
                            const SizedBox(width: 2),
                            Text(
                              '${task.deadline.day}.${task.deadline.month}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.1),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            Text(task.title,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(
              '${AppDateUtils.formatDuration(task.estimatedMinutes)} · deadline ${task.deadline.day}.${task.deadline.month}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),

            _ActionBtn(
              icon: task.isCompleted ? Icons.refresh : Icons.check_circle,
              label: task.isCompleted ? AppStrings.markUndone : AppStrings.markDone,
              color: AppTheme.lowPriority,
              onTap: () {
                ref.read(taskNotifierProvider.notifier).toggleComplete(task.id);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),

            _ActionBtn(
              icon: Icons.schedule,
              label: AppStrings.changeTime,
              color: AppTheme.primary,
              onTap: () async {
                Navigator.pop(ctx);

                // FIRST pick date
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: task.scheduledStart ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
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

                if (pickedDate != null && context.mounted) {
                  // THEN pick time
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: task.scheduledStart != null
                        ? TimeOfDay.fromDateTime(task.scheduledStart!)
                        : const TimeOfDay(hour: 9, minute: 0),
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

                  if (pickedTime != null && context.mounted) {
                    await ref.read(taskNotifierProvider.notifier).scheduleTask(
                      task.id,
                      DateTime(
                        pickedDate.year, pickedDate.month, pickedDate.day,
                        pickedTime.hour, pickedTime.minute,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),

            _ActionBtn(
              icon: Icons.timer_outlined,
              label: 'Change duration',
              color: AppTheme.accent,
              onTap: () {
                Navigator.pop(ctx);
                _showDurationPicker(context, ref);
              },
            ),
            const SizedBox(height: 8),

            _ActionBtn(
              icon: Icons.delete_outline,
              label: AppStrings.deleteTask,
              color: AppTheme.highPriority,
              onTap: () {
                ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDurationPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change duration',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [30, 45, 60, 90, 120, 150, 180, 240].map((min) {
                final isCurrent = task.estimatedMinutes == min;
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(taskNotifierProvider.notifier)
                        .updateDuration(task.id, min);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppTheme.primary : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? AppTheme.primary
                            : AppTheme.surfaceLight,
                      ),
                    ),
                    child: Text(
                      AppDateUtils.formatDuration(min),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? Colors.white
                              : AppTheme.textSecondary),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final Color color;
  final Widget child;
  const _Chip({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(6)),
      child: child,
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(28),
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceLight.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.calendar_today_outlined,
                size: 36, color: AppTheme.primaryLight),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.noTasks,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text(AppStrings.addTasksOrOptimize,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    ).animate().fadeIn().scale(delay: 200.ms);
  }
}
