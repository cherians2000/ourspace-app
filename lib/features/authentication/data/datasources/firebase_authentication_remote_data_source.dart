import '../models/user_model.dart';
import 'authentication_remote_data_source.dart';

/// Firebase-backed [AuthenticationRemoteDataSource].
///
/// Scaffold only: the Firebase Auth SDK is wired in by the authentication
/// integration task. Until then every method throws [UnimplementedError].
class FirebaseAuthenticationRemoteDataSource
    implements AuthenticationRemoteDataSource {
  const FirebaseAuthenticationRemoteDataSource();

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) {
    throw UnimplementedError('Firebase Auth integration pending');
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
  }) {
    throw UnimplementedError('Firebase Auth integration pending');
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError('Firebase Auth integration pending');
  }

  @override
  Future<void> forgotPassword({required String email}) {
    throw UnimplementedError('Firebase Auth integration pending');
  }

  @override
  Future<UserModel?> getCurrentUser() {
    throw UnimplementedError('Firebase Auth integration pending');
  }

  @override
  Stream<UserModel?> authStateChanges() {
    throw UnimplementedError('Firebase Auth integration pending');
  }
}
