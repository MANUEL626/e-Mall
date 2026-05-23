import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

bool _isAbsoluteHttpUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

/// Construit l'URL publique Storage pour `primary_image_storage_path`
/// (guide : bucket `organization-articles`).
String? publicUrlForCatalogImage(String? storagePath) {
  final path = storagePath?.trim();
  if (path == null || path.isEmpty) return null;
  if (_isAbsoluteHttpUrl(path)) return path;
  if (!AppConfig.isSupabaseConfigured) return null;
  return Supabase.instance.client.storage
      .from(AppConfig.articleCatalogBucket)
      .getPublicUrl(path);
}

/// URL publique pour `media_storage_path`
/// (guide : bucket `organization-article-posts`).
String? publicUrlForPostMedia(String? storagePath) {
  final path = storagePath?.trim();
  if (path == null || path.isEmpty) return null;
  if (_isAbsoluteHttpUrl(path)) return path;
  if (!AppConfig.isSupabaseConfigured) return null;
  return Supabase.instance.client.storage
      .from(AppConfig.articlePostBucket)
      .getPublicUrl(path);
}
