import '../models/user_model.dart';

/// Remote authentication operations, in data-layer terms.
///
/// Mirrors the domain repository contract but speaks [UserModel] and raw
/// SDK errors; translation to entities and `AuthException` happens in the
/// repository implementation.
abstract interface class AuthenticationRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});

  /// Creates the account, sets the display name when provided, and sends
  /// a verification email immediately.
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<UserModel> signInWithGoogle();

  Future<void> sendEmailVerification();

  Future<UserModel?> reloadCurrentUser();

  Future<void> signOut();

  Future<void> deleteAccount();

  Future<bool> needsRecentLogin();

  Future<void> reauthenticate({String? password});

  Future<void> forgotPassword({required String email});

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> authStateChanges();
}
