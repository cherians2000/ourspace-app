import 'package:equatable/equatable.dart';

/// How the account was originally authenticated.
enum ProfileAuthProvider { email, google }

/// The application's canonical user record, stored in Cloud Firestore.
///
/// Authentication remains the source of identity; this profile is the
/// application-level document other features build upon.
class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
    required this.emailVerified,
    this.createdAt,
    this.lastLogin,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final ProfileAuthProvider provider;

  /// Convenience mirror of FirebaseAuth's `emailVerified`. The
  /// authoritative value is always the authentication session
  /// (`AppUser.emailVerified`); never gate logic on this copy.
  final bool emailVerified;

  /// Server timestamps; null only in the brief window before the server
  /// resolves a just-written value.
  final DateTime? createdAt;
  final DateTime? lastLogin;

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        provider,
        emailVerified,
        createdAt,
        lastLogin,
      ];
}
