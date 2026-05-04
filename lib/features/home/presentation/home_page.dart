import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/catalog/catalog_models.dart';
import '../../../core/catalog/customer_catalog_service.dart';
import '../../../core/catalog/product_image_url.dart';
import '../../../core/branding/app_branding.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _pageSize = 24;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _filterMinController = TextEditingController();
  final TextEditingController _filterMaxController = TextEditingController();

  bool _showSearchField = false;
  String _query = '';
  String _selectedCategory = 'all';
  double? _minPrice;
  double? _maxPrice;

  List<CatalogProduct> _items = [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_load(reset: true));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _filterMinController.dispose();
    _filterMaxController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loading || _loadingMore || _error != null) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent - 320) {
      unawaited(_load(reset: false));
    }
  }

  Future<void> _load({required bool reset}) async {
    if (!AppConfig.isApiConfigured) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.errorApiNotConfigured;
      });
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.errorSessionMissing;
      });
      return;
    }

    if (_loadingMore && !reset) return;
    if (!reset && _items.length >= _total) return;

    final offset = reset ? 0 : _items.length;
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final token = session.accessToken;
      final page = await _fetchPage(token: token, offset: offset, limit: _pageSize);

      if (!mounted) return;
      setState(() {
        _total = page.total;
        if (reset) {
          _items = List<CatalogProduct>.from(page.items);
        } else {
          _items = [..._items, ...page.items];
        }
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.toString();
      });
    }
  }

  Future<CatalogPage> _fetchPage({
    required String token,
    required int offset,
    required int limit,
  }) async {
    final svc = CustomerCatalogService.instance;
    final q = _query.trim();
    final hasCategory = _selectedCategory != 'all';
    final hasPrice = _minPrice != null || _maxPrice != null;

    // Recherche dédiée uniquement si le nom est le seul critère (guide : `/products/search`).
    if (q.isNotEmpty && !hasCategory && !hasPrice) {
      return svc.searchProducts(accessToken: token, q: q, limit: limit, offset: offset);
    }

    // Filtres combinés (`/products/filter` — au moins un paramètre côté API).
    if (hasCategory || hasPrice || q.isNotEmpty) {
      return svc.filterProducts(
        accessToken: token,
        name: q.isNotEmpty ? q : null,
        categories: hasCategory ? [_selectedCategory] : null,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        limit: limit,
        offset: offset,
      );
    }

    return svc.listProducts(accessToken: token, limit: limit, offset: offset);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _query = value.trim());
      unawaited(_load(reset: true));
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _searchController.clear();
        _query = '';
        unawaited(_load(reset: true));
      }
    });
  }

  void _openFilterSheet() {
    _filterMinController.text = _minPrice != null ? _formatNum(_minPrice!) : '';
    _filterMaxController.text = _maxPrice != null ? _formatNum(_maxPrice!) : '';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF5ECE7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.filterSheetTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.filterCategoryLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.homeAllCategories),
                        selected: _selectedCategory == 'all',
                        onSelected: (_) {
                          setState(() => _selectedCategory = 'all');
                          setModalState(() {});
                        },
                      ),
                      ...kCatalogCategoryOptions.map(
                        (e) => ChoiceChip(
                          label: Text(e.$2),
                          selected: _selectedCategory == e.$1,
                          onSelected: (_) {
                            setState(() => _selectedCategory = e.$1);
                            setModalState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.filterPriceLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _filterMinController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Min',
                            filled: true,
                            fillColor: const Color(0xFFF3E4D9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _filterMaxController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Max',
                            filled: true,
                            fillColor: const Color(0xFFF3E4D9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final minP = _parseDouble(_filterMinController.text);
                        final maxP = _parseDouble(_filterMaxController.text);
                        if (minP != null &&
                            maxP != null &&
                            minP > maxP) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.snackMinMaxPrice)),
                          );
                          return;
                        }
                        setState(() {
                          _minPrice = minP;
                          _maxPrice = maxP;
                        });
                        Navigator.of(context).pop();
                        unawaited(_load(reset: true));
                      },
                      child: Text(l10n.applyButton),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'all';
                        _minPrice = null;
                        _maxPrice = null;
                        _filterMinController.clear();
                        _filterMaxController.clear();
                      });
                      Navigator.of(context).pop();
                      unawaited(_load(reset: true));
                    },
                    child: Text(l10n.resetButton),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static double? _parseDouble(String raw) {
    final s = raw.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  static String _formatNum(double n) {
    if (n == n.roundToDouble()) return n.round().toString();
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _toggleSearch,
                          icon: const Icon(Icons.search),
                          tooltip: l10n.homeSearchTooltip,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppBranding.logoImage(height: 30, fit: BoxFit.contain),
                            const SizedBox(width: 8),
                            const Text(
                              'e-Mall',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7B4721),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _openFilterSheet,
                          icon: const Icon(Icons.tune),
                          tooltip: l10n.homeFiltersTooltip,
                        ),
                      ],
                    ),
                    if (_showSearchField) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: l10n.homeSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: const Color(0xFFF3E4D9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF0DACB), Color(0xFFE8E8C8)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.homeHeroTitle,
                            style: const TextStyle(
                              fontSize: 42,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2F1B10),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.homeHeroSubtitle,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_activeFilterSummary(l10n).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _activeFilterSummary(l10n),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6A4A35),
                          ),
                        ),
                      ),
                    Text(
                      l10n.homeCategoriesTitle,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F1B10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _CategoryChip(
                          label: l10n.homeAllCategories,
                          bg: const Color(0xFFE7D8CD),
                          selected: _selectedCategory == 'all',
                          onTap: () {
                            setState(() => _selectedCategory = 'all');
                            unawaited(_load(reset: true));
                          },
                        ),
                        ...kCatalogCategoryOptions.map(
                          (e) => _CategoryChip(
                            label: e.$2,
                            bg: _chipColorFor(e.$1),
                            selected: _selectedCategory == e.$1,
                            onTap: () {
                              setState(() => _selectedCategory = e.$1);
                              unawaited(_load(reset: true));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.homeSelectionTitle,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F1B10),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            if (_loading && _items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF6A4A35)),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => unawaited(_load(reset: true)),
                        child: Text(l10n.retryButton),
                      ),
                    ],
                  ),
                ),
              )
            else if (_items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    l10n.homeEmptyCatalog,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.64,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _items[index];
                      return _ProductCard(product: item);
                    },
                    childCount: _items.length,
                  ),
                ),
              ),
            if (_loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Row(
                    children: [
                      _CategoryChip(
                        label: 'local_shipping',
                        bg: Color(0xFFF26D21),
                        fg: Colors.white,
                        selected: false,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Free Friday Delivery\nAll orders over \$50 delivered every Friday.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _activeFilterSummary(AppLocalizations l10n) {
    final parts = <String>[];
    if (_minPrice != null || _maxPrice != null) {
      final a = _minPrice != null ? _formatNum(_minPrice!) : '…';
      final b = _maxPrice != null ? _formatNum(_maxPrice!) : '…';
      parts.add(l10n.filterPriceSummary(a, b));
    }
    return parts.join(' · ');
  }

  Color _chipColorFor(String slug) {
    const palette = [
      Color(0xFFC4F3A7),
      Color(0xFFF6E2CB),
      Color(0xFFF2D7C7),
      Color(0xFFFCE3D2),
      Color(0xFFE8D4F0),
      Color(0xFFD4E8F7),
      Color(0xFFE8E8C8),
      Color(0xFFE7D8CD),
    ];
    var h = 0;
    for (final c in slug.codeUnits) {
      h = (h + c) % palette.length;
    }
    return palette[h];
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = publicUrlForCatalogImage(product.primaryImageStoragePath);
    final priceLabel = product.unitSalePrice;
    final stock = _stockLabel(product.stockStatus);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: const Color(0xFFEDE0D8),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_outlined),
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(Icons.shopping_bag_outlined, size: 40),
                          ),
                  ),
                  if (stock != null)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          stock,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFC45A12),
                        shape: BoxShape.circle,
                      ),
                      height: 36,
                      width: 36,
                      child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.organizationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.brown.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  priceLabel,
                  style: const TextStyle(
                    color: Color(0xFF5D2F15),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _stockLabel(String s) {
    switch (s) {
      case 'in_stock':
        return 'En stock';
      case 'low_stock':
        return 'Stock faible';
      case 'out_of_stock':
        return 'Rupture';
      default:
        return null;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.bg,
    this.fg = const Color(0xFF3F2413),
    this.selected = false,
    this.onTap,
  });

  final String label;
  final Color bg;
  final Color fg;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          border: selected ? Border.all(color: const Color(0xFF7B4721), width: 1.4) : null,
        ),
        child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
