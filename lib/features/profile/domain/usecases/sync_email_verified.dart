import '../repositories/user_profile_repository.dart';

/// Mirrors a changed FirebaseAuth `emailVerified` flag into the Firestore
/// profile. FirebaseAuth remains the source of truth; the profile copy
/// exists for display and queries only.
class SyncEmailVerified {
  const SyncEmailVerified(this._repository);

  final UserProfileRepository _repository;

  Future<void> call({required String uid, required bool emailVerified}) {
    return _repository.syncEmailVerified(
      uid: uid,
      emailVerified: emailVerified,
    );
  }
}
