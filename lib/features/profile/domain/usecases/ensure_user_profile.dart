import '../../../authentication/domain/entities/app_user.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

/// Creates or refreshes the canonical profile for an established session.
///
/// Invoked on successful sign-in/sign-up and on restored sessions at app
/// startup — never from a passive stream listener.
class EnsureUserProfile {
  const EnsureUserProfile(this._repository);

  final UserProfileRepository _repository;

  Future<UserProfile> call(AppUser user) => _repository.ensureProfile(user);
}
