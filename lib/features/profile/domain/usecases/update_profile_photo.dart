import '../repositories/user_profile_repository.dart';

/// Uploads and sets a new profile photo from a local file path.
/// Returns the new photo URL.
class UpdateProfilePhoto {
  const UpdateProfilePhoto(this._repository);

  final UserProfileRepository _repository;

  Future<String> call({required String uid, required String photoPath}) {
    return _repository.updateProfilePhoto(uid: uid, photoPath: photoPath);
  }
}
