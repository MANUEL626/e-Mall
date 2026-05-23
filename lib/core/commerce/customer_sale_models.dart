import 'dart:convert';

import '../catalog/catalog_models.dart';

/// `fulfillment_type` côté customer (`guide_api.md`) — pas `walk_in_offline`.
enum SaleFulfillmentType {
  pickup,
  delivery;

  String get apiValue => name;
}

/// Filtre `?bucket=` / `?status_group=` sur `GET /customer-sales`.
enum SaleOrderBucket {
  inProgress,
  inDelivery,
  cancelled,
  completed;

  String get apiValue {
    switch (this) {
      case SaleOrderBucket.inProgress:
        return 'in_progress';
      case SaleOrderBucket.inDelivery:
        return 'in_delivery';
      case SaleOrderBucket.cancelled:
        return 'cancelled';
      case SaleOrderBucket.completed:
        return 'completed';
    }
  }
}

/// Ligne envoyée à `POST /api/v1/customer-sales` (`article_id` dans le guide).
class CreateSaleOrderLine {
  const CreateSaleOrderLine({
    required this.articleId,
    required this.quantity,
  });

  final String articleId;
  final int quantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'article_id': articleId,
        'quantity': quantity,
      };
}

/// Paramètres `GET` / `PATCH /api/v1/customers/me/params`.
class CustomerMeParams {
  const CustomerMeParams({
    this.locale,
    this.defaultLongitude,
    this.defaultLatitude,
    this.country,
    this.interests = const [],
    this.extra,
  });

  final String? locale;
  final double? defaultLongitude;
  final double? defaultLatitude;
  final String? country;
  final List<String> interests;
  final Map<String, dynamic>? extra;

  factory CustomerMeParams.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? extraMap;
    final rawExtra = json['extra'];
    if (rawExtra is Map<String, dynamic>) {
      extraMap = rawExtra;
    } else if (rawExtra is Map) {
      extraMap = rawExtra.map((k, v) => MapEntry(k.toString(), v));
    }

    return CustomerMeParams(
      locale: json['locale'] as String?,
      defaultLongitude: (json['default_longitude'] as num?)?.toDouble(),
      defaultLatitude: (json['default_latitude'] as num?)?.toDouble(),
      country: json['country'] as String?,
      interests: (json['interests'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      extra: extraMap,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'locale': locale,
        'default_longitude': defaultLongitude,
        'default_latitude': defaultLatitude,
        'country': country,
        'interests': interests,
        'extra': extra,
      };

  static Map<String, dynamic> patchBody({
    String? locale,
    double? defaultLongitude,
    double? defaultLatitude,
    String? country,
    List<String>? interests,
    Map<String, dynamic>? extra,
  }) {
    final out = <String, dynamic>{};
    if (locale != null) out['locale'] = locale;
    if (defaultLongitude != null) out['default_longitude'] = defaultLongitude;
    if (defaultLatitude != null) out['default_latitude'] = defaultLatitude;
    if (country != null) out['country'] = country;
    if (interests != null) out['interests'] = interests;
    if (extra != null) out['extra'] = extra;
    return out;
  }
}

/// Commande (champs courants + tolérance aux champs additionnels serveur).
class SaleOrderOut {
  const SaleOrderOut({
    required this.id,
    required this.status,
    this.organizationId,
    this.organizationName,
    this.fulfillmentType,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.raw,
  });

  final String id;
  final String status;
  final String? organizationId;
  final String? organizationName;
  final String? fulfillmentType;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? raw;

  factory SaleOrderOut.fromJson(Map<String, dynamic> json) {
    return SaleOrderOut(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      organizationId: json['organization_id'] as String?,
      organizationName: json['organization_name'] as String?,
      fulfillmentType: json['fulfillment_type'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      raw: json,
    );
  }
}

/// Ligne commande côté réponse (`lines` dans `SaleOrderDetailOut`).
class SaleOrderLine {
  const SaleOrderLine({
    required this.quantity,
    this.articleId,
    this.lineId,
    this.product,
    this.raw,
  });

  final int quantity;
  final String? articleId;
  final String? lineId;
  final CatalogProduct? product;
  final Map<String, dynamic>? raw;

  factory SaleOrderLine.fromJson(Map<String, dynamic> json) {
    CatalogProduct? product;
    final p = json['product'];
    if (p is Map<String, dynamic>) {
      product = CatalogProduct.fromJson(p);
    }
    return SaleOrderLine(
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      articleId: json['article_id'] as String? ?? json['organization_article_id'] as String?,
      lineId: json['line_id'] as String?,
      product: product,
      raw: json,
    );
  }
}

/// Réponse `SaleOrderDetailOut` : `order` + `lines` (schéma guide).
class SaleOrderDetailOut {
  const SaleOrderDetailOut({
    required this.order,
    required this.lines,
  });

  final SaleOrderOut order;
  final List<SaleOrderLine> lines;

  factory SaleOrderDetailOut.fromJson(Map<String, dynamic> json) {
    final orderMap = json['order'];
    Map<String, dynamic> orderJson;
    List<dynamic> linesRaw;

    if (orderMap is Map<String, dynamic>) {
      orderJson = orderMap;
      linesRaw = json['lines'] as List<dynamic>? ?? const [];
    } else {
      orderJson = Map<String, dynamic>.from(json)
        ..remove('lines')
        ..remove('items');
      linesRaw = json['lines'] as List<dynamic>? ?? const [];
    }

    return SaleOrderDetailOut(
      order: SaleOrderOut.fromJson(orderJson),
      lines: linesRaw
          .map((e) => SaleOrderLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Liste `GET /api/v1/customer-sales` — enveloppe tolérante (`items` ou liste racine).
class SaleOrderListResult {
  SaleOrderListResult({
    required this.items,
    this.total,
    this.limit,
    this.offset,
  });

  final List<SaleOrderDetailOut> items;
  final int? total;
  final int? limit;
  final int? offset;

  factory SaleOrderListResult.fromJson(Map<String, dynamic> json) {
    List<dynamic> raw;
    if (json['items'] is List<dynamic>) {
      raw = json['items'] as List<dynamic>;
    } else if (json['orders'] is List<dynamic>) {
      raw = json['orders'] as List<dynamic>;
    } else if (json['results'] is List<dynamic>) {
      raw = json['results'] as List<dynamic>;
    } else if (json['data'] is List<dynamic>) {
      raw = json['data'] as List<dynamic>;
    } else if (json['data'] is Map<String, dynamic>) {
      final d = json['data'] as Map<String, dynamic>;
      raw = (d['items'] as List<dynamic>?) ??
          (d['orders'] as List<dynamic>?) ??
          (d['results'] as List<dynamic>?) ??
          const [];
    } else {
      raw = const [];
    }

    return SaleOrderListResult(
      items: raw
          .map((e) => SaleOrderDetailOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
    );
  }
}

/// Entrée `GET .../customer-sales/{order_id}/history`.
class SaleOrderHistoryEntry {
  const SaleOrderHistoryEntry({
    this.fromStatus,
    this.toStatus,
    this.note,
    this.at,
    this.raw,
  });

  final String? fromStatus;
  final String? toStatus;
  final String? note;
  final String? at;
  final Map<String, dynamic>? raw;

  factory SaleOrderHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SaleOrderHistoryEntry(
      fromStatus: json['from_status'] as String? ?? json['from'] as String?,
      toStatus: json['to_status'] as String? ?? json['to'] as String?,
      note: json['note'] as String?,
      at: json['created_at']?.toString() ??
          json['at']?.toString() ??
          json['occurred_at']?.toString(),
      raw: json,
    );
  }
}

/// Payload attendu après scan QR (`order_id` + `secret`) pour `confirm-receipt`.
class SaleQrPayload {
  const SaleQrPayload({
    required this.orderId,
    required this.secret,
  });

  final String orderId;
  final String secret;

  /// Formats reconnus :
  /// - schéma app : `emall:order:<order_id>:<secret>` (QR production courant) ;
  /// - JSON `{ "order_id", "secret" }` (alias de clés tolérés) ;
  /// - URL ou query `order_id=…&secret=…`.
  static SaleQrPayload? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // emall:order:<uuid>:<secret> — le secret peut contenir « : », tout après le 3ᵉ segment est le secret.
    final emallParts = trimmed.split(':');
    if (emallParts.length >= 4 &&
        emallParts[0].toLowerCase() == 'emall' &&
        emallParts[1].toLowerCase() == 'order') {
      final id = emallParts[2].trim();
      final sec = emallParts.sublist(3).join(':').trim();
      if (id.isNotEmpty && sec.isNotEmpty) {
        return SaleQrPayload(orderId: id, secret: sec);
      }
    }

    String? nonEmptyString(Object? v) {
      if (v == null) return null;
      final s = v is String ? v.trim() : v.toString().trim();
      return s.isEmpty ? null : s;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final id = nonEmptyString(
          decoded['order_id'] ?? decoded['orderId'] ?? decoded['sale_order_id'],
        );
        final sec = nonEmptyString(
          decoded['secret'] ?? decoded['token'] ?? decoded['receipt_secret'],
        );
        if (id != null && sec != null) {
          return SaleQrPayload(orderId: id, secret: sec);
        }
      }
    } catch (_) {
      // pas du JSON
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.hasQuery || uri.queryParameters.isNotEmpty)) {
      final id = nonEmptyString(
        uri.queryParameters['order_id'] ??
            uri.queryParameters['orderId'] ??
            uri.queryParameters['sale_order_id'],
      );
      final sec = nonEmptyString(
        uri.queryParameters['secret'] ??
            uri.queryParameters['token'] ??
            uri.queryParameters['receipt_secret'],
      );
      if (id != null && sec != null) {
        return SaleQrPayload(orderId: id, secret: sec);
      }
    }

    if (trimmed.contains('=') && (trimmed.contains('secret') || trimmed.contains('token'))) {
      final qp = Uri.splitQueryString(trimmed);
      final id = nonEmptyString(qp['order_id'] ?? qp['orderId'] ?? qp['sale_order_id']);
      final sec = nonEmptyString(qp['secret'] ?? qp['token'] ?? qp['receipt_secret']);
      if (id != null && sec != null) {
        return SaleQrPayload(orderId: id, secret: sec);
      }
    }

    return null;
  }
}
