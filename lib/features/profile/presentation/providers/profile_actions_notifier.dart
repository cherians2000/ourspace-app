import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/exceptions/profile_exception.dart';
import 'profile_actions_state.dart';
import 'profile_providers.dart';

/// Orchestrates profile edit actions.
///
/// Results appear in the UI through `userProfileProvider` (the Firestore
/// stream echoes every successful write back); this notifier only tracks
/// whether an action is in flight and whether it failed.
class ProfileActionsNotifier extends Notifier<ProfileActionsState> {
  @override
  ProfileActionsState build() => const ProfileActionsState();

  /// Returns true on success.
  Future<bool> updateDisplayName({
    required String uid,
    required String displayName,
  }) {
    return _run(() => ref.read(updateDisplayNameProvider)(
          uid: uid,
          displayName: displayName,
        ));
  }

  /// Returns true on success.
  Future<bool> updateProfilePhoto({
    required String uid,
    required String photoPath,
  }) {
    return _run(() => ref.read(updateProfilePhotoProvider)(
          uid: uid,
          photoPath: photoPath,
        ));
  }

  /// Clears a visible failure (user edited a field or returned to the
  /// page), so stale error banners never outlive their context.
  void clearError() {
    if (state.status == ProfileActionStatus.failure) {
      state = const ProfileActionsState();
    }
  }

  /// Returns true on success.
  Future<bool> removeProfilePhoto({required String uid}) {
    return _run(() => ref.read(removeProfilePhotoProvider)(uid: uid));
  }

  /// Permanently deletes the account and all user data. On success the
  /// session stream emits null and the router redirects to login; no
  /// navigation happens here. Returns true on success.
  ///
  /// When Firebase demands a recent login, email accounts fail with
  /// [ProfileErrorReason.requiresRecentLogin] until called again with
  /// [password]; Google accounts re-authenticate inline.
  Future<bool> deleteAccount({
    required String uid,
    required ProfileAuthProvider provider,
    String? password,
  }) {
    return _run(() => ref.read(deleteAccountProvider)(
          uid: uid,
          provider: provider,
          password: password,
        ));
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const ProfileActionsState(status: ProfileActionStatus.saving);
    try {
      await action();
      state = const ProfileActionsState();
      return true;
    } on ProfileException catch (e) {
      // Dismissing a re-auth flow is not a failure; return quietly.
      state = e.reason == ProfileErrorReason.cancelled
          ? const ProfileActionsState()
          : ProfileActionsState(
              status: ProfileActionStatus.failure,
              error: e,
            );
      return false;
    }
  }
}
