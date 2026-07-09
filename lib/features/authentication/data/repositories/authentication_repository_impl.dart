import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:google_sign_in/google_sign_in.dart'
    show GoogleSignInException, GoogleSignInExceptionCode;

import '../../domain/entities/app_user.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../datasources/authentication_remote_data_source.dart';

/// Default [AuthenticationRepository], backed by a remote data source.
///
/// The error boundary of the feature: every SDK exception is translated to
/// a domain [AuthException] here, so no Firebase type crosses into domain
/// or presentation.
class AuthenticationRepositoryImpl implements AuthenticationRepository {
  const AuthenticationRepositoryImpl(this._remote);

  final AuthenticationRemoteDataSource _remote;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final user = await _remote.signIn(email: email, password: password);
      return user.toEntity();
    });
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _guard(() async {
      final user = await _remote.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      return user.toEntity();
    });
  }

  @override
  Future<AppUser> signInWithGoogle() {
    return _guard(() async {
      final user = await _remote.signInWithGoogle();
      return user.toEntity();
    });
  }

  @override
  Future<void> sendEmailVerification() {
    return _guard(_remote.sendEmailVerification);
  }

  @override
  Future<AppUser?> reloadCurrentUser() {
    return _guard(() async {
      final user = await _remote.reloadCurrentUser();
      return user?.toEntity();
    });
  }

  @override
  Future<void> signOut() => _guard(_remote.signOut);

  @override
  Future<void> deleteAccount() => _guard(_remote.deleteAccount);

  @override
  Future<bool> needsRecentLogin() => _guard(_remote.needsRecentLogin);

  @override
  Future<void> reauthenticate({String? password}) {
    return _guard(() => _remote.reauthenticate(password: password));
  }

  @override
  Future<void> forgotPassword({required String email}) {
    return _guard(() => _remote.forgotPassword(email: email));
  }

  @override
  Future<AppUser?> getCurrentUser() {
    return _guard(() async {
      final user = await _remote.getCurrentUser();
      return user?.toEntity();
    });
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _remote.authStateChanges().map((model) => model?.toEntity());
  }

  /// Runs [action], translating SDK errors into domain [AuthException]s.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e, stackTrace) {
      _log('FirebaseAuthException(code: ${e.code})', e, stackTrace);
      throw AuthException(_mapCode(e.code), e.message);
    } on GoogleSignInException catch (e, stackTrace) {
      _log(
        'GoogleSignInException(code: ${e.code.name}, '
        'description: ${e.description}, details: ${e.details})',
        e,
        stackTrace,
      );
      throw AuthException(
        e.code == GoogleSignInExceptionCode.canceled
            ? AuthErrorReason.cancelled
            : AuthErrorReason.unknown,
        e.description,
      );
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Unexpected ${e.runtimeType}', e, stackTrace);
      throw AuthException(AuthErrorReason.unknown, e.toString());
    }
  }

  /// Logs the original SDK error before it is mapped to a domain
  /// [AuthException], so root causes are never masked by the mapping.
  static void _log(String summary, Object error, StackTrace stackTrace) {
    developer.log(
      summary,
      name: 'AuthenticationRepository',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static AuthErrorReason _mapCode(String code) {
    return switch (code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-email' ||
      'user-disabled' =>
        AuthErrorReason.invalidCredentials,
      'email-already-in-use' ||
      'account-exists-with-different-credential' =>
        AuthErrorReason.emailAlreadyInUse,
      'weak-password' => AuthErrorReason.weakPassword,
      'network-request-failed' => AuthErrorReason.network,
      'too-many-requests' => AuthErrorReason.tooManyRequests,
      'requires-recent-login' => AuthErrorReason.requiresRecentLogin,
      'no-current-user' ||
      'user-token-expired' =>
        AuthErrorReason.sessionExpired,
      _ => AuthErrorReason.unknown,
    };
  }
}
