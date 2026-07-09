import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_profile.dart';

/// Firestore representation of a user profile.
///
/// Owns all document (de)serialization, including server-timestamp
/// sentinels; the entity never sees Firestore types.
class UserProfileModel {
  const UserProfileModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
    required this.emailVerified,
    this.createdAt,
    this.lastLogin,
  });

  factory UserProfileModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfileModel(
      uid: uid,
      email: (data['email'] as String?) ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      provider: (data['provider'] as String?) ?? 'email',
      emailVerified: (data['emailVerified'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String provider;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  /// Full document for first-time creation. Timestamps are always the
  /// Firestore server's, never device time.
  static Map<String, dynamic> createData({
    required String uid,
    required String email,
    required String? displayName,
    required String? photoUrl,
    required String provider,
    required bool emailVerified,
  }) {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'provider': provider,
      'emailVerified': emailVerified,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }

  /// Partial update for repeat sessions: only the fields that mirror
  /// Authentication. Existing profile data is never overwritten.
  static Map<String, dynamic> sessionRefreshData({
    required bool emailVerified,
  }) {
    return {
      'lastLogin': FieldValue.serverTimestamp(),
      'emailVerified': emailVerified,
    };
  }

  UserProfile toEntity() {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      provider: provider == 'google'
          ? ProfileAuthProvider.google
          : ProfileAuthProvider.email,
      emailVerified: emailVerified,
      createdAt: createdAt,
      lastLogin: lastLogin,
    );
  }
}
