import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

/// Streams the canonical profile of a user.
class WatchUserProfile {
  const WatchUserProfile(this._repository);

  final UserProfileRepository _repository;

  Stream<UserProfile?> call(String uid) => _repository.watchProfile(uid);
}
