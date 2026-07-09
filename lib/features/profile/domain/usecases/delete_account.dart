import '../../../authentication/domain/exceptions/auth_exception.dart';
import '../../../authentication/domain/repositories/authentication_repository.dart';
import '../entities/user_profile.dart';
import '../exceptions/profile_exception.dart';
import '../repositories/user_profile_repository.dart';

/// Permanently deletes the user's account and all their data.
///
/// Re-authentication is resolved *before* any destructive work, so user
/// data is never deleted while the authentication account survives:
///
/// 1. If Firebase will demand a recent login, re-authenticate first —
///    via the Google flow for Google accounts, or with [password] for
///    email accounts (thrown back to the UI to collect when missing).
/// 2. Only then: delete the profile photo and all user-owned Firestore
///    documents (rules require the authenticated owner), and finally the
///    authentication account itself.
class DeleteAccount {
  const DeleteAccount(this._profileRepository, this._authRepository);

  final UserProfileRepository _profileRepository;
  final AuthenticationRepository _authRepository;

  Future<void> call({
    required String uid,
    required ProfileAuthProvider provider,
    String? password,
  }) async {
    // Resolve the recent-login requirement before touching any data.
    if (await _authRepository.needsRecentLogin()) {
      if (provider == ProfileAuthProvider.email && password == null) {
        // The UI must collect the password and retry; nothing was
        // deleted.
        throw const ProfileException(
          ProfileErrorReason.requiresRecentLogin,
          'Password required for re-authentication',
        );
      }
      try {
        await _authRepository.reauthenticate(password: password);
      } on AuthException catch (e) {
        throw ProfileException(_mapReauthFailure(e.reason), e.message);
      }
    }

    // Re-authentication settled: now (and only now) delete data. Rules
    // require the authenticated owner, so cleanup precedes account
    // deletion.
    await _profileRepository.deleteProfile(uid);

    try {
      await _authRepository.deleteAccount();
    } on AuthException catch (e) {
      throw ProfileException(
        e.reason == AuthErrorReason.requiresRecentLogin
            ? ProfileErrorReason.requiresRecentLogin
            : e.reason == AuthErrorReason.network
                ? ProfileErrorReason.network
                : ProfileErrorReason.unknown,
        e.message,
      );
    }

    // Clears any provider session (e.g. the Google account picker
    // default). Best-effort: the account no longer exists either way.
    try {
      await _authRepository.signOut();
    } catch (_) {
      // Ignored: the session is already invalid after deletion.
    }
  }

  static ProfileErrorReason _mapReauthFailure(AuthErrorReason reason) {
    return switch (reason) {
      AuthErrorReason.cancelled => ProfileErrorReason.cancelled,
      AuthErrorReason.invalidCredentials =>
        ProfileErrorReason.reauthenticationFailed,
      AuthErrorReason.network => ProfileErrorReason.network,
      _ => ProfileErrorReason.unknown,
    };
  }
}
