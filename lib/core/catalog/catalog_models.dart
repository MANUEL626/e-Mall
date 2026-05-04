/// Modèles alignés sur `guide_api.md` — réponses `GET /api/v1/customers/products*`.
class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.name,
    required this.category,
    required this.unitSalePrice,
    required this.stockStatus,
    this.primaryImageStoragePath,
    this.additionalImageStoragePaths = const [],
    this.description,
  });

  final String id;
  final String organizationId;
  final String organizationName;
  final String name;
  final String category;
  final String unitSalePrice;
  final String stockStatus;
  final String? primaryImageStoragePath;
  final List<String> additionalImageStoragePaths;
  final String? description;

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      id: json['id'] as String? ?? '',
      organizationId: json['organization_id'] as String? ?? '',
      organizationName: json['organization_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      unitSalePrice: json['unit_sale_price']?.toString() ?? '0',
      stockStatus: json['stock_status'] as String? ?? 'out_of_stock',
      primaryImageStoragePath: json['primary_image_storage_path'] as String?,
      additionalImageStoragePaths: (json['additional_image_storage_paths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      description: json['description'] as String?,
    );
  }
}

class CatalogPage {
  const CatalogPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<CatalogProduct> items;
  final int total;
  final int limit;
  final int offset;

  factory CatalogPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return CatalogPage(
      items: raw
          .map((e) => CatalogProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Catégories documentées par l’API (`GET .../products` / `filter`).
const List<(String, String)> kCatalogCategoryOptions = [
  ('electronics', 'Électronique'),
  ('appliances', 'Électroménager'),
  ('clothing', 'Vêtements'),
  ('food', 'Alimentation'),
  ('beauty', 'Beauté'),
  ('sports', 'Sport'),
  ('home', 'Maison'),
  ('other', 'Autre'),
];

String catalogCategoryLabel(String slug) {
  for (final e in kCatalogCategoryOptions) {
    if (e.$1 == slug) return e.$2;
  }
  return slug;
}
