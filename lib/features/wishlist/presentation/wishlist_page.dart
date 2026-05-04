import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/catalog/catalog_models.dart';
import '../../../core/catalog/customer_catalog_service.dart';
import '../../../core/catalog/product_image_url.dart';
import '../../../core/commerce/customer_shopping_service.dart';
import '../../../core/config/app_config.dart';

/// Liste de souhaits depuis `GET /api/v1/customers/wishlist`.
class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<CatalogProduct>? _items;
  bool _loading = true;
  String? _error;
  final Set<String> _busyArticleIds = <String>{};

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
        _items = null;
      });
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        _loading = false;
        _error = 'Connectez-vous pour voir vos favoris.';
        _items = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await CustomerShoppingService.instance.getWishlist(accessToken: session.accessToken);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
        _error = null;
      });
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
        _items = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _items = null;
      });
    }
  }

  Future<void> _remove(CatalogProduct product) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    setState(() => _busyArticleIds.add(product.id));
    try {
      await CustomerShoppingService.instance.removeWishlistItem(
        accessToken: session.accessToken,
        organizationArticleId: product.id,
      );
      if (!mounted) return;
      setState(() {
        _items = _items?.where((p) => p.id != product.id).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retiré des favoris')),
        );
      }
    } on CatalogApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyArticleIds.remove(product.id));
      }
    }
  }

  Future<void> _addToCart(CatalogProduct product) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    setState(() => _busyArticleIds.add(product.id));
    try {
      await CustomerShoppingService.instance.addCartLine(
        accessToken: session.accessToken,
        organizationArticleId: product.id,
        quantity: 1,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajouté au panier')),
      );
    } on CatalogApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyArticleIds.remove(product.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste de souhaits'),
        actions: [
          if (_items != null)
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
    if (_loading && _items == null) {
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

    final items = _items ?? [];
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.favorite_border, size: 48, color: Color(0xFFC45A12)),
          SizedBox(height: 16),
          Center(child: Text('Aucun article dans vos favoris')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = items[index];
        final busy = _busyArticleIds.contains(p.id);
        final imgUrl = publicUrlForCatalogImage(p.primaryImageStoragePath);
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: imgUrl != null
                        ? Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.organizationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF6A4A35)),
                      ),
                      Text(
                        p.unitSalePrice,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Retirer',
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      icon: busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_outline),
                      onPressed: busy ? null : () => _remove(p),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => _addToCart(p),
                      icon: const Icon(Icons.add_shopping_cart_outlined, size: 16),
                      label: const Text('Panier'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFEEDFD5),
      child: const Icon(Icons.image_outlined, color: Color(0xFF9A7B6A)),
    );
  }
}
