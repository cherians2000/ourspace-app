import '../models/user_profile_model.dart';

/// Remote profile operations, in data-layer terms.
abstract interface class UserProfileRemoteDataSource {
  /// Creates the profile document if absent, otherwise refreshes only the
  /// session-mirror fields. Must be atomic under concurrent calls.
  Future<UserProfileModel> ensureProfile({
    required String uid,
    required String email,
    required String? displayName,
    required String? photoUrl,
    required bool emailVerified,
  });

  Stream<UserProfileModel?> watchProfile(String uid);

  /// Deletes every user-owned Firestore document. The single,
  /// centralized cleanup point: future user-owned collections must be
  /// added to its implementation.
  Future<void> deleteUserData(String uid);

  /// Partial update of profile document fields.
  Future<void> updateProfileFields(String uid, Map<String, dynamic> fields);

  /// Mirrors profile changes onto the authentication user record.
  /// Only non-null values are applied; [clearPhotoUrl] explicitly resets
  /// the photo (since `null` means "no change" here).
  Future<void> syncAuthUser({
    String? displayName,
    String? photoUrl,
    bool clearPhotoUrl = false,
  });
}
