import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile.dart';
import '../../core/services/hive_service.dart';

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

class OnboardingState {
  final bool isCompleted;
  final int currentStep;
  final Map<String, dynamic> formData;
  final bool isLoading;
  final String? error;

  OnboardingState({
    this.isCompleted = false,
    this.currentStep = 0,
    this.formData = const {},
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    bool? isCompleted,
    int? currentStep,
    Map<String, dynamic>? formData,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      isCompleted: isCompleted ?? this.isCompleted,
      currentStep: currentStep ?? this.currentStep,
      formData: formData ?? this.formData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState()) {
    _checkOnboardingStatus();
  }

  void _checkOnboardingStatus() {
    final isComplete = HiveService.isOnboardingComplete();
    if (isComplete) {
      state = state.copyWith(isCompleted: true);
    }
  }

  void nextStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void updateForm(String key, dynamic value) {
    state = state.copyWith(
      formData: {
        ...state.formData,
        key: value,
      },
    );
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = UserProfile(
        wakeUpTime: (state.formData['wakeUpTime'] ?? '08:00') as String,
        peakHours: (state.formData['peakHours'] ?? ProductivityPeak.morning) as ProductivityPeak,
        maxFocusMinutes: (state.formData['maxFocusMinutes'] ?? 90) as int,
        commonTasks: List<String>.from((state.formData['commonTasks'] ?? <String>[]) as List),
        timeManagementIssue: (state.formData['timeManagementIssue'] ?? '') as String,
        isOnboardingCompleted: true,
      );

      await HiveService.saveUserProfile(profile);
      await HiveService.setOnboardingComplete(true);

      state = state.copyWith(isCompleted: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
