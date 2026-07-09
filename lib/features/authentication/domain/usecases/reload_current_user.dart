import '../entities/app_user.dart';
import '../repositories/authentication_repository.dart';

/// Re-fetches the current user from the server, picking up changes such
/// as a completed email verification. Returns `null` when signed out.
class ReloadCurrentUser {
  const ReloadCurrentUser(this._repository);

  final AuthenticationRepository _repository;

  Future<AppUser?> call() => _repository.reloadCurrentUser();
}
