import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Construit l’URL publique Storage pour `primary_image_storage_path` (guide : bucket `organization-articles`).
String? publicUrlForCatalogImage(String? storagePath) {
  if (storagePath == null || storagePath.isEmpty) return null;
  if (!AppConfig.isSupabaseConfigured) return null;
  return Supabase.instance.client.storage
      .from(AppConfig.articleCatalogBucket)
      .getPublicUrl(storagePath);
}

/// URL publique pour `media_storage_path` (bucket `organization-article-posts`).
String? publicUrlForPostMedia(String? storagePath) {
  if (storagePath == null || storagePath.isEmpty) return null;
  if (!AppConfig.isSupabaseConfigured) return null;
  return Supabase.instance.client.storage
      .from(AppConfig.articlePostBucket)
      .getPublicUrl(storagePath);
}
