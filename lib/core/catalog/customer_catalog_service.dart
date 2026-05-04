import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'catalog_models.dart';

/// Appels catalogue customer (`guide_api.md`) — JWT Supabase requis.
class CustomerCatalogService {
  CustomerCatalogService._();

  static final CustomerCatalogService instance = CustomerCatalogService._();

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

  Future<CatalogPage> listProducts({
    required String accessToken,
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/products').replace(
      queryParameters: <String, String>{
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final resp = await http.get(uri, headers: _headers(accessToken));
    _throwIfError(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return CatalogPage.fromJson(map);
  }

  Future<CatalogPage> searchProducts({
    required String accessToken,
    required String q,
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/products/search').replace(
      queryParameters: <String, String>{
        'q': q,
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final resp = await http.get(uri, headers: _headers(accessToken));
    _throwIfError(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return CatalogPage.fromJson(map);
  }

  /// Au moins un parmi [name], [categories], [minPrice], [maxPrice] (sinon 422 côté API).
  Future<CatalogPage> filterProducts({
    required String accessToken,
    String? name,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
    int limit = 50,
    int offset = 0,
  }) async {
    final segments = <String>['limit=$limit', 'offset=$offset'];
    if (name != null && name.trim().isNotEmpty) {
      segments.add('name=${Uri.encodeQueryComponent(name.trim())}');
    }
    if (categories != null) {
      for (final c in categories) {
        if (c.isEmpty) continue;
        segments.add('category=${Uri.encodeQueryComponent(c)}');
      }
    }
    if (minPrice != null) {
      segments.add('min_price=${Uri.encodeQueryComponent(minPrice.toString())}');
    }
    if (maxPrice != null) {
      segments.add('max_price=${Uri.encodeQueryComponent(maxPrice.toString())}');
    }
    final uri = Uri.parse(
      '$_apiRoot/api/v1/customers/products/filter?${segments.join('&')}',
    );
    final resp = await http.get(uri, headers: _headers(accessToken));
    _throwIfError(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return CatalogPage.fromJson(map);
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

class CatalogApiException implements Exception {
  CatalogApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'CatalogApiException($statusCode): $message';
}
