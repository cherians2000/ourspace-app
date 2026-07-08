import '../../domain/entities/app_user.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../datasources/authentication_remote_data_source.dart';

/// Default [AuthenticationRepository], backed by a remote data source.
///
/// Responsible for model→entity conversion. SDK error mapping to
/// `AuthException` is added together with the Firebase Auth integration.
class AuthenticationRepositoryImpl implements AuthenticationRepository {
  const AuthenticationRepositoryImpl(this._remote);

  final AuthenticationRemoteDataSource _remote;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _remote.signIn(email: email, password: password);
    return user.toEntity();
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    final user = await _remote.signUp(email: email, password: password);
    return user.toEntity();
  }

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<void> forgotPassword({required String email}) {
    return _remote.forgotPassword(email: email);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = await _remote.getCurrentUser();
    return user?.toEntity();
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _remote.authStateChanges().map((model) => model?.toEntity());
  }
}
