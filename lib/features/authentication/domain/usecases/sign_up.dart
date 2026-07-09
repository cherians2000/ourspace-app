import '../entities/app_user.dart';
import '../repositories/authentication_repository.dart';

/// Registers a new user with email and password.
class SignUp {
  const SignUp(this._repository);

  final AuthenticationRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
    String? displayName,
  }) {
    final name = displayName?.trim();
    return _repository.signUp(
      email: email,
      password: password,
      displayName: (name == null || name.isEmpty) ? null : name,
    );
  }
}
