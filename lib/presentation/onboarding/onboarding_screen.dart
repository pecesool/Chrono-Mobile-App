import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_steps.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final currentStep = state.currentStep;
    const totalSteps = 6;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            if (currentStep > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: List.generate(
                    5,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index < currentStep
                              ? AppTheme.primary
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.3, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildStep(currentStep, key: ValueKey(currentStep)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (currentStep > 0)
                    Flexible(
                      child: TextButton.icon(
                        onPressed: () => ref.read(onboardingProvider.notifier).prevStep(),
                        icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary, size: 18),
                        label: const Text(AppStrings.back, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ),
                    )
                  else
                    const SizedBox(width: 80),
                  const Spacer(),
                  _buildNextButton(context, ref, currentStep, totalSteps),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step, {Key? key}) {
    switch (step) {
      case 0: return _IntroStep(key: key);
      case 1: return WakeUpStep(key: key);
      case 2: return PeakHoursStep(key: key);
      case 3: return MaxFocusStep(key: key);
      case 4: return CommonTasksStep(key: key);
      case 5: return ProblemsStep(key: key);
      default: return _IntroStep(key: key);
    }
  }

  Widget _buildNextButton(BuildContext context, WidgetRef ref, int currentStep, int totalSteps) {
    final isLastStep = currentStep == totalSteps - 1;
    final notifier = ref.read(onboardingProvider.notifier);

    return GestureDetector(
      onTap: () async {
        if (isLastStep) {
          await notifier.completeOnboarding();
        } else {
          notifier.nextStep();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLastStep ? AppStrings.finish : AppStrings.next,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isLastStep) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(width: 140, height: 140, decoration: BoxDecoration(gradient: AppTheme.glowGradient, shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, size: 60, color: AppTheme.primaryLight)),
          const SizedBox(height: 32),
          Text(AppStrings.onboardingTitle1, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(AppStrings.onboardingDesc1, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 36),
          _FeatureCard(icon: Icons.bolt, title: AppStrings.smartPlanningTitle, description: AppStrings.smartPlanningDesc, delay: 700),
          const SizedBox(height: 12),
          _FeatureCard(icon: Icons.mic, title: AppStrings.voiceCommandsTitle, description: AppStrings.voiceCommandsDesc, delay: 900),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int delay;
  const _FeatureCard({required this.icon, required this.title, required this.description, required this.delay});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryLight, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
                const SizedBox(height: 3),
                Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: -0.2);
  }
}
