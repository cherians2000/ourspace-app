import '../../../authentication/domain/entities/app_user.dart';
import '../entities/user_profile.dart';

/// Contract for the canonical user profile.
///
/// Depends on the authentication domain's [AppUser] as input — profile
/// depends on identity, never the reverse.
abstract interface class UserProfileRepository {
  /// Creates the profile on the user's first session, otherwise refreshes
  /// only `lastLogin` and `emailVerified` (fields that mirror
  /// Authentication). Idempotent: never duplicates or overwrites profile
  /// data.
  Future<UserProfile> ensureProfile(AppUser user);

  /// Live view of a profile document; emits `null` while it doesn't exist.
  Stream<UserProfile?> watchProfile(String uid);

  /// Updates the display name in the canonical profile (and mirrors it to
  /// the authentication provider, best-effort).
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  });

  /// Uploads a new profile photo from a local file path and stores its
  /// URL in the canonical profile (mirrored to the authentication
  /// provider, best-effort). Returns the new photo URL.
  Future<String> updateProfilePhoto({
    required String uid,
    required String photoPath,
  });

  /// Removes the profile photo: clears the canonical `photoUrl`, deletes
  /// the stored object (best-effort) and clears the authentication
  /// provider's mirror.
  Future<void> removeProfilePhoto(String uid);

  /// Mirrors the authoritative FirebaseAuth `emailVerified` flag into
  /// the profile document (a convenience copy, never the source of
  /// truth). Call only when the value actually changed.
  Future<void> syncEmailVerified({
    required String uid,
    required bool emailVerified,
  });

  /// Deletes all of the user's stored data: the profile photo
  /// (best-effort) and every user-owned Firestore document. Part of
  /// account deletion; must run while the user is still authenticated.
  Future<void> deleteProfile(String uid);
}
