import '../exceptions/profile_exception.dart';
import '../repositories/user_profile_repository.dart';

/// Updates the user's display name.
class UpdateDisplayName {
  const UpdateDisplayName(this._repository);

  final UserProfileRepository _repository;

  static const int maxLength = 50;

  Future<void> call({required String uid, required String displayName}) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw const ProfileException(
        ProfileErrorReason.invalidInput,
        'Display name must not be empty',
      );
    }
    if (trimmed.length > maxLength) {
      throw const ProfileException(
        ProfileErrorReason.invalidInput,
        'Display name is too long',
      );
    }
    return _repository.updateDisplayName(uid: uid, displayName: trimmed);
  }
}
