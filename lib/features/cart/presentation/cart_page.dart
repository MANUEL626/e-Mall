import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/catalog/customer_catalog_service.dart';
import '../../../core/catalog/product_image_url.dart';
import '../../../core/commerce/customer_shopping_service.dart';
import '../../../core/commerce/shopping_cart_models.dart';
import '../../../core/config/app_config.dart';
import 'cart_detail_page.dart';

/// Liste des paniers par boutique (`GET /api/v1/customers/carts`).
/// Un tap ouvre les articles dans [CartDetailPage].
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CustomerCart>? _carts;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AppConfig.isApiConfigured) {
      setState(() {
        _loading = false;
        _error = 'API_BASE_URL non configurée (dart-define).';
        _carts = null;
      });
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        _loading = false;
        _error = 'Connectez-vous pour voir votre panier.';
        _carts = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final carts = await CustomerShoppingService.instance.getCarts(accessToken: session.accessToken);
      if (!mounted) return;
      setState(() {
        _carts = carts;
        _loading = false;
        _error = null;
      });
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
        _carts = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _carts = null;
      });
    }
  }

  double _grandTotal(List<CustomerCart> carts) {
    var sum = 0.0;
    for (final c in carts) {
      sum += subtotalForCart(c);
    }
    return sum;
  }

  Future<void> _openCartDetail(CustomerCart cart) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CartDetailPage(initialCart: cart),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paniers'),
        actions: [
          if (_carts != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _load,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _carts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(_error!, style: const TextStyle(color: Color(0xFF6A4A35))),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Réessayer')),
        ],
      );
    }

    final carts = _carts ?? [];
    if (carts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.shopping_bag_outlined, size: 48, color: Color(0xFFC45A12)),
          SizedBox(height: 16),
          Center(child: Text('Votre panier est vide')),
        ],
      );
    }

    final total = _grandTotal(carts);

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: carts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cart = carts[index];
              final subtotal = subtotalForCart(cart);
              final pieces = totalPiecesInCart(cart);
              final refs = cart.items.length;

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _loading ? null : () => _openCartDetail(cart),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CartThumbnail(cart: cart),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cart.organizationName,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$pieces article(s) · $refs réf.',
                                style: const TextStyle(color: Color(0xFF6A4A35), fontSize: 13),
                              ),
                              if (cart.updatedAt != null && cart.updatedAt!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    cart.updatedAt!,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              subtotal.toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: Color(0xFFC45A12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(Icons.chevron_right, color: Colors.grey.shade600),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Material(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total estimé (toutes boutiques)', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        total.toStringAsFixed(2),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: Color(0xFFC45A12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Montants indicatifs. Touchez un panier pour modifier les quantités.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CartThumbnail extends StatelessWidget {
  const _CartThumbnail({required this.cart});

  final CustomerCart cart;

  @override
  Widget build(BuildContext context) {
    final firstPath = cart.items.isNotEmpty ? cart.items.first.product.primaryImageStoragePath : null;
    final url = publicUrlForCatalogImage(firstPath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 64,
        height: 64,
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF6ECE5),
      alignment: Alignment.center,
      child: const Icon(Icons.storefront_outlined, color: Color(0xFFC45A12)),
    );
  }
}
