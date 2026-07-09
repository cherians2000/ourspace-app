import 'package:equatable/equatable.dart';

import '../../domain/exceptions/profile_exception.dart';

enum ProfileActionStatus { idle, saving, failure }

/// Lifecycle of in-flight profile edits (saving/failure).
///
/// Deliberately not a second profile data store: the profile itself is
/// always read from `userProfileProvider` (the Firestore stream).
class ProfileActionsState extends Equatable {
  const ProfileActionsState({
    this.status = ProfileActionStatus.idle,
    this.error,
  });

  final ProfileActionStatus status;

  /// Non-null when [status] is [ProfileActionStatus.failure].
  final ProfileException? error;

  @override
  List<Object?> get props => [status, error];
}
