/// Supabase project configuration.
///
/// Used only for Supabase Storage (profile photos). Authentication and
/// application data remain on Firebase.
///
/// Fill these from the Supabase dashboard: Project Settings → API Keys.
/// The publishable key is a client key (safe to ship); access control is
/// enforced by bucket policies, not by the key.
abstract final class SupabaseConfig {
  static const String url = 'https://ybjiylkjkskijurbciwl.supabase.co';

  static const String publishableKey =
      'sb_publishable_MIiKkM1DJ_50g2AySqM4AA_5gYO39zr';
}
