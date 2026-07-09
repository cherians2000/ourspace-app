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
    this.verificationEmailSentAt,
  });

  final AuthStatus status;

  /// Non-null when [status] is [AuthStatus.authenticated].
  final AppUser? user;

  /// Non-null when [status] is [AuthStatus.failure].
  final AuthException? error;

  /// When a verification email was last sent in this app session (at
  /// sign-up or via resend). Null when none was sent this session —
  /// e.g. an existing unverified user who just logged in. The verify
  /// screen derives its resend cooldown from this.
  final DateTime? verificationEmailSentAt;

  static const Object _unset = Object();

  /// Copies the state; pass `null` explicitly to clear nullable fields.
  AuthState copyWith({
    AuthStatus? status,
    Object? user = _unset,
    Object? error = _unset,
    Object? verificationEmailSentAt = _unset,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: identical(user, _unset) ? this.user : user as AppUser?,
      error: identical(error, _unset) ? this.error : error as AuthException?,
      verificationEmailSentAt: identical(verificationEmailSentAt, _unset)
          ? this.verificationEmailSentAt
          : verificationEmailSentAt as DateTime?,
    );
  }

  @override
  List<Object?> get props => [status, user, error, verificationEmailSentAt];
}
