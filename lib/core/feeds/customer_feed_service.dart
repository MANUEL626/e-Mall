import 'dart:convert';

import 'package:http/http.dart' as http;

import '../catalog/customer_catalog_service.dart';
import '../config/app_config.dart';
import 'article_post_feed_models.dart';

/// `GET /api/v1/customers/posts/feed` — JWT Supabase requis.
class CustomerFeedService {
  CustomerFeedService._();

  static final CustomerFeedService instance = CustomerFeedService._();

  String get _apiRoot {
    final base = AppConfig.apiBaseUrl.trim();
    if (base.isEmpty) {
      throw CatalogApiException('API_BASE_URL non configurée (dart-define).');
    }
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  Map<String, String> _headers(String accessToken) => {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      };

  Future<PostFeedPage> postsFeed({
    required String accessToken,
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/posts/feed').replace(
      queryParameters: <String, String>{
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final resp = await http.get(uri, headers: _headers(accessToken));
    _throwIfError(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return PostFeedPage.fromJson(map);
  }

  void _throwIfError(http.Response resp) {
    if (resp.statusCode >= 400) {
      throw CatalogApiException(
        resp.body.isNotEmpty ? resp.body : 'Erreur HTTP ${resp.statusCode}',
        statusCode: resp.statusCode,
      );
    }
  }
}
