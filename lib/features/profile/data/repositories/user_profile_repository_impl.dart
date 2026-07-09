import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:supabase_flutter/supabase_flutter.dart' show StorageException;

import '../../../authentication/domain/entities/app_user.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/exceptions/profile_exception.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/profile_photo_storage_data_source.dart';
import '../datasources/user_profile_remote_data_source.dart';

/// Default [UserProfileRepository], backed by Cloud Firestore.
///
/// The error boundary of the feature: SDK exceptions are logged and
/// mapped to domain [ProfileException]s here.
class UserProfileRepositoryImpl implements UserProfileRepository {
  const UserProfileRepositoryImpl(this._remote, this._photoStorage);

  final UserProfileRemoteDataSource _remote;
  final ProfilePhotoStorageDataSource _photoStorage;

  @override
  Future<UserProfile> ensureProfile(AppUser user) {
    return _guard(() async {
      final profile = await _remote.ensureProfile(
        uid: user.id,
        email: user.email,
        displayName: user.name,
        photoUrl: user.photoUrl,
        emailVerified: user.emailVerified,
      );
      return profile.toEntity();
    });
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _remote.watchProfile(uid).map((model) => model?.toEntity());
  }

  @override
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) {
    return _guard(() async {
      await _remote.updateProfileFields(uid, {'displayName': displayName});
      await _mirrorToAuth(displayName: displayName);
    });
  }

  @override
  Future<String> updateProfilePhoto({
    required String uid,
    required String photoPath,
  }) {
    return _guard(() async {
      final url = await _photoStorage.uploadProfilePhoto(
        uid: uid,
        filePath: photoPath,
      );
      await _remote.updateProfileFields(uid, {'photoUrl': url});
      await _mirrorToAuth(photoUrl: url);
      return url;
    });
  }

  @override
  Future<void> removeProfilePhoto(String uid) {
    return _guard(() async {
      // Canonical record first: the avatar disappears immediately.
      await _remote.updateProfileFields(uid, {'photoUrl': null});
      // Object deletion is best-effort: a leftover object is invisible
      // (nothing references it) and gets overwritten by the next upload.
      try {
        await _photoStorage.deleteProfilePhoto(uid: uid);
      } catch (e, stackTrace) {
        _log('Photo object deletion failed (harmless orphan)', e, stackTrace);
      }
      await _mirrorToAuth(clearPhotoUrl: true);
    });
  }

  @override
  Future<void> syncEmailVerified({
    required String uid,
    required bool emailVerified,
  }) {
    return _guard(
      () => _remote.updateProfileFields(uid, {'emailVerified': emailVerified}),
    );
  }

  @override
  Future<void> deleteProfile(String uid) {
    return _guard(() async {
      // Photo first, best-effort: after the Firestore doc and the auth
      // account are gone there is no later chance to clean it up.
      try {
        await _photoStorage.deleteProfilePhoto(uid: uid);
      } catch (e, stackTrace) {
        _log('Photo deletion failed during account deletion', e, stackTrace);
      }
      await _remote.deleteUserData(uid);
    });
  }

  /// Mirrors profile changes to Firebase Auth, best-effort: Firestore is
  /// the canonical record, so a failed mirror is logged, never surfaced.
  Future<void> _mirrorToAuth({
    String? displayName,
    String? photoUrl,
    bool clearPhotoUrl = false,
  }) async {
    try {
      await _remote.syncAuthUser(
        displayName: displayName,
        photoUrl: photoUrl,
        clearPhotoUrl: clearPhotoUrl,
      );
    } catch (e, stackTrace) {
      _log('Auth mirror sync failed', e, stackTrace);
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e, stackTrace) {
      _log('FirebaseException(code: ${e.code})', e, stackTrace);
      throw ProfileException(_mapCode(e.code), e.message);
    } on StorageException catch (e, stackTrace) {
      _log('StorageException(statusCode: ${e.statusCode})', e, stackTrace);
      throw ProfileException(_mapStorageStatus(e.statusCode), e.message);
    } on ProfileException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Unexpected ${e.runtimeType}', e, stackTrace);
      throw ProfileException(ProfileErrorReason.unknown, e.toString());
    }
  }

  /// Firestore error codes → domain reasons.
  static ProfileErrorReason _mapCode(String code) {
    return switch (code) {
      'permission-denied' => ProfileErrorReason.permissionDenied,
      'unavailable' || 'deadline-exceeded' => ProfileErrorReason.network,
      _ => ProfileErrorReason.unknown,
    };
  }

  /// Supabase Storage HTTP status codes → domain reasons.
  ///
  /// A 404 during upload means the `profile_photos` bucket itself is
  /// missing (uploads to an existing bucket create objects, never 404).
  static ProfileErrorReason _mapStorageStatus(String? statusCode) {
    return switch (statusCode) {
      '401' || '403' => ProfileErrorReason.permissionDenied,
      '404' => ProfileErrorReason.misconfigured,
      _ => ProfileErrorReason.unknown,
    };
  }

  static void _log(String summary, Object error, StackTrace stackTrace) {
    developer.log(
      summary,
      name: 'UserProfileRepository',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
