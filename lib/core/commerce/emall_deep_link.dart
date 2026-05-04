/// Liens personnalisés **option B** : schéma `emall` (Android / iOS + Flutter).
///
/// - QR « opaque » : `emall:order:<order_id>:<secret>` (inchangé pour [SaleQrPayload]).
/// - Lien cliquable / OS : `emall://order/<order_id>/<secret>` (host `order`, path en segments).
class EmallDeepLink {
  EmallDeepLink._();

  /// Normalise une [Uri] reçue via `app_links` vers la ligne attendue par [SaleQrPayload.tryParse].
  static String normalizeToQrPayload(Uri uri) {
    if (uri.scheme.toLowerCase() != 'emall') {
      return uri.toString().trim();
    }
    final host = uri.host.toLowerCase();
    if (host == 'order' && uri.pathSegments.length >= 2) {
      final id = uri.pathSegments.first;
      final secret = uri.pathSegments.sublist(1).join('/');
      return 'emall:order:$id:$secret';
    }
    return uri.toString().trim();
  }
}
