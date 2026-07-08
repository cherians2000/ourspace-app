import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;

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
  }) {
    return _guard(() async {
      final user = await _remote.signUp(email: email, password: password);
      return user.toEntity();
    });
  }

  @override
  Future<void> signOut() => _guard(_remote.signOut);

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
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code), e.message);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(AuthErrorReason.unknown, e.toString());
    }
  }

  static AuthErrorReason _mapCode(String code) {
    return switch (code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-email' ||
      'user-disabled' =>
        AuthErrorReason.invalidCredentials,
      'email-already-in-use' => AuthErrorReason.emailAlreadyInUse,
      'weak-password' => AuthErrorReason.weakPassword,
      'network-request-failed' => AuthErrorReason.network,
      _ => AuthErrorReason.unknown,
    };
  }
}
