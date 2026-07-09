import '../entities/app_user.dart';
import '../repositories/authentication_repository.dart';

/// Signs a user in with their Google account.
class SignInWithGoogle {
  const SignInWithGoogle(this._repository);

  final AuthenticationRepository _repository;

  Future<AppUser> call() => _repository.signInWithGoogle();
}
