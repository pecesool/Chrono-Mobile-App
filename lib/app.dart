import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'providers/onboarding_provider.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/dashboard/dashboard_screen.dart';

class ChronoApp extends ConsumerWidget {
  const ChronoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);

    return MaterialApp(
      title: 'Chrono',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: onboardingState.isCompleted
          ? const DashboardScreen()
          : const OnboardingScreen(),
    );
  }
}
