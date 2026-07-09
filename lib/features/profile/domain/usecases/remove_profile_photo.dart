import '../repositories/user_profile_repository.dart';

/// Removes the user's profile photo.
class RemoveProfilePhoto {
  const RemoveProfilePhoto(this._repository);

  final UserProfileRepository _repository;

  Future<void> call({required String uid}) {
    return _repository.removeProfilePhoto(uid);
  }
}
