import 'package:equatable/equatable.dart';

/// Authenticated user of the application.
///
/// Auth-scoped identity only. The full profile (username, bio, ...) is a
/// separate concern and will live in its own domain once Firestore lands.
///
/// Named `AppUser` to avoid colliding with `firebase_auth`'s `User` in the
/// data layer.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? name;
  final String? photoUrl;

  @override
  List<Object?> get props => [id, email, name, photoUrl];
}
