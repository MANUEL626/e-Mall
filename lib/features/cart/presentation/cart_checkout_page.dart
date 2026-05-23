import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/cart/cart_service.dart';
import '../../../services/catalog/catalog_service.dart';
import '../../../services/orders/orders_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/location/location_picker.dart';
import '../../../core/ui/app_feedback.dart';

/// Plafond d’article par ligne côté API panier (`guide_api.md`) — même ordre de grandeur pour la commande.
const int _kMaxOrderQuantity = 99999;

class _LineSelection {
  _LineSelection({required this.selected, required this.orderQty});

  bool selected;
  int orderQty;
}

/// Commande depuis un panier : choix des lignes, quantités, retrait ou livraison.
class CartCheckoutPage extends StatefulWidget {
  const CartCheckoutPage({super.key, required this.cart});

  final CustomerCart cart;

  @override
  State<CartCheckoutPage> createState() => _CartCheckoutPageState();
}

class _CartCheckoutPageState extends State<CartCheckoutPage> {
  late final Map<String, _LineSelection> _byLineId;
  SaleFulfillmentType _fulfillment = SaleFulfillmentType.pickup;

  final TextEditingController _lng = TextEditingController();
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  bool _loadingParams = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _byLineId = {
      for (final line in widget.cart.items)
        line.lineId: _LineSelection(selected: false, orderQty: line.quantity),
    };
    _loadDefaultCoords();
  }

  @override
  void dispose() {
    _lng.dispose();
    _lat.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultCoords() async {
    if (!AppConfig.isApiConfigured) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    setState(() => _loadingParams = true);
    try {
      final p = await CustomerSaleService.instance.getMyParams(accessToken: session.accessToken);
      if (!mounted) return;
      if (p.defaultLongitude != null) {
        _lng.text = p.defaultLongitude!.toString();
      }
      if (p.defaultLatitude != null) {
        _lat.text = p.defaultLatitude!.toString();
      }
    } catch (_) {
      // Silencieux : champs laissés vides.
    } finally {
      if (mounted) setState(() => _loadingParams = false);
    }
  }

  double? _parseCoord(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  List<CreateSaleOrderLine> _buildOrderLines() {
    final out = <CreateSaleOrderLine>[];
    for (final line in widget.cart.items) {
      final sel = _byLineId[line.lineId]!;
      if (!sel.selected || sel.orderQty < 1) continue;
      final q = sel.orderQty.clamp(1, _kMaxOrderQuantity);
      out.add(CreateSaleOrderLine(articleId: line.product.id, quantity: q));
    }
    return out;
  }

  double _estimatedSelectionTotal() {
    var sum = 0.0;
    for (final line in widget.cart.items) {
      final sel = _byLineId[line.lineId]!;
      if (!sel.selected || sel.orderQty < 1) continue;
      final q = sel.orderQty.clamp(1, _kMaxOrderQuantity);
      sum += parseCatalogUnitPrice(line.product.unitSalePrice) * q;
    }
    return sum;
  }

  Future<void> _syncCartAfterOrder(List<CartLine> cartLinesSnapshot) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    for (final line in cartLinesSnapshot) {
      final sel = _byLineId[line.lineId]!;
      if (!sel.selected || sel.orderQty < 1) continue;
      final ordered = sel.orderQty.clamp(1, _kMaxOrderQuantity);
      final remaining = line.quantity - ordered;
      try {
        if (remaining <= 0) {
          await CustomerShoppingService.instance.deleteCartLine(
            accessToken: session.accessToken,
            lineId: line.lineId,
          );
        } else {
          await CustomerShoppingService.instance.updateCartLineQuantity(
            accessToken: session.accessToken,
            lineId: line.lineId,
            quantity: remaining,
          );
        }
      } catch (_) {
        // Ne bloque pas : la commande est déjà créée côté serveur.
      }
    }
  }

  Future<void> _submit() async {
    if (!AppConfig.isApiConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API_BASE_URL non configurée.')),
      );
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expirée. Reconnectez-vous.')),
      );
      return;
    }

    final lines = _buildOrderLines();
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un article et une quantité.')),
      );
      return;
    }

    double? deliveryLng;
    double? deliveryLat;
    if (_fulfillment == SaleFulfillmentType.delivery) {
      deliveryLng = _parseCoord(_lng.text);
      deliveryLat = _parseCoord(_lat.text);
      if (deliveryLng == null || deliveryLat == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indiquez une longitude et une latitude valides pour la livraison.'),
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final detail = await CustomerSaleService.instance.createSaleOrder(
        accessToken: session.accessToken,
        organizationId: widget.cart.organizationId,
        fulfillmentType: _fulfillment,
        lines: lines,
        deliveryLongitude: _fulfillment == SaleFulfillmentType.delivery ? deliveryLng : null,
        deliveryLatitude: _fulfillment == SaleFulfillmentType.delivery ? deliveryLat : null,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );

      await _syncCartAfterOrder(List<CartLine>.from(widget.cart.items));

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Commande enregistrée'),
          content: Text(
            'Statut : ${detail.order.status}\nRéf. : ${detail.order.id}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on CatalogApiException catch (e) {
      if (mounted) {
        AppFeedback.show(context, AppFeedback.error(AppFeedback.userErrorMessage(e.message)));
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(context, AppFeedback.error(AppFeedback.userErrorMessage(e)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passer commande')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.cart.organizationName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cochez les articles à commander. La quantité peut dépasser celle du panier (max. $_kMaxOrderQuantity par ligne).',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 16),
                  ...widget.cart.items.map(_buildArticleCard),
                  const SizedBox(height: 20),
                  const Text('Mode de réception', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SegmentedButton<SaleFulfillmentType>(
                    segments: const [
                      ButtonSegment(
                        value: SaleFulfillmentType.pickup,
                        label: Text('Retrait'),
                        icon: Icon(Icons.storefront_outlined),
                      ),
                      ButtonSegment(
                        value: SaleFulfillmentType.delivery,
                        label: Text('Livraison'),
                        icon: Icon(Icons.local_shipping_outlined),
                      ),
                    ],
                    selected: {_fulfillment},
                    onSelectionChanged: (s) {
                      setState(() => _fulfillment = s.first);
                    },
                  ),
                  if (_fulfillment == SaleFulfillmentType.delivery) ...[
                    const SizedBox(height: 16),
                    const Text('Coordonnées de livraison', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      _loadingParams ? 'Chargement des coordonnees enregistrees...' : 'Choisissez un point de livraison.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    LocationPicker(
                      longitudeController: _lng,
                      latitudeController: _lat,
                      title: _loadingParams ? 'Chargement de la position enregistree...' : 'Lieu de livraison',
                      subtitle: 'Utilisez votre position actuelle ou touchez la carte pour placer le marqueur.',
                      compact: true,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optionnel)',
                      hintText: 'Instructions pour le marchand ou le livreur',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total sélection', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        _estimatedSelectionTotal().toStringAsFixed(2),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: Color(0xFFC45A12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Material(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: SafeArea(
                top: false,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Valider la commande'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(CartLine line) {
    final sel = _byLineId[line.lineId]!;
    final p = line.product;
    final imgUrl = publicUrlForCatalogImage(p.primaryImageStoragePath);
    final inCart = line.quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: sel.selected,
                  onChanged: (v) {
                    setState(() {
                      sel.selected = v ?? false;
                      if (sel.selected) sel.orderQty = inCart;
                    });
                  },
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: imgUrl != null
                        ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
                        : _ph(),
                  ),
                ),
                const SizedBox(width: 10),
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
                      Text(
                        '${p.unitSalePrice} · $inCart dans le panier',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6A4A35)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (sel.selected) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Quantité pour la commande', style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF6ECE5),
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: sel.orderQty <= 1
                        ? null
                        : () => setState(() => sel.orderQty--),
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('${sel.orderQty}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF6ECE5),
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: sel.orderQty >= _kMaxOrderQuantity
                        ? null
                        : () => setState(() => sel.orderQty++),
                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ph() {
    return Container(
      color: const Color(0xFFF1EEEC),
      child: const Icon(Icons.image_outlined, size: 22, color: Color(0xFF9A7B6A)),
    );
  }
}
