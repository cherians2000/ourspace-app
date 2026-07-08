import '../entities/app_user.dart';
import '../repositories/authentication_repository.dart';

/// Returns the currently signed-in user, or `null` when signed out.
class GetCurrentUser {
  const GetCurrentUser(this._repository);

  final AuthenticationRepository _repository;

  Future<AppUser?> call() => _repository.getCurrentUser();
}
