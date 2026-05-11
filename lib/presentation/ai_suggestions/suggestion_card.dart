import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/scheduled_task.dart';
import '../../data/models/task.dart';

class SuggestionCard extends StatelessWidget {
  final List<ScheduledTask> suggestions;
  final VoidCallback onAccept;
  final VoidCallback onEdit;

  const SuggestionCard({
    super.key,
    required this.suggestions,
    required this.onAccept,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final morningTasks = suggestions.where((s) => s.startTime.hour < 12).toList();
    final dayTasks = suggestions.where((s) => s.startTime.hour >= 12 && s.startTime.hour < 17).toList();
    final eveningTasks = suggestions.where((s) => s.startTime.hour >= 17).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.15),
            AppTheme.accent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.3),
                    AppTheme.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primaryLight,
                      size: 24,
                    ),
                  ).animate().scale(delay: 100.ms).then().shimmer(duration: 1500.ms),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.aiSuggestion,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'AI distributed ${suggestions.length} tasks',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppTheme.accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _generateExplanation(suggestions),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (morningTasks.isNotEmpty)
                    _TimeBlock(
                      label: AppStrings.morning,
                      timeRange: AppStrings.morningTime,
                      icon: Icons.wb_sunny_outlined,
                      color: AppTheme.mediumPriority,
                      tasks: morningTasks,
                      delay: 200,
                    ),
                  if (dayTasks.isNotEmpty)
                    _TimeBlock(
                      label: AppStrings.day,
                      timeRange: AppStrings.dayTime,
                      icon: Icons.light_mode_outlined,
                      color: AppTheme.primaryLight,
                      tasks: dayTasks,
                      delay: 400,
                    ),
                  if (eveningTasks.isNotEmpty)
                    _TimeBlock(
                      label: AppStrings.evening,
                      timeRange: AppStrings.eveningTime,
                      icon: Icons.nights_stay_outlined,
                      color: AppTheme.accent,
                      tasks: eveningTasks,
                      delay: 600,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text(AppStrings.accept, style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text(AppStrings.edit, style: TextStyle(fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.surfaceLight, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3);
  }

  String _generateExplanation(List<ScheduledTask> suggestions) {
    final hasLongTasks = suggestions.any((s) => s.task.estimatedMinutes > 90);
    final hasSplitTasks = suggestions.any((s) => s.task.title.contains('part'));

    if (hasSplitTasks) return AppStrings.aiExplanationSplit;
    if (hasLongTasks) return AppStrings.aiExplanationPeak;
    return AppStrings.aiExplanationDefault;
  }
}

class _TimeBlock extends StatelessWidget {
  final String label;
  final String timeRange;
  final IconData icon;
  final Color color;
  final List<ScheduledTask> tasks;
  final int delay;

  const _TimeBlock({
    required this.label,
    required this.timeRange,
    required this.icon,
    required this.color,
    required this.tasks,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                timeRange,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tasks.map((scheduled) => _TaskMiniCard(
            task: scheduled.task,
            startTime: scheduled.startTime,
          )),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2);
  }
}

class _TaskMiniCard extends StatelessWidget {
  final Task task;
  final DateTime startTime;

  const _TaskMiniCard({required this.task, required this.startTime});

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    switch (task.priority) {
      case Priority.high:
        priorityColor = AppTheme.highPriority;
        break;
      case Priority.medium:
        priorityColor = AppTheme.mediumPriority;
        break;
      case Priority.low:
        priorityColor = AppTheme.lowPriority;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${AppDateUtils.formatTime(startTime)} – ${AppDateUtils.formatTime(startTime.add(Duration(minutes: task.estimatedMinutes)))}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              AppDateUtils.formatDuration(task.estimatedMinutes),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: priorityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
