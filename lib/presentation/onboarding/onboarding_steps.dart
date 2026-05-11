import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/user_profile.dart';
import '../../providers/onboarding_provider.dart';

class WakeUpStep extends ConsumerWidget {
  const WakeUpStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final form = state.formData;
    final notifier = ref.read(onboardingProvider.notifier);

    return _StepContainer(
      title: AppStrings.questionWakeUp,
      subtitle: 'This helps AI plan your day',
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Text(
              (form['wakeUpTime'] ?? '08:00') as String,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: AppTheme.primaryLight,
                letterSpacing: 4,
              ),
            ),
          ).animate().scale(delay: 200.ms),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.surfaceLight,
              thumbColor: AppTheme.primaryLight,
              overlayColor: AppTheme.primary.withOpacity(0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: _timeToDouble((form['wakeUpTime'] ?? '08:00') as String),
              min: 5,
              max: 11,
              divisions: 12,
              onChanged: (value) {
                notifier.updateForm('wakeUpTime', _doubleToTime(value));
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: ['06:00', '07:00', '08:00', '09:00', '10:00'].map((time) {
              final isSelected = (form['wakeUpTime'] ?? '08:00') == time;
              return ChoiceChip(
                label: Text(time, style: TextStyle(fontSize: 13)),
                selected: isSelected,
                onSelected: (_) => notifier.updateForm('wakeUpTime', time),
                selectedColor: AppTheme.primary,
                backgroundColor: AppTheme.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  double _timeToDouble(String time) {
    final parts = time.split(':');
    return double.parse(parts[0]) + double.parse(parts[1]) / 60;
  }

  String _doubleToTime(double value) {
    final hours = value.floor();
    final minutes = ((value - hours) * 60).round();
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

class PeakHoursStep extends ConsumerWidget {
  const PeakHoursStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final form = state.formData;
    final notifier = ref.read(onboardingProvider.notifier);
    final selected = (form['peakHours'] ?? ProductivityPeak.morning) as ProductivityPeak;

    return _StepContainer(
      title: AppStrings.questionPeakHours,
      subtitle: 'When do you feel most productive?',
      child: Column(
        children: [
          const SizedBox(height: 24),
          _PeakCard(
            peak: ProductivityPeak.morning,
            title: AppStrings.morning,
            subtitle: AppStrings.morningTime,
            icon: Icons.wb_sunny_outlined,
            isSelected: selected == ProductivityPeak.morning,
            onTap: () => notifier.updateForm('peakHours', ProductivityPeak.morning),
          ),
          const SizedBox(height: 12),
          _PeakCard(
            peak: ProductivityPeak.day,
            title: AppStrings.day,
            subtitle: AppStrings.dayTime,
            icon: Icons.light_mode_outlined,
            isSelected: selected == ProductivityPeak.day,
            onTap: () => notifier.updateForm('peakHours', ProductivityPeak.day),
          ),
          const SizedBox(height: 12),
          _PeakCard(
            peak: ProductivityPeak.evening,
            title: AppStrings.evening,
            subtitle: AppStrings.eveningTime,
            icon: Icons.nights_stay_outlined,
            isSelected: selected == ProductivityPeak.evening,
            onTap: () => notifier.updateForm('peakHours', ProductivityPeak.evening),
          ),
        ],
      ),
    );
  }
}

class _PeakCard extends StatelessWidget {
  final ProductivityPeak peak;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeakCard({
    required this.peak,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.15) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceLight.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.2)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppTheme.textSecondary : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (peak.index * 200).ms).slideX(begin: 0.2);
  }
}

class MaxFocusStep extends ConsumerWidget {
  const MaxFocusStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final form = state.formData;
    final notifier = ref.read(onboardingProvider.notifier);
    final value = (form['maxFocusMinutes'] ?? 90) as int;

    return _StepContainer(
      title: AppStrings.questionMaxFocus,
      subtitle: 'How many minutes can you focus without a break?',
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: AppTheme.glowGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w200,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const Text(
                    'minutes',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().scale(delay: 200.ms, duration: 600.ms),
          const SizedBox(height: 32),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.surfaceLight,
              thumbColor: AppTheme.primaryLight,
              overlayColor: AppTheme.primary.withOpacity(0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 30,
              max: 180,
              divisions: 5,
              label: '$value min',
              onChanged: (val) {
                notifier.updateForm('maxFocusMinutes', val.round());
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [30, 45, 60, 90, 120, 180].map((min) {
              final isSelected = value == min;
              return ChoiceChip(
                label: Text('$min min', style: TextStyle(fontSize: 13)),
                selected: isSelected,
                onSelected: (_) => notifier.updateForm('maxFocusMinutes', min),
                selectedColor: AppTheme.primary,
                backgroundColor: AppTheme.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class CommonTasksStep extends ConsumerWidget {
  const CommonTasksStep({super.key});

  final List<Map<String, dynamic>> taskOptions = const [
    {'label': 'Essays', 'icon': Icons.article_outlined},
    {'label': 'Labs', 'icon': Icons.science_outlined},
    {'label': 'Exams', 'icon': Icons.school_outlined},
    {'label': 'Presentations', 'icon': Icons.present_to_all_outlined},
    {'label': 'Reading', 'icon': Icons.menu_book_outlined},
    {'label': 'Homework', 'icon': Icons.home_work_outlined},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final form = state.formData;
    final notifier = ref.read(onboardingProvider.notifier);
    final selected = List<String>.from((form['commonTasks'] ?? <String>[]) as List);

    return _StepContainer(
      title: AppStrings.questionCommonTasks,
      subtitle: 'Select task types you work with most often',
      child: Column(
        children: [
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: taskOptions.map((option) {
              final isSelected = selected.contains(option['label']);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(option['label'] as String, style: TextStyle(fontSize: 13)),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) {
                  final newList = List<String>.from(selected);
                  if (isSelected) {
                    newList.remove(option['label']);
                  } else {
                    newList.add(option['label'] as String);
                  }
                  notifier.updateForm('commonTasks', newList);
                },
                selectedColor: AppTheme.primary,
                backgroundColor: AppTheme.surface,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (selected.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryLight, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.aiWillEstimate,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
        ],
      ),
    );
  }
}

class ProblemsStep extends ConsumerWidget {
  const ProblemsStep({super.key});

  final List<Map<String, String>> problemOptions = const [
    {'label': 'Procrastination', 'desc': 'I postpone important tasks'},
    {'label': 'Overload', 'desc': 'Too many tasks at once'},
    {'label': 'No rhythm', 'desc': 'Inconsistent schedule'},
    {'label': 'Deadlines', 'desc': 'Often miss deadlines'},
    {'label': 'Breaks', 'desc': 'Forget to take breaks'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final form = state.formData;
    final notifier = ref.read(onboardingProvider.notifier);
    final selected = (form['timeManagementIssue'] ?? '') as String;

    return _StepContainer(
      title: AppStrings.questionProblems,
      subtitle: 'Which time management problem bothers you the most?',
      child: Column(
        children: [
          const SizedBox(height: 20),
          ...problemOptions.map((option) {
            final isSelected = selected == option['label'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => notifier.updateForm('timeManagementIssue', option['label']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withOpacity(0.15) : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.surfaceLight.withOpacity(0.5),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 12)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option['label']!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              option['desc']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? AppTheme.textSecondary : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StepContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepContainer({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontSize: 24,
            ),
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          child,
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
