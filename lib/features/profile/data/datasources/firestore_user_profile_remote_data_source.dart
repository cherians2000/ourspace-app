import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/user_profile_model.dart';
import 'user_profile_remote_data_source.dart';

/// Cloud Firestore-backed [UserProfileRemoteDataSource].
///
/// Documents live at `users/{uid}` — keying by uid makes duplicate
/// profiles structurally impossible.
class FirestoreUserProfileRemoteDataSource
    implements UserProfileRemoteDataSource {
  FirestoreUserProfileRemoteDataSource({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;

  static const String _collection = 'users';

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore.collection(_collection).doc(uid);
  }

  /// Derives the profile's `provider` field from the live Firebase user.
  ///
  /// Read here (data layer) because the domain [AppUser] deliberately
  /// carries no SDK provider details.
  String _currentProvider() {
    final providers = _auth.currentUser?.providerData ?? const [];
    for (final info in providers) {
      if (info.providerId == 'google.com') return 'google';
    }
    return 'email';
  }

  @override
  Future<UserProfileModel> ensureProfile({
    required String uid,
    required String email,
    required String? displayName,
    required String? photoUrl,
    required bool emailVerified,
  }) async {
    final doc = _doc(uid);

    // Transaction: the exists-check and the write are atomic, so
    // concurrent sign-ins (multiple devices, double taps) can never
    // produce conflicting creates or lost updates.
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      if (snapshot.exists) {
        transaction.update(
          doc,
          UserProfileModel.sessionRefreshData(emailVerified: emailVerified),
        );
      } else {
        transaction.set(
          doc,
          UserProfileModel.createData(
            uid: uid,
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
            provider: _currentProvider(),
            emailVerified: emailVerified,
          ),
        );
      }
    });

    final fresh = await doc.get();
    return UserProfileModel.fromMap(fresh.id, fresh.data() ?? const {});
  }

  @override
  Future<void> updateProfileFields(String uid, Map<String, dynamic> fields) {
    return _doc(uid).update(fields);
  }

  @override
  Future<void> syncAuthUser({
    String? displayName,
    String? photoUrl,
    bool clearPhotoUrl = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (displayName != null) await user.updateDisplayName(displayName);
    if (clearPhotoUrl) {
      await user.updatePhotoURL(null);
    } else if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }
  }

  @override
  Future<void> deleteUserData(String uid) async {
    // CENTRALIZED user-data cleanup for account deletion. When new
    // user-owned collections are added (spaces memberships, presence,
    // settings, ...), delete them here in the same batch.
    final batch = _firestore.batch();
    batch.delete(_doc(uid));
    await batch.commit();
  }

  @override
  Stream<UserProfileModel?> watchProfile(String uid) {
    return _doc(uid).snapshots().map(
          (snapshot) => snapshot.exists
              ? UserProfileModel.fromMap(snapshot.id, snapshot.data()!)
              : null,
        );
  }
}
