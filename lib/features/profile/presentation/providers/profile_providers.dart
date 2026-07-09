import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/firestore_user_profile_remote_data_source.dart';
import '../../data/datasources/profile_photo_storage_data_source.dart';
import '../../data/datasources/supabase_profile_photo_storage_data_source.dart';
import '../../data/datasources/user_profile_remote_data_source.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/ensure_user_profile.dart';
import '../../domain/usecases/remove_profile_photo.dart';
import '../../domain/usecases/sync_email_verified.dart';
import '../../domain/usecases/update_display_name.dart';
import '../../domain/usecases/update_profile_photo.dart';
import '../../domain/usecases/watch_user_profile.dart';
import 'profile_actions_notifier.dart';
import 'profile_actions_state.dart';

/// Composition root for the profile feature.
///
/// No passive synchronization lives here: `ensureUserProfileProvider` is
/// invoked explicitly at session establishment (sign-in/sign-up success,
/// restored session during splash bootstrap).

final userProfileRemoteDataSourceProvider =
    Provider<UserProfileRemoteDataSource>(
  (ref) => FirestoreUserProfileRemoteDataSource(),
);

final profilePhotoStorageDataSourceProvider =
    Provider<ProfilePhotoStorageDataSource>(
  (ref) => SupabaseProfilePhotoStorageDataSource(),
);

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepositoryImpl(
    ref.watch(userProfileRemoteDataSourceProvider),
    ref.watch(profilePhotoStorageDataSourceProvider),
  ),
);

// Use cases

final ensureUserProfileProvider = Provider<EnsureUserProfile>(
  (ref) => EnsureUserProfile(ref.watch(userProfileRepositoryProvider)),
);

final watchUserProfileProvider = Provider<WatchUserProfile>(
  (ref) => WatchUserProfile(ref.watch(userProfileRepositoryProvider)),
);

final updateDisplayNameProvider = Provider<UpdateDisplayName>(
  (ref) => UpdateDisplayName(ref.watch(userProfileRepositoryProvider)),
);

final updateProfilePhotoProvider = Provider<UpdateProfilePhoto>(
  (ref) => UpdateProfilePhoto(ref.watch(userProfileRepositoryProvider)),
);

final removeProfilePhotoProvider = Provider<RemoveProfilePhoto>(
  (ref) => RemoveProfilePhoto(ref.watch(userProfileRepositoryProvider)),
);

final syncEmailVerifiedProvider = Provider<SyncEmailVerified>(
  (ref) => SyncEmailVerified(ref.watch(userProfileRepositoryProvider)),
);

final deleteAccountProvider = Provider<DeleteAccount>(
  (ref) => DeleteAccount(
    ref.watch(userProfileRepositoryProvider),
    ref.watch(authenticationRepositoryProvider),
  ),
);

// Action state (in-flight edits; profile data stays in userProfileProvider)

final profileActionsProvider =
    NotifierProvider<ProfileActionsNotifier, ProfileActionsState>(
  ProfileActionsNotifier.new,
);

// Canonical record

/// Live profile of the signed-in user; `null` when signed out or before
/// the profile document exists.
///
/// Selects only the session uid, so token refreshes and verification
/// re-emissions don't tear down and recreate the Firestore subscription.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(
    authStateChangesProvider.select((session) => session.value?.id),
  );
  if (uid == null) return Stream<UserProfile?>.value(null);
  return ref.watch(watchUserProfileProvider)(uid);
});
