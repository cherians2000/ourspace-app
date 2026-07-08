import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/exceptions/auth_exception.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

/// Immutable authentication state exposed to the UI.
class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  final AuthStatus status;

  /// Non-null when [status] is [AuthStatus.authenticated].
  final AppUser? user;

  /// Non-null when [status] is [AuthStatus.failure].
  final AuthException? error;

  static const Object _unset = Object();

  /// Copies the state; pass `null` explicitly to clear [user] or [error].
  AuthState copyWith({
    AuthStatus? status,
    Object? user = _unset,
    Object? error = _unset,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: identical(user, _unset) ? this.user : user as AppUser?,
      error: identical(error, _unset) ? this.error : error as AuthException?,
    );
  }

  @override
  List<Object?> get props => [status, user, error];
}
