import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/user_model.dart';
import 'authentication_remote_data_source.dart';

/// Firebase-backed [AuthenticationRemoteDataSource].
///
/// Speaks the raw SDK: [firebase_auth.FirebaseAuthException]s are allowed
/// to propagate; the repository implementation maps them to domain
/// `AuthException`s.
class FirebaseAuthenticationRemoteDataSource
    implements AuthenticationRemoteDataSource {
  FirebaseAuthenticationRemoteDataSource({firebase_auth.FirebaseAuth? auth})
      : _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  final firebase_auth.FirebaseAuth _auth;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserModel.fromFirebaseUser(credential.user!);
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserModel.fromFirebaseUser(credential.user!);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> forgotPassword({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    return user == null ? null : UserModel.fromFirebaseUser(user);
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _auth.authStateChanges().map(
          (user) => user == null ? null : UserModel.fromFirebaseUser(user),
        );
  }
}
