/// Configuration lue au build via `--dart-define`.
///
/// Exemple :
/// `flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ... --dart-define=API_BASE_URL=https://api.example.com`
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Base HTTPS publique utilisée pour les liens partageables.
  /// Elle doit pointer vers une page/route web qui ouvre l'app ou redirige vers l'accueil.
  static const String shareBaseUrl = String.fromEnvironment(
    'SHARE_BASE_URL',
    defaultValue: apiBaseUrl,
  );

  /// Bucket Supabase Storage pour les photos de profil (`upload` + URL dans `profilepicture`).
  /// Créer le bucket dans le dashboard et le rendre public si tu utilises `getPublicUrl`.
  static const String profilePhotoBucket = String.fromEnvironment(
    'PROFILE_PHOTO_BUCKET',
    defaultValue: 'avatars',
  );

  /// Bucket des images catalogue (`primary_image_storage_path`, guide : `organization-articles`).
  static const String articleCatalogBucket = String.fromEnvironment(
    'ARTICLE_CATALOG_BUCKET',
    defaultValue: 'organization-articles',
  );

  /// Bucket des médias posts promo (`media_storage_path`, guide : `organization-article-posts`).
  static const String articlePostBucket = String.fromEnvironment(
    'ARTICLE_POST_BUCKET',
    defaultValue: 'organization-article-posts',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isApiConfigured => apiBaseUrl.isNotEmpty;
}
