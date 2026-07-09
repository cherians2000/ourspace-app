import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/app_user.dart';

/// Data-transfer representation of a user.
///
/// Deliberately independent from [AppUser]; the layers exchange users
/// exclusively through [toEntity] and [fromEntity]. SDK mappings (e.g.
/// [fromFirebaseUser]) are added here, never on the entity.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.emailVerified = false,
  });

  factory UserModel.fromEntity(AppUser entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      photoUrl: entity.photoUrl,
      emailVerified: entity.emailVerified,
    );
  }

  factory UserModel.fromFirebaseUser(firebase_auth.User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final bool emailVerified;

  AppUser toEntity() {
    return AppUser(
      id: id,
      email: email,
      name: name,
      photoUrl: photoUrl,
      emailVerified: emailVerified,
    );
  }
}
