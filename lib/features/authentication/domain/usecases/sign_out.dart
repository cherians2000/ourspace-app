import '../repositories/authentication_repository.dart';

/// Signs the current user out.
class SignOut {
  const SignOut(this._repository);

  final AuthenticationRepository _repository;

  Future<void> call() => _repository.signOut();
}
