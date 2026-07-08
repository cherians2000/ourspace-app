import '../entities/app_user.dart';

/// Contract for authentication operations.
///
/// Implementations live in the data layer and must surface expected
/// failures as `AuthException`.
abstract interface class AuthenticationRepository {
  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({required String email, required String password});

  Future<void> signOut();

  Future<void> forgotPassword({required String email});

  Future<AppUser?> getCurrentUser();

  /// Emits the current user on every auth state change (`null` when
  /// signed out). Router redirects will consume this.
  Stream<AppUser?> authStateChanges();
}
