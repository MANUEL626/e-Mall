import 'dart:convert';

import 'package:http/http.dart' as http;

import '../catalog/customer_catalog_service.dart';
import '../config/app_config.dart';
import 'organization_models.dart';

/// Organisations + abonnements customer (`guide_api.md`).
class CustomerOrganizationService {
  CustomerOrganizationService._();

  static final CustomerOrganizationService instance = CustomerOrganizationService._();

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

  Future<OrganizationPreview> getOrganization({
    required String accessToken,
    required String organizationId,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/organizations/$organizationId');
    final resp = await http.get(uri, headers: _headers(accessToken));
    _throwIfError(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return OrganizationPreview.fromJson(map);
  }

  Future<CustomerSubscriptionsPage> listSubscriptions({required String accessToken}) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/subscriptions');
    final resp = await http.get(uri, headers: _headers(accessToken));
    _throwIfError(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return CustomerSubscriptionsPage.fromJson(map);
  }

  Future<void> subscribe({
    required String accessToken,
    required String organizationId,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/subscriptions');
    final resp = await http.post(
      uri,
      headers: _headers(accessToken, jsonBody: true),
      body: jsonEncode(<String, String>{'organization_id': organizationId}),
    );
    _throwIfError(resp);
  }

  Future<void> unsubscribe({
    required String accessToken,
    required String organizationId,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/subscriptions/$organizationId');
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
