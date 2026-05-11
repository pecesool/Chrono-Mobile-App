import '../../data/models/user_profile.dart';
import '../../core/services/hive_service.dart';

class UserRepository {
  Future<void> saveProfile(UserProfile profile) async {
    await HiveService.saveUserProfile(profile);
  }

  UserProfile? getProfile() {
    return HiveService.getUserProfile();
  }

  bool hasProfile() {
    return HiveService.hasUserProfile();
  }
}
