import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/catalog/customer_catalog_service.dart';
import '../../../core/catalog/product_image_url.dart';
import '../../../core/commerce/customer_sale_models.dart';
import '../../../core/commerce/customer_sale_service.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import 'confirm_receipt_scan_page.dart';

String _shortOrderId(String id) {
  if (id.length <= 10) return id;
  return '${id.substring(0, 8)}…';
}

String _formatDateShort(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final t = iso.trim();
  if (t.length >= 10) return t.substring(0, 10);
  return t;
}

String _statusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'pending':
      return l10n.orderStatusPending;
    case 'in_progress':
      return l10n.orderStatusInProgress;
    case 'in_delivery':
      return l10n.orderStatusInDelivery;
    case 'cancelled':
      return l10n.orderStatusCancelled;
    case 'completed':
      return l10n.orderStatusCompleted;
    default:
      return status;
  }
}

String _fulfillmentLabel(AppLocalizations l10n, String? ft) {
  if (ft == 'delivery') return l10n.orderFulfillmentDelivery;
  if (ft == 'pickup') return l10n.orderFulfillmentPickup;
  return ft ?? '—';
}

bool _canConfirmReceipt(String status) {
  return status != 'completed' && status != 'cancelled';
}

/// Liste `GET /api/v1/customer-sales` + filtres `bucket` (guide `guide_api.md`).
class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  SaleOrderBucket? _bucket;
  bool _loading = true;
  String? _error;
  List<SaleOrderDetailOut> _items = const [];

  @override
  void initState() {
    super.initState();
    // Pas d’AppLocalizations.of(context) avant la fin du premier build (règle InheritedWidget).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    if (!AppConfig.isApiConfigured) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = l10n.errorApiNotConfigured;
      });
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = l10n.errorSessionMissing;
      });
      return;
    }

    try {
      final result = await CustomerSaleService.instance.listSaleOrders(
        accessToken: session.accessToken,
        bucket: _bucket,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _loading = false;
      });
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _setBucket(SaleOrderBucket? bucket) {
    if (_bucket == bucket) return;
    setState(() => _bucket = bucket);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ordersTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: l10n.orderConfirmReceiptScanTooltip,
            onPressed: () {
              Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => const ConfirmReceiptScanPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.ordersFilterAll),
                  selected: _bucket == null,
                  onSelected: (v) {
                    if (v) _setBucket(null);
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: Text(l10n.ordersFilterInProgress),
                  selected: _bucket == SaleOrderBucket.inProgress,
                  onSelected: (v) {
                    if (v) _setBucket(SaleOrderBucket.inProgress);
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: Text(l10n.ordersFilterInDelivery),
                  selected: _bucket == SaleOrderBucket.inDelivery,
                  onSelected: (v) {
                    if (v) _setBucket(SaleOrderBucket.inDelivery);
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: Text(l10n.ordersFilterCancelled),
                  selected: _bucket == SaleOrderBucket.cancelled,
                  onSelected: (v) {
                    if (v) _setBucket(SaleOrderBucket.cancelled);
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: Text(l10n.ordersFilterCompleted),
                  selected: _bucket == SaleOrderBucket.completed,
                  onSelected: (v) {
                    if (v) _setBucket(SaleOrderBucket.completed);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _load,
                                child: Text(l10n.retryButton),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.sizeOf(context).height * 0.25,
                                  ),
                                  Center(child: Text(l10n.ordersEmpty)),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: _items.length,
                                itemBuilder: (context, i) {
                                  final detail = _items[i];
                                  final o = detail.order;
                                  final n = detail.lines.length;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      title: Text(
                                        o.organizationName?.isNotEmpty == true
                                            ? o.organizationName!
                                            : _shortOrderId(o.id),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${_statusLabel(l10n, o.status)} · '
                                        '${_fulfillmentLabel(l10n, o.fulfillmentType)} · '
                                        '${l10n.ordersArticlesCount(n)}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => CustomerOrderDetailPage(
                                              initial: detail,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Détail `GET /api/v1/customer-sales/{order_id}` (rafraîchissement à l’ouverture).
class CustomerOrderDetailPage extends StatefulWidget {
  const CustomerOrderDetailPage({super.key, required this.initial});

  final SaleOrderDetailOut initial;

  @override
  State<CustomerOrderDetailPage> createState() => _CustomerOrderDetailPageState();
}

class _CustomerOrderDetailPageState extends State<CustomerOrderDetailPage> {
  late SaleOrderDetailOut _detail;
  bool _refreshing = true;

  @override
  void initState() {
    super.initState();
    _detail = widget.initial;
    _refreshFromApi();
  }

  Future<void> _refreshFromApi() async {
    if (!AppConfig.isApiConfigured) {
      setState(() => _refreshing = false);
      return;
    }
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() => _refreshing = false);
      return;
    }
    try {
      final d = await CustomerSaleService.instance.getSaleOrder(
        accessToken: session.accessToken,
        orderId: widget.initial.order.id,
      );
      if (!mounted) return;
      setState(() {
        _detail = d;
        _refreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final o = _detail.order;

    final showReceipt = _canConfirmReceipt(o.status);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.orderDetailTitle} · ${_shortOrderId(o.id)}'),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _refreshing
                ? null
                : () {
                    setState(() => _refreshing = true);
                    _refreshFromApi();
                  },
          ),
        ],
      ),
      bottomNavigationBar: showReceipt
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l10n.orderDetailConfirmReceipt),
                  onPressed: () async {
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => ConfirmReceiptScanPage(expectedOrderId: o.id),
                      ),
                    );
                    if (ok == true && mounted) {
                      setState(() => _refreshing = true);
                      await _refreshFromApi();
                    }
                  },
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (o.organizationName?.isNotEmpty == true) ...[
            Text(
              o.organizationName!,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.orderShopLabel} · ${_shortOrderId(o.id)}',
              style: const TextStyle(color: Color(0xFF6D513E), fontSize: 13),
            ),
          ] else
            Text(
              '${l10n.orderShopLabel} · ${_shortOrderId(o.id)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          const SizedBox(height: 8),
          Text('${_statusLabel(l10n, o.status)} · ${_fulfillmentLabel(l10n, o.fulfillmentType)}'),
          if (o.createdAt != null && o.createdAt!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('${l10n.orderPlacedLabel} ${_formatDateShort(o.createdAt)}'),
          ],
          if (o.notes != null && o.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(o.notes!, style: const TextStyle(color: Color(0xFF6D513E))),
          ],
          const SizedBox(height: 20),
          Text(
            l10n.orderArticlesTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ..._detail.lines.map((line) => _OrderLineTile(line: line)),
        ],
      ),
    );
  }
}

class _OrderLineTile extends StatelessWidget {
  const _OrderLineTile({required this.line});

  final SaleOrderLine line;

  @override
  Widget build(BuildContext context) {
    final product = line.product;
    final name = product?.name.isNotEmpty == true ? product!.name : (line.articleId ?? '—');
    final price = product?.unitSalePrice ?? '';
    final imgUrl = publicUrlForCatalogImage(product?.primaryImageStoragePath);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: imgUrl != null
                    ? Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFFF1DACB),
                          child: Icon(Icons.image_not_supported_outlined),
                        ),
                      )
                    : const ColoredBox(
                        color: Color(0xFFF1DACB),
                        child: Icon(Icons.inventory_2_outlined, color: Color(0xFF6A4A35)),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('× ${line.quantity}', style: const TextStyle(color: Color(0xFF6D513E))),
                  if (price.isNotEmpty)
                    Text(price, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
