import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import 'authentication_remote_data_source.dart';

/// Firebase-backed [AuthenticationRemoteDataSource].
///
/// Speaks the raw SDKs: [firebase_auth.FirebaseAuthException] and
/// [GoogleSignInException] are allowed to propagate; the repository
/// implementation maps them to domain `AuthException`s.
class FirebaseAuthenticationRemoteDataSource
    implements AuthenticationRemoteDataSource {
  FirebaseAuthenticationRemoteDataSource({firebase_auth.FirebaseAuth? auth})
      : _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  final firebase_auth.FirebaseAuth _auth;

  /// One-time google_sign_in v7 initialization, memoized.
  Future<void>? _googleInitialization;

  Future<void> _ensureGoogleInitialized() {
    return _googleInitialization ??= GoogleSignIn.instance.initialize();
  }

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
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    var user = credential.user!;
    // Set the name before sending the verification email, so email
    // templates using %DISPLAY_NAME% address the user correctly.
    if (displayName != null) {
      await user.updateDisplayName(displayName);
      await user.reload();
      user = _auth.currentUser ?? user;
    }
    // Part of the registration contract: the verification email goes out
    // immediately with account creation.
    await user.sendEmailVerification();
    return UserModel.fromFirebaseUser(user);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google returned no ID token. If this persists, pass the '
            'Firebase web client ID as serverClientId to '
            'GoogleSignIn.initialize.',
      );
    }
    final credential = firebase_auth.GoogleAuthProvider.credential(
      idToken: idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return UserModel.fromFirebaseUser(userCredential.user!);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(code: 'no-current-user');
    }
    await user.sendEmailVerification();
  }

  @override
  Future<UserModel?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final wasVerified = user.emailVerified;
    await user.reload();
    final fresh = _auth.currentUser;
    if (fresh == null) return null;

    if (!wasVerified && fresh.emailVerified) {
      // Force a token refresh so userChanges() re-emits: the reload alone
      // updates local state silently, and the router only reacts to
      // stream emissions.
      await fresh.getIdToken(true);
    }
    return UserModel.fromFirebaseUser(fresh);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(code: 'no-current-user');
    }
    await user.delete();
  }

  /// Firebase treats a login as "recent" for roughly five minutes; this
  /// uses a conservative window so the check errs toward
  /// re-authenticating rather than failing mid-deletion.
  static const Duration _recentLoginWindow = Duration(minutes: 4);

  @override
  Future<bool> needsRecentLogin() async {
    final lastSignIn = _auth.currentUser?.metadata.lastSignInTime;
    if (lastSignIn == null) return true;
    return DateTime.now().difference(lastSignIn) > _recentLoginWindow;
  }

  @override
  Future<void> reauthenticate({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(code: 'no-current-user');
    }

    if (password != null) {
      final email = user.email;
      if (email == null) {
        throw firebase_auth.FirebaseAuthException(code: 'no-current-user');
      }
      await user.reauthenticateWithCredential(
        firebase_auth.EmailAuthProvider.credential(
          email: email,
          password: password,
        ),
      );
      return;
    }

    // Provider (Google) re-authentication.
    await _ensureGoogleInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google returned no ID token during re-authentication.',
      );
    }
    await user.reauthenticateWithCredential(
      firebase_auth.GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Best-effort: Google sign-out only clears the picker default.
      // Firebase sign-out below is what actually ends the session.
    }
    await _auth.signOut();
  }

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
    // userChanges() is a superset of authStateChanges(): same sign-in/out
    // events, plus profile and token updates (e.g. email verification).
    return _auth.userChanges().map(
          (user) => user == null ? null : UserModel.fromFirebaseUser(user),
        );
  }
}
