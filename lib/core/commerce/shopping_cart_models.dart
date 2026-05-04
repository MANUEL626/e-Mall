import '../catalog/catalog_models.dart';

/// Ligne `GET .../customers/carts` (`guide_api.md`).
class CartLine {
  const CartLine({
    required this.lineId,
    required this.quantity,
    required this.product,
  });

  final String lineId;
  final int quantity;
  final CatalogProduct product;

  factory CartLine.fromJson(Map<String, dynamic> json) {
    final productRaw = json['product'];
    if (productRaw is! Map<String, dynamic>) {
      throw FormatException('Cart line sans product valide');
    }
    return CartLine(
      lineId: json['line_id'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      product: CatalogProduct.fromJson(productRaw),
    );
  }
}

/// Un panier par organisation marchande.
class CustomerCart {
  const CustomerCart({
    required this.cartId,
    required this.organizationId,
    required this.organizationName,
    required this.items,
    this.updatedAt,
  });

  final String cartId;
  final String organizationId;
  final String organizationName;
  final String? updatedAt;
  final List<CartLine> items;

  factory CustomerCart.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return CustomerCart(
      cartId: json['cart_id'] as String? ?? '',
      organizationId: json['organization_id'] as String? ?? '',
      organizationName: json['organization_name'] as String? ?? '',
      updatedAt: json['updated_at']?.toString(),
      items: rawItems
          .map((e) => CartLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Prix unitaire catalogue (`unit_sale_price` texte API).
double parseCatalogUnitPrice(String raw) => double.tryParse(raw.trim()) ?? 0;

/// Somme des quantités × prix pour un panier.
double subtotalForCart(CustomerCart cart) {
  var sum = 0.0;
  for (final line in cart.items) {
    sum += parseCatalogUnitPrice(line.product.unitSalePrice) * line.quantity;
  }
  return sum;
}

/// Quantité totale de pièces dans le panier.
int totalPiecesInCart(CustomerCart cart) {
  return cart.items.fold<int>(0, (sum, line) => sum + line.quantity);
}
