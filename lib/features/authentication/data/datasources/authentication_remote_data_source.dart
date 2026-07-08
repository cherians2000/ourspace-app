import '../models/user_model.dart';

/// Remote authentication operations, in data-layer terms.
///
/// Mirrors the domain repository contract but speaks [UserModel] and raw
/// SDK errors; translation to entities and `AuthException` happens in the
/// repository implementation.
abstract interface class AuthenticationRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signUp({required String email, required String password});

  Future<void> signOut();

  Future<void> forgotPassword({required String email});

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> authStateChanges();
}
