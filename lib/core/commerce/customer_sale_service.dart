import 'dart:convert';

import 'package:http/http.dart' as http;

import '../catalog/customer_catalog_service.dart';
import '../config/app_config.dart';
import 'customer_sale_models.dart';

/// Ventes client — commandes, historique, params, confirmation QR (`guide_api.md`).
class CustomerSaleService {
  CustomerSaleService._();

  static final CustomerSaleService instance = CustomerSaleService._();

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

  /// Extrait un message lisible depuis une erreur JSON FastAPI (`detail`) ou renvoie le corps brut.
  static String _messageFromErrorBody(String body) {
    if (body.isEmpty) return body;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
        }
        final msg = decoded['message'];
        if (msg is String) return msg;
      }
    } catch (_) {}
    return body;
  }

  void _throwIfError(http.Response resp) {
    if (resp.statusCode >= 400) {
      final raw = resp.body.isNotEmpty ? resp.body : 'Erreur HTTP ${resp.statusCode}';
      throw CatalogApiException(
        _messageFromErrorBody(raw),
        statusCode: resp.statusCode,
      );
    }
  }

  /// `POST /api/v1/customer-sales` — réserve le stock ; statut initial typ. `pending`.
  Future<SaleOrderDetailOut> createSaleOrder({
    required String accessToken,
    required String organizationId,
    required SaleFulfillmentType fulfillmentType,
    required List<CreateSaleOrderLine> lines,
    double? deliveryLongitude,
    double? deliveryLatitude,
    String? notes,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customer-sales');
    final body = <String, dynamic>{
      'organization_id': organizationId,
      'fulfillment_type': fulfillmentType.apiValue,
      'lines': lines.map((e) => e.toJson()).toList(),
    };
    if (deliveryLongitude != null) body['delivery_longitude'] = deliveryLongitude;
    if (deliveryLatitude != null) body['delivery_latitude'] = deliveryLatitude;
    if (notes != null && notes.trim().isNotEmpty) body['notes'] = notes.trim();

    final resp = await http.post(
      uri,
      headers: _headers(accessToken, jsonBody: true),
      body: jsonEncode(body),
    );
    _throwIfError(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return SaleOrderDetailOut.fromJson(map);
  }

  /// `GET /api/v1/customer-sales` — filtres `bucket` / `status_group`.
  Future<SaleOrderListResult> listSaleOrders({
    required String accessToken,
    SaleOrderBucket? bucket,
    bool useStatusGroupParam = false,
    int? limit,
    int? offset,
  }) async {
    final qp = <String, String>{};
    if (bucket != null) {
      final key = useStatusGroupParam ? 'status_group' : 'bucket';
      qp[key] = bucket.apiValue;
    }
    if (limit != null) qp['limit'] = '$limit';
    if (offset != null) qp['offset'] = '$offset';

    final uri = Uri.parse('$_apiRoot/api/v1/customer-sales').replace(queryParameters: qp);
    final resp = await http.get(uri, headers: _headers(accessToken));
    _throwIfError(resp);
    final decoded = jsonDecode(resp.body);
    if (decoded is List<dynamic>) {
      return SaleOrderListResult(
        items: decoded
            .map((e) => SaleOrderDetailOut.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    if (decoded is Map<String, dynamic>) {
      return SaleOrderListResult.fromJson(decoded);
    }
    return SaleOrderListResult(items: []);
  }

  /// `GET /api/v1/customer-sales/{order_id}`.
  Future<SaleOrderDetailOut> getSaleOrder({
    required String accessToken,
    required String orderId,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customer-sales/$orderId');
    final resp = await http.get(uri, headers: _headers(accessToken));
    _throwIfError(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return SaleOrderDetailOut.fromJson(map);
  }

  /// `GET /api/v1/customer-sales/{order_id}/history`.
  Future<List<SaleOrderHistoryEntry>> getSaleOrderHistory({
    required String accessToken,
    required String orderId,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customer-sales/$orderId/history');
    final resp = await http.get(uri, headers: _headers(accessToken));
    _throwIfError(resp);
    final decoded = jsonDecode(resp.body);
    List<dynamic> list;
    if (decoded is List<dynamic>) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['items'] is List<dynamic>) {
      list = decoded['items'] as List<dynamic>;
    } else {
      list = const [];
    }
    return list
        .map((e) => SaleOrderHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /api/v1/customer-sales/{order_id}/confirm-receipt` — secret issu du QR.
  Future<SaleOrderDetailOut?> confirmReceipt({
    required String accessToken,
    required String orderId,
    required String secret,
    String? note,
  }) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customer-sales/$orderId/confirm-receipt');
    final body = <String, dynamic>{'secret': secret};
    if (note != null && note.trim().isNotEmpty) body['note'] = note.trim();

    final resp = await http.post(
      uri,
      headers: _headers(accessToken, jsonBody: true),
      body: jsonEncode(body),
    );
    _throwIfError(resp);
    if (resp.body.isEmpty) return null;
    final map = jsonDecode(resp.body);
    if (map is! Map<String, dynamic>) return null;
    return SaleOrderDetailOut.fromJson(map);
  }

  /// `GET /api/v1/customers/me/params`.
  Future<CustomerMeParams> getMyParams({required String accessToken}) async {
    final uri = Uri.parse('$_apiRoot/api/v1/customers/me/params');
    final resp = await http.get(uri, headers: _headers(accessToken));
    _throwIfError(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return CustomerMeParams.fromJson(map);
  }

  /// `PATCH /api/v1/customers/me/params` — au moins un champ (comme le guide).
  Future<CustomerMeParams> patchMyParams({
    required String accessToken,
    String? locale,
    double? defaultLongitude,
    double? defaultLatitude,
    Map<String, dynamic>? extra,
  }) async {
    final patch = CustomerMeParams.patchBody(
      locale: locale,
      defaultLongitude: defaultLongitude,
      defaultLatitude: defaultLatitude,
      extra: extra,
    );
    if (patch.isEmpty) {
      throw CatalogApiException('PATCH me/params : aucun champ à envoyer.');
    }

    final uri = Uri.parse('$_apiRoot/api/v1/customers/me/params');
    final resp = await http.patch(
      uri,
      headers: _headers(accessToken, jsonBody: true),
      body: jsonEncode(patch),
    );
    _throwIfError(resp);
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return CustomerMeParams.fromJson(map);
  }

  /// Après scan : vérifie optionnellement l’`orderId` attendu puis confirme.
  Future<SaleOrderDetailOut?> confirmReceiptFromQrScan({
    required String accessToken,
    required String scannedRaw,
    String? expectedOrderId,
    String? note,
  }) async {
    final payload = SaleQrPayload.tryParse(scannedRaw);
    if (payload == null) {
      throw CatalogApiException(
        'QR invalide : impossible d’extraire order_id et secret du texte scanné. '
        'Formats attendus : emall:order:<order_id>:<secret>, JSON '
        '{"order_id","secret"}, ou lien ?order_id=…&secret=… (voir guide_api.md).',
      );
    }
    if (expectedOrderId != null && expectedOrderId.isNotEmpty && payload.orderId != expectedOrderId) {
      throw CatalogApiException('Ce QR ne correspond pas à cette commande.');
    }
    return confirmReceipt(
      accessToken: accessToken,
      orderId: payload.orderId,
      secret: payload.secret,
      note: note,
    );
  }
}
