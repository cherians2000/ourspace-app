import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/authentication_remote_data_source.dart';
import '../../data/datasources/firebase_authentication_remote_data_source.dart';
import '../../data/repositories/authentication_repository_impl.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../../domain/usecases/forgot_password.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

/// Composition root for the authentication feature.
///
/// The only place where concrete data-layer classes are bound to domain
/// contracts. Everything else depends on interfaces.

final authRemoteDataSourceProvider = Provider<AuthenticationRemoteDataSource>(
  (ref) => FirebaseAuthenticationRemoteDataSource(),
);

final authenticationRepositoryProvider = Provider<AuthenticationRepository>(
  (ref) => AuthenticationRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);

// Use cases

final signInProvider = Provider<SignIn>(
  (ref) => SignIn(ref.watch(authenticationRepositoryProvider)),
);

final signUpProvider = Provider<SignUp>(
  (ref) => SignUp(ref.watch(authenticationRepositoryProvider)),
);

final signOutProvider = Provider<SignOut>(
  (ref) => SignOut(ref.watch(authenticationRepositoryProvider)),
);

final forgotPasswordProvider = Provider<ForgotPassword>(
  (ref) => ForgotPassword(ref.watch(authenticationRepositoryProvider)),
);

final getCurrentUserProvider = Provider<GetCurrentUser>(
  (ref) => GetCurrentUser(ref.watch(authenticationRepositoryProvider)),
);

// State

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
