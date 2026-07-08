import '../../domain/entities/app_user.dart';

/// Data-transfer representation of a user.
///
/// Deliberately independent from [AppUser]; the layers exchange users
/// exclusively through [toEntity] and [fromEntity]. SDK mappings (e.g.
/// `fromFirebaseUser`) are added here, never on the entity.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
  });

  factory UserModel.fromEntity(AppUser entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      photoUrl: entity.photoUrl,
    );
  }

  final String id;
  final String email;
  final String? name;
  final String? photoUrl;

  AppUser toEntity() {
    return AppUser(id: id, email: email, name: name, photoUrl: photoUrl);
  }
}
