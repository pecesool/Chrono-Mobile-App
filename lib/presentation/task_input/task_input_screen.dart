import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/task.dart';
import '../../domain/ai_engine/scheduler.dart';
import '../../providers/task_provider.dart';

final taskTitleProvider = StateProvider<String>((ref) => '');
final taskPriorityProvider = StateProvider<Priority>((ref) => Priority.medium);
final taskDeadlineProvider = StateProvider<DateTime>((ref) => DateTime.now().add(const Duration(days: 1)));
final autoEstimateProvider = StateProvider<int>((ref) => 60);

class TaskInputScreen extends ConsumerWidget {
  const TaskInputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(taskTitleProvider);
    final priority = ref.watch(taskPriorityProvider);
    final deadline = ref.watch(taskDeadlineProvider);
    final autoEstimate = ref.watch(autoEstimateProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  AppStrings.addTask,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 20),

                TextField(
                  onChanged: (value) {
                    ref.read(taskTitleProvider.notifier).state = value;
                    final estimate = AIScheduler.estimateTime(value);
                    ref.read(autoEstimateProvider.notifier).state = estimate;
                  },
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: AppStrings.taskTitle,
                    prefixIcon: const Icon(Icons.edit_note, color: AppTheme.primary, size: 22),
                  ),
                ),

                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  AppStrings.aiEstimate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accent,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${autoEstimate ~/ 60}h ${autoEstimate % 60}min',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showEstimatePicker(context, ref, autoEstimate),
                            child: const Text(
                              AppStrings.change,
                              style: TextStyle(color: AppTheme.accent, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: -0.2),

                const SizedBox(height: 16),

                Text(
                  AppStrings.priority,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _PriorityChip(
                      label: AppStrings.high,
                      priority: Priority.high,
                      isSelected: priority == Priority.high,
                      onTap: () => ref.read(taskPriorityProvider.notifier).state = Priority.high,
                    ),
                    const SizedBox(width: 10),
                    _PriorityChip(
                      label: AppStrings.medium,
                      priority: Priority.medium,
                      isSelected: priority == Priority.medium,
                      onTap: () => ref.read(taskPriorityProvider.notifier).state = Priority.medium,
                    ),
                    const SizedBox(width: 10),
                    _PriorityChip(
                      label: AppStrings.low,
                      priority: Priority.low,
                      isSelected: priority == Priority.low,
                      onTap: () => ref.read(taskPriorityProvider.notifier).state = Priority.low,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  AppStrings.deadline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showDatePicker(context, ref, deadline),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.surfaceLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppTheme.primaryLight, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          '${deadline.day}.${deadline.month}.${deadline.year}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: title.isEmpty ? null : () async {
                      final task = Task(
                        title: title,
                        priority: priority,
                        deadline: deadline,
                        estimatedMinutes: autoEstimate,
                      );
                      await ref.read(taskNotifierProvider.notifier).addTask(task);

                      // Reset providers
                      ref.read(taskTitleProvider.notifier).state = '';
                      ref.read(taskPriorityProvider.notifier).state = Priority.medium;
                      ref.read(autoEstimateProvider.notifier).state = 60;

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(AppStrings.taskAdded),
                            backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    child: const Text(AppStrings.addTaskButton),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEstimatePicker(BuildContext context, WidgetRef ref, int current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.timeEstimateTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [30, 45, 60, 90, 120, 180, 240].map((minutes) {
                final isSelected = current == minutes;
                return ChoiceChip(
                  label: Text(
                    '${minutes ~/ 60 > 0 ? '${minutes ~/ 60}h ' : ''}${minutes % 60 > 0 ? '${minutes % 60}min' : ''}',
                    style: TextStyle(fontSize: 13),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(autoEstimateProvider.notifier).state = minutes;
                    Navigator.pop(context);
                  },
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.cardBg,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context, WidgetRef ref, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(taskDeadlineProvider.notifier).state = picked;
    }
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final Priority priority;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.priority,
    required this.isSelected,
    required this.onTap,
  });

  Color get _color {
    switch (priority) {
      case Priority.high: return AppTheme.highPriority;
      case Priority.medium: return AppTheme.mediumPriority;
      case Priority.low: return AppTheme.lowPriority;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _color.withOpacity(0.2) : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _color : AppTheme.surfaceLight.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.flag,
                color: isSelected ? _color : AppTheme.textMuted,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
