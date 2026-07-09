import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/exceptions/profile_exception.dart';
import '../providers/profile_actions_state.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_avatar.dart';

/// Actions available from the profile photo bottom sheet.
enum _PhotoAction { view, gallery, camera, remove }

/// User-facing copy for profile failures (UI concern, so it lives here).
extension _ProfileErrorMessage on ProfileException {
  String get userMessage {
    return switch (reason) {
      ProfileErrorReason.invalidInput =>
        'Please enter a name (up to 50 characters).',
      ProfileErrorReason.permissionDenied =>
        "You don't have permission to make this change.",
      ProfileErrorReason.network =>
        'Connection trouble. Check your network and try again.',
      ProfileErrorReason.misconfigured =>
        "Photo storage isn't set up for this app yet.",
      ProfileErrorReason.requiresRecentLogin =>
        'For security, deleting your account needs a fresh login.',
      ProfileErrorReason.reauthenticationFailed =>
        "That password doesn't match. Please try again.",
      // Handled silently by the notifier; present for exhaustiveness.
      ProfileErrorReason.cancelled => 'Cancelled.',
      ProfileErrorReason.unknown =>
        'Something went wrong. Please try again.',
    };
  }
}

/// The current user's profile: photo and display name are editable,
/// email is read-only. All profile data is read from
/// `userProfileProvider`; this page never caches its own copy.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();

  /// Which profile the controller was last seeded from, so stream echoes
  /// don't clobber in-progress typing.
  String? _seededUid;

  bool _uploadingPhoto = false;
  bool _deletingAccount = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    // A stale failure from a previous visit must not greet the user.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(profileActionsProvider.notifier).clearError(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _seedController(UserProfile profile) {
    if (_seededUid == profile.uid) return;
    _seededUid = profile.uid;
    _nameController.text = profile.displayName ?? '';
  }

  Future<void> _saveName(UserProfile profile) async {
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(profileActionsProvider.notifier)
        .updateDisplayName(uid: profile.uid, displayName: _nameController.text);
    if (!mounted) return;
    if (saved) {
      // Rebuild the save-button state against the new canonical value.
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated')),
      );
    }
  }

  Object _heroTag(UserProfile profile) => 'profile-photo-${profile.uid}';

  /// Own-profile avatar tap: actions sheet. (Other users' profiles open
  /// the full-screen viewer directly, without a sheet.)
  Future<void> _onAvatarTap(UserProfile profile) async {
    final hasPhoto = profile.photoUrl != null;

    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('View photo'),
                onTap: () => Navigator.pop(context, _PhotoAction.view),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, _PhotoAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, _PhotoAction.camera),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.pop(context, _PhotoAction.remove),
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _PhotoAction.view:
        await FullScreenImageViewer.show(
          context,
          image: CachedNetworkImageProvider(profile.photoUrl!),
          heroTag: _heroTag(profile),
        );
      case _PhotoAction.gallery:
        await _pickAndUpload(profile, ImageSource.gallery);
      case _PhotoAction.camera:
        await _pickAndUpload(profile, ImageSource.camera);
      case _PhotoAction.remove:
        await _removePhoto(profile);
    }
  }

  Future<void> _pickAndUpload(UserProfile profile, ImageSource source) async {
    // Compression happens at pick time, before upload: bounded to
    // 720x720 (aspect ratio preserved) at ~80% JPEG quality. The upload
    // then overwrites the single `{uid}.jpg` object.
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    final saved = await ref
        .read(profileActionsProvider.notifier)
        .updateProfilePhoto(uid: profile.uid, photoPath: picked.path);
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated')),
      );
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _signingOut = true);
    // Existing sign-out pipeline (notifier → use case → repository); the
    // session stream then emits null and the router redirects to login.
    await ref.read(authNotifierProvider.notifier).signOut();
    if (mounted) setState(() => _signingOut = false);
  }

  Future<void> _confirmDeleteAccount(UserProfile profile) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => const _DeleteAccountDialog(),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    // First attempt. Google accounts re-authenticate inline if needed;
    // email accounts fail fast (before any data is touched) when a
    // fresh login is required.
    var deleted = await _attemptDelete(profile);
    if (deleted || !mounted) return;

    // Email + stale login: collect the password and retry. Nothing has
    // been deleted at this point.
    final error = ref.read(profileActionsProvider).error;
    if (error?.reason == ProfileErrorReason.requiresRecentLogin &&
        profile.provider == ProfileAuthProvider.email) {
      final password = await showDialog<String>(
        context: context,
        builder: (context) => const _ReauthPasswordDialog(),
      );
      if (password == null || !mounted) {
        ref.read(profileActionsProvider.notifier).clearError();
        return;
      }
      deleted = await _attemptDelete(profile, password: password);
    }
    // On success the session stream emits null and the router redirects
    // to login automatically. On failure the error banner explains why.
  }

  Future<bool> _attemptDelete(UserProfile profile, {String? password}) async {
    setState(() => _deletingAccount = true);
    final deleted = await ref.read(profileActionsProvider.notifier).deleteAccount(
          uid: profile.uid,
          provider: profile.provider,
          password: password,
        );
    if (mounted) setState(() => _deletingAccount = false);
    return deleted;
  }

  Future<void> _removePhoto(UserProfile profile) async {
    final removed = await ref
        .read(profileActionsProvider.notifier)
        .removeProfilePhoto(uid: profile.uid);
    if (!mounted) return;
    if (removed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _buildLoadError(),
          // While deleting or signing out, the profile stream goes null
          // before the router redirects — show progress, not the
          // load-error state.
          data: (profile) => profile == null
              ? (_deletingAccount || _signingOut
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLoadError())
              : _buildProfile(profile),
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.textSecondary,
              size: AppIcons.lg,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Couldn't load your profile",
              style: AppTypography.title.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check your connection and try again.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => ref.invalidate(userProfileProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(UserProfile profile) {
    _seedController(profile);

    final actions = ref.watch(profileActionsProvider);
    final saving = actions.status == ProfileActionStatus.saving;
    final error =
        actions.status == ProfileActionStatus.failure ? actions.error : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ProfileAvatar(
                  photoUrl: profile.photoUrl,
                  displayName: profile.displayName ?? profile.email,
                  radius: 48,
                  uploading: _uploadingPhoto,
                  showEditBadge: true,
                  heroTag: _heroTag(profile),
                  onTap: saving ? null : () => _onAvatarTap(profile),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              if (error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Text(
                    error.userMessage,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              Text(
                'Display name',
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _nameController,
                enabled: !saving,
                maxLength: 50,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  // Editing dismisses the current error banner; setState
                  // refreshes the save button's dirty check.
                  ref.read(profileActionsProvider.notifier).clearError();
                  setState(() {});
                },
                onSubmitted: (_) => _saveName(profile),
                decoration: const InputDecoration(counterText: ''),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              Text(
                'Email',
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                initialValue: profile.email,
                enabled: false,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.lock_outline, size: AppIcons.sm),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Email can't be changed.",
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (profile.createdAt != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Member since '
                  '${DateFormat.yMMMM().format(profile.createdAt!)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sectionGap),
              ElevatedButton(
                onPressed: saving ||
                        _nameController.text.trim().isEmpty ||
                        _nameController.text.trim() ==
                            (profile.displayName ?? '')
                    ? null
                    : () => _saveName(profile),
                child: saving && !_uploadingPhoto && !_deletingAccount
                    ? const SizedBox(
                        width: AppIcons.sm,
                        height: AppIcons.sm,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              // Secondary action: quieter than the destructive delete
              // below it.
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                onPressed: saving || _signingOut ? null : _confirmSignOut,
                icon: _signingOut
                    ? const SizedBox(
                        width: AppIcons.sm,
                        height: AppIcons.sm,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout, size: AppIcons.sm),
                label: Text(_signingOut ? 'Signing out…' : 'Sign out'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.5),
                  ),
                ),
                onPressed: saving || _signingOut
                    ? null
                    : () => _confirmDeleteAccount(profile),
                icon: _deletingAccount
                    ? const SizedBox(
                        width: AppIcons.sm,
                        height: AppIcons.sm,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Icon(Icons.delete_forever_outlined,
                        size: AppIcons.sm),
                label: Text(
                  _deletingAccount ? 'Deleting account…' : 'Delete account',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Destructive confirmation: the final button stays disabled until the
/// user types DELETE, making accidental account deletion impossible.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const String _requiredText = 'DELETE';

  final _controller = TextEditingController();

  bool get _confirmed => _controller.text.trim() == _requiredText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete your account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This permanently deletes your account, your profile and '
            'your photo. This cannot be undone.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Type $_requiredText to confirm:',
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: _requiredText),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_confirmed) Navigator.pop(context, true);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          onPressed:
              _confirmed ? () => Navigator.pop(context, true) : null,
          child: const Text('Delete account'),
        ),
      ],
    );
  }
}

/// Collects the password for re-authentication before account deletion.
/// Pops with the entered password, or null when cancelled.
class _ReauthPasswordDialog extends StatefulWidget {
  const _ReauthPasswordDialog();

  @override
  State<_ReauthPasswordDialog> createState() => _ReauthPasswordDialogState();
}

class _ReauthPasswordDialogState extends State<_ReauthPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _controller.text;
    if (password.isNotEmpty) Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm your password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'For security, deleting your account requires your password.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(hintText: 'Password'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: _controller.text.isEmpty ? null : _submit,
          child: const Text('Delete account'),
        ),
      ],
    );
  }
}
