/// Remote storage for profile photos.
abstract interface class ProfilePhotoStorageDataSource {
  /// Uploads the photo at [filePath] for [uid] and returns its public
  /// download URL. Implementations must overwrite the previous photo
  /// rather than accumulate files.
  Future<String> uploadProfilePhoto({
    required String uid,
    required String filePath,
  });

  /// Deletes the stored photo object for [uid], if any.
  Future<void> deleteProfilePhoto({required String uid});
}
