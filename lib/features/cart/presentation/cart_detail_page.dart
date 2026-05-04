import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/catalog/customer_catalog_service.dart';
import '../../../core/catalog/product_image_url.dart';
import '../../../core/commerce/customer_shopping_service.dart';
import '../../../core/commerce/shopping_cart_models.dart';
import '../../../core/config/app_config.dart';
import 'cart_checkout_page.dart';

/// Détail d’un panier boutique : lignes, quantités, vidage.
class CartDetailPage extends StatefulWidget {
  const CartDetailPage({
    super.key,
    required this.initialCart,
  });

  final CustomerCart initialCart;

  @override
  State<CartDetailPage> createState() => _CartDetailPageState();
}

class _CartDetailPageState extends State<CartDetailPage> {
  CustomerCart? _cart;
  bool _loading = true;
  final Set<String> _busyLineIds = <String>{};

  @override
  void initState() {
    super.initState();
    _cart = widget.initialCart;
    _loading = false;
  }

  Future<void> _reloadFromApi() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || !AppConfig.isApiConfigured) return;

    setState(() => _loading = true);
    try {
      final carts = await CustomerShoppingService.instance.getCarts(accessToken: session.accessToken);
      if (!mounted) return;
      final idx = carts.indexWhere((c) => c.cartId == widget.initialCart.cartId);
      if (idx < 0) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _cart = carts[idx];
        _loading = false;
      });
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _setQuantity(CartLine line, int next) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    if (next < 1) {
      await _deleteLine(line);
      return;
    }

    setState(() => _busyLineIds.add(line.lineId));
    try {
      await CustomerShoppingService.instance.updateCartLineQuantity(
        accessToken: session.accessToken,
        lineId: line.lineId,
        quantity: next,
      );
      if (!mounted) return;
      await _reloadFromApi();
    } on CatalogApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busyLineIds.remove(line.lineId));
    }
  }

  Future<void> _deleteLine(CartLine line) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    setState(() => _busyLineIds.add(line.lineId));
    try {
      await CustomerShoppingService.instance.deleteCartLine(
        accessToken: session.accessToken,
        lineId: line.lineId,
      );
      if (!mounted) return;
      await _reloadFromApi();
    } on CatalogApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busyLineIds.remove(line.lineId));
    }
  }

  Future<void> _clearCart() async {
    final cart = _cart;
    final session = Supabase.instance.client.auth.currentSession;
    if (cart == null || session == null) return;

    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Vider ce panier ?'),
            content: Text(cart.organizationName),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vider')),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;

    try {
      await CustomerShoppingService.instance.deleteCart(
        accessToken: session.accessToken,
        cartId: cart.cartId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CatalogApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openCheckout() async {
    final cart = _cart;
    if (cart == null || cart.items.isEmpty || _loading) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CartCheckoutPage(cart: cart),
      ),
    );
    if (ok == true && mounted) await _reloadFromApi();
  }

  @override
  Widget build(BuildContext context) {
    final cart = _cart;

    return Scaffold(
      appBar: AppBar(
        title: Text(cart?.organizationName ?? 'Panier'),
        actions: [
          if (cart != null && cart.items.isNotEmpty)
            TextButton(
              onPressed: _loading ? null : _clearCart,
              child: const Text('Vider'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _reloadFromApi,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reloadFromApi,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final cart = _cart;
    if (cart == null || cart.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Icon(Icons.shopping_bag_outlined, size: 48, color: Color(0xFFC45A12)),
          const SizedBox(height: 16),
          const Center(child: Text('Ce panier est vide')),
          const SizedBox(height: 24),
          Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Retour aux paniers'),
            ),
          ),
        ],
      );
    }

    final subtotal = subtotalForCart(cart);

    return Column(
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...cart.items.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _LineTile(
                      line: line,
                      busy: _busyLineIds.contains(line.lineId),
                      onDecrement: () => _setQuantity(line, line.quantity - 1),
                      onIncrement: () => _setQuantity(line, line.quantity + 1),
                      onDelete: () => _deleteLine(line),
                    ),
                  )),
            ],
          ),
        ),
        Material(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _loading ? null : _openCheckout,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Commander'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sous-total', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        subtotal.toStringAsFixed(2),
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
                    'Montants indicatifs (prix catalogue).',
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

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.busy,
    required this.onDecrement,
    required this.onIncrement,
    required this.onDelete,
  });

  final CartLine line;
  final bool busy;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = line.product;
    final imgUrl = publicUrlForCatalogImage(p.primaryImageStoragePath);
    final lineTotal = parseCatalogUnitPrice(p.unitSalePrice) * line.quantity;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 72,
                height: 72,
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
                    '${p.unitSalePrice} × ${line.quantity}',
                    style: const TextStyle(color: Color(0xFF6A4A35)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF6ECE5),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  minimumSize: const Size(34, 34),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: busy ? null : onDecrement,
                                icon: const Icon(Icons.remove, size: 18),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: busy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        '${line.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF6ECE5),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  minimumSize: const Size(34, 34),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: busy || line.quantity >= 99999 ? null : onIncrement,
                                icon: const Icon(Icons.add, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Supprimer',
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: const Size(40, 40),
                          padding: const EdgeInsets.all(4),
                        ),
                        onPressed: busy ? null : onDelete,
                        icon: const Icon(Icons.delete_outline, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: Text(
                lineTotal.toStringAsFixed(2),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF1EEEC),
      child: const Icon(Icons.image_outlined, color: Color(0xFF9A7B6A)),
    );
  }
}
