import 'dart:convert';

import 'package:http/http.dart' as http;

import '../catalog/catalog_models.dart';
import '../catalog/customer_catalog_service.dart';
import '../config/app_config.dart';
import 'shopping_cart_models.dart';

/// Wishlist + panier (`guide_api.md`) pour les actions depuis le feed.
class CustomerShoppingService {
  CustomerShoppingService._();

  static final CustomerShoppingService instance = CustomerShoppingService._();

  String get _apiRoot {
    final base = AppConfig.apiBaseUrl.trim();
    if (base.isEmpty) {
      throw CatalogApiException('API_BASE_URL non configurée (dart-define).');
    }
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  Map<String, String> _headers(String accessToken, {bool jsonBody = false}) => {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        if (jsonBody) 'Content-Type': 'application/json',
      };

  Future<List<CatalogProduct>> getWishlist({required String accessToken}) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/wishlist');
    final resp = await http.get(uri, headers: _headers(accessToken));
    _throwIfError(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final raw = map['items'] as List<dynamic>? ?? const [];
    return raw.map((e) => CatalogProduct.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addWishlistItem({
    required String accessToken,
    required String organizationArticleId,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/wishlist/items');
    final resp = await http.post(
      uri,
      headers: _headers(accessToken, jsonBody: true),
      body: jsonEncode(<String, String>{'organization_article_id': organizationArticleId}),
    );
    if (resp.statusCode >= 400) {
      throw CatalogApiException(
        resp.body.isNotEmpty ? resp.body : 'Erreur HTTP ${resp.statusCode}',
        statusCode: resp.statusCode,
      );
    }
  }

  Future<void> removeWishlistItem({
    required String accessToken,
    required String organizationArticleId,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/wishlist/items/$organizationArticleId');
    final resp = await http.delete(uri, headers: _headers(accessToken));
    if (resp.statusCode >= 400) {
      throw CatalogApiException(
        resp.body.isNotEmpty ? resp.body : 'Erreur HTTP ${resp.statusCode}',
        statusCode: resp.statusCode,
      );
    }
  }

  Future<void> addCartLine({
    required String accessToken,
    required String organizationArticleId,
    int quantity = 1,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/carts/items');
    final resp = await http.post(
      uri,
      headers: _headers(accessToken, jsonBody: true),
      body: jsonEncode(<String, dynamic>{
        'organization_article_id': organizationArticleId,
        'quantity': quantity,
      }),
    );
    if (resp.statusCode >= 400) {
      throw CatalogApiException(
        resp.body.isNotEmpty ? resp.body : 'Erreur HTTP ${resp.statusCode}',
        statusCode: resp.statusCode,
      );
    }
  }

  /// `GET /api/v1/customers/carts` — paniers groupés par organisation.
  Future<List<CustomerCart>> getCarts({required String accessToken}) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/carts');
    final resp = await http.get(uri, headers: _headers(accessToken));
    _throwIfError(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final raw = map['carts'] as List<dynamic>? ?? const [];
    return raw.map((e) => CustomerCart.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `PATCH /api/v1/customers/carts/items/{line_id}` — quantity 1 … 99999.
  Future<void> updateCartLineQuantity({
    required String accessToken,
    required String lineId,
    required int quantity,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/carts/items/$lineId');
    final resp = await http.patch(
      uri,
      headers: _headers(accessToken, jsonBody: true),
      body: jsonEncode(<String, dynamic>{'quantity': quantity}),
    );
    if (resp.statusCode >= 400) {
      throw CatalogApiException(
        resp.body.isNotEmpty ? resp.body : 'Erreur HTTP ${resp.statusCode}',
        statusCode: resp.statusCode,
      );
    }
  }

  /// `DELETE /api/v1/customers/carts/items/{line_id}`.
  Future<void> deleteCartLine({
    required String accessToken,
    required String lineId,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/carts/items/$lineId');
    final resp = await http.delete(uri, headers: _headers(accessToken));
    if (resp.statusCode >= 400) {
      throw CatalogApiException(
        resp.body.isNotEmpty ? resp.body : 'Erreur HTTP ${resp.statusCode}',
        statusCode: resp.statusCode,
      );
    }
  }

  /// `DELETE /api/v1/customers/carts/{cart_id}` — vide le panier pour une organisation.
  Future<void> deleteCart({
    required String accessToken,
    required String cartId,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/carts/$cartId');
    final resp = await http.delete(uri, headers: _headers(accessToken));
    if (resp.statusCode >= 400) {
      throw CatalogApiException(
        resp.body.isNotEmpty ? resp.body : 'Erreur HTTP ${resp.statusCode}',
        statusCode: resp.statusCode,
      );
    }
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
