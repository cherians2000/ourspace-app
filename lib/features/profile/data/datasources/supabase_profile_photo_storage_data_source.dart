import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_photo_storage_data_source.dart';

/// Supabase Storage-backed [ProfilePhotoStorageDataSource].
///
/// Photos live in the `profile_photos` bucket at the fixed object path
/// `{uid}.jpg`: every upload upserts over the previous object, so no
/// orphan files accumulate.
///
/// IMPORTANT: `profile_photos` is intentionally a PUBLIC bucket. Avatars
/// are served through the plain public URLs returned by `getPublicUrl`,
/// which only work on public buckets. The bucket must remain public
/// unless the app is migrated to signed URLs (in which case this data
/// source is the single place to change).
class SupabaseProfilePhotoStorageDataSource
    implements ProfilePhotoStorageDataSource {
  SupabaseProfilePhotoStorageDataSource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _bucket = 'profile_photos';

  String _objectPath(String uid) => '$uid.jpg';

  @override
  Future<String> uploadProfilePhoto({
    required String uid,
    required String filePath,
  }) async {
    final objectPath = _objectPath(uid);
    final storage = _client.storage.from(_bucket);

    await storage.upload(
      objectPath,
      File(filePath),
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true, // Overwrite the previous photo in place.
      ),
    );

    // The public URL is stable across overwrites, and public objects are
    // served through Supabase's CDN. The version query parameter busts
    // both the device image cache and the CDN edge cache, so every
    // upload is immediately visible.
    final publicUrl = storage.getPublicUrl(objectPath);
    final version = DateTime.now().millisecondsSinceEpoch;
    return '$publicUrl?v=$version';
  }

  @override
  Future<void> deleteProfilePhoto({required String uid}) async {
    await _client.storage.from(_bucket).remove([_objectPath(uid)]);
  }
}
