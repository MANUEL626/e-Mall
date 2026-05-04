import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Upload d’avatar vers Supabase Storage, puis URL publique pour `profilepicture` (API).
///
/// Prérequis Supabase :
/// - Bucket existant (nom par défaut `avatars`, surcharge via `--dart-define=PROFILE_PHOTO_BUCKET=...`).
/// - Bucket **public** pour que `getPublicUrl` soit utilisable par ton API / l’app, **ou** adapter avec URL signée.
/// - Politiques Storage : `INSERT` pour `authenticated` sur `avatars/{user_id}/...` (voir doc Supabase).
class ProfilePhotoStorage {
  ProfilePhotoStorage._();

  static String _contentTypeForBytes(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50) {
      return 'image/png';
    }
    if (bytes.length >= 6 && bytes[0] == 0x47 && bytes[1] == 0x49) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  static String _extensionForContentType(String ct) {
    if (ct == 'image/png') return 'png';
    if (ct == 'image/gif') return 'gif';
    return 'jpg';
  }

  /// Retourne l’URL publique du fichier uploadé.
  static Future<String> uploadProfilePhoto(Uint8List bytes) async {
    final bucket = AppConfig.profilePhotoBucket.trim();
    if (bucket.isEmpty) {
      throw Exception('PROFILE_PHOTO_BUCKET non défini.');
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté.');
    }
    final ct = _contentTypeForBytes(bytes);
    final ext = _extensionForContentType(ct);
    final path =
        '${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await Supabase.instance.client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: ct,
            upsert: true,
          ),
        );

    return Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
  }
}
