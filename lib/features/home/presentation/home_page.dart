import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/cart/cart_service.dart';
import '../../../services/catalog/catalog_service.dart';
import '../../../core/branding/app_branding.dart';
import '../../../core/config/app_config.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageCache {
  static List<CatalogProduct> items = <CatalogProduct>[];
  static int total = 0;
  static String query = '';
  static String selectedCategory = 'all';
  static double? minPrice;
  static double? maxPrice;
  static Set<String> cartProductIds = <String>{};

  static bool get hasData => items.isNotEmpty;
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
  Timer? _realtimeRefreshDebounce;
  final Set<String> _addingToCartIds = <String>{};
  Set<String> _cartProductIds = <String>{};
  RealtimeChannel? _catalogChannel;
  bool _realtimeRefreshInFlight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final restored = _restoreCachedState();
    _subscribeToCatalogUpdates();
    if (restored) {
      unawaited(_load(reset: true, silent: true));
    } else {
      unawaited(_load(reset: true));
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _realtimeRefreshDebounce?.cancel();
    final channel = _catalogChannel;
    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }
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

  bool _restoreCachedState() {
    if (!_HomePageCache.hasData) return false;
    _query = _HomePageCache.query;
    _selectedCategory = _HomePageCache.selectedCategory;
    _minPrice = _HomePageCache.minPrice;
    _maxPrice = _HomePageCache.maxPrice;
    _items = List<CatalogProduct>.from(_HomePageCache.items);
    _total = _HomePageCache.total;
    _cartProductIds = Set<String>.from(_HomePageCache.cartProductIds);
    _loading = false;
    _error = null;
    _searchController.text = _query;
    _filterMinController.text = _minPrice != null ? _formatNum(_minPrice!) : '';
    _filterMaxController.text = _maxPrice != null ? _formatNum(_maxPrice!) : '';
    return true;
  }

  void _saveCachedState() {
    _HomePageCache.items = List<CatalogProduct>.from(_items);
    _HomePageCache.total = _total;
    _HomePageCache.query = _query;
    _HomePageCache.selectedCategory = _selectedCategory;
    _HomePageCache.minPrice = _minPrice;
    _HomePageCache.maxPrice = _maxPrice;
    _HomePageCache.cartProductIds = Set<String>.from(_cartProductIds);
  }

  void _subscribeToCatalogUpdates() {
    if (!AppConfig.isSupabaseConfigured) return;
    if (Supabase.instance.client.auth.currentSession == null) return;

    final channel = Supabase.instance.client.channel(
      'customer-home-catalog-${identityHashCode(this)}',
    );
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'organization_articles',
          callback: (_) => _scheduleRealtimeRefresh(),
        )
        .subscribe();
    _catalogChannel = channel;
  }

  void _scheduleRealtimeRefresh() {
    if (!mounted) return;
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted || _realtimeRefreshInFlight) return;
      _realtimeRefreshInFlight = true;
      try {
        await _load(reset: true, silent: true);
      } finally {
        _realtimeRefreshInFlight = false;
      }
    });
  }

  Future<void> _load({required bool reset, bool silent = false}) async {
    if (!AppConfig.isApiConfigured) {
      if (!mounted) return;
      if (silent && _items.isNotEmpty) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.errorApiNotConfigured;
      });
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (!mounted) return;
      if (silent && _items.isNotEmpty) return;
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
      if (!silent || _items.isEmpty) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final token = session.accessToken;
      final page = await _fetchPage(token: token, offset: offset, limit: _pageSize);
      final cartProductIds = reset
          ? await _fetchCartProductIds(token)
          : _cartProductIds;

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
        _cartProductIds = cartProductIds;
      });
      _saveCachedState();
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      if (silent && _items.isNotEmpty) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = AppFeedback.userErrorMessage(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      if (silent && _items.isNotEmpty) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = AppFeedback.userErrorMessage(e);
      });
    }
  }

  Future<Set<String>> _fetchCartProductIds(String token) async {
    try {
      final carts = await CustomerShoppingService.instance.getCarts(accessToken: token);
      return {
        for (final cart in carts)
          for (final line in cart.items)
            if (line.product.id.isNotEmpty) line.product.id,
      };
    } catch (_) {
      return _cartProductIds;
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
                            AppBranding.appIcon(size: 30),
                            const SizedBox(width: 8),
                            const Text(
                              AppBranding.appName,
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
                    const SizedBox(height: 12),
                    Text(
                      _productsTitle(),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.brown.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _emptyProductsMessage(l10n),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: Color(0xFF6A4A35),
                        ),
                      ),
                      if (_hasActiveSearchOrFilter) ...[
                        const SizedBox(height: 14),
                        TextButton.icon(
                          onPressed: _clearSearchAndFilters,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Voir tous les produits'),
                        ),
                      ],
                    ],
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
                      return _ProductCard(
                        product: item,
                        isAddingToCart: _addingToCartIds.contains(item.id),
                        isInCart: _cartProductIds.contains(item.id),
                        onTap: () => unawaited(_openProductDetail(item)),
                        onAddToCart: () => unawaited(_addToCart(item).then<void>((_) {})),
                      );
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
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  String _productsTitle() {
    if (_selectedCategory == 'all') return AppBranding.appName;
    return kCatalogCategoryOptions
            .where((option) => option.$1 == _selectedCategory)
            .map((option) => option.$2)
            .firstOrNull ??
        AppBranding.appName;
  }

  bool get _hasActiveSearchOrFilter {
    return _query.isNotEmpty || _selectedCategory != 'all' || _minPrice != null || _maxPrice != null;
  }

  String _emptyProductsMessage(AppLocalizations l10n) {
    if (_query.isNotEmpty && (_selectedCategory != 'all' || _minPrice != null || _maxPrice != null)) {
      return 'Aucun produit ne correspond a cette recherche et ces filtres.';
    }
    if (_query.isNotEmpty) {
      return 'Aucun produit trouve pour "$_query".';
    }
    if (_selectedCategory != 'all' || _minPrice != null || _maxPrice != null) {
      return 'Aucun produit ne correspond a ces filtres.';
    }
    return l10n.homeEmptyCatalog;
  }

  void _clearSearchAndFilters() {
    _searchDebounce?.cancel();
    setState(() {
      _query = '';
      _selectedCategory = 'all';
      _minPrice = null;
      _maxPrice = null;
      _searchController.clear();
      _filterMinController.clear();
      _filterMaxController.clear();
    });
    unawaited(_load(reset: true));
  }

  Future<bool> _addToCart(CatalogProduct product) async {
    if (_addingToCartIds.contains(product.id)) return false;
    if (_cartProductIds.contains(product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce produit est deja dans votre panier.')),
      );
      return false;
    }
    if (product.stockStatus == 'out_of_stock') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce produit est indisponible pour le moment.')),
      );
      return false;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expiree. Reconnectez-vous.')),
      );
      return false;
    }

    setState(() => _addingToCartIds.add(product.id));
    try {
      await CustomerShoppingService.instance.addCartLine(
        accessToken: session.accessToken,
        organizationArticleId: product.id,
        quantity: 1,
      );
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au panier')),
      );
      setState(() => _cartProductIds = {..._cartProductIds, product.id});
      _saveCachedState();
      return true;
    } on CatalogApiException catch (e) {
      if (!mounted) return false;
      AppFeedback.show(context, AppFeedback.error(AppFeedback.userErrorMessage(e.message)));
    } catch (_) {
      if (!mounted) return false;
      AppFeedback.show(
        context,
        AppFeedback.error('Impossible d ajouter ce produit au panier.'),
      );
    } finally {
      if (mounted) setState(() => _addingToCartIds.remove(product.id));
    }
    return false;
  }

  Future<void> _openProductDetail(CatalogProduct product) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          product: product,
          isAddingToCart: _addingToCartIds.contains(product.id),
          isInCart: _cartProductIds.contains(product.id),
          onAddToCart: () => _addToCart(product),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isAddingToCart,
    required this.isInCart,
    required this.onTap,
    required this.onAddToCart,
  });

  final CatalogProduct product;
  final bool isAddingToCart;
  final bool isInCart;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final imageUrl = publicUrlForCatalogImage(product.primaryImageStoragePath);
    final priceLabel = product.unitSalePrice;
    final stock = _stockLabel(product.stockStatus);
    final outOfStock = product.stockStatus == 'out_of_stock';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
                    child: Material(
                      color: outOfStock
                          ? Colors.grey.shade500
                          : isInCart
                              ? const Color(0xFF2E6F40)
                              : const Color(0xFFC45A12),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: isAddingToCart || outOfStock || isInCart ? null : onAddToCart,
                        child: SizedBox(
                          height: 38,
                          width: 38,
                          child: Center(
                            child: isAddingToCart
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    outOfStock
                                        ? Icons.remove_shopping_cart_outlined
                                        : isInCart
                                            ? Icons.shopping_cart_checkout_rounded
                                            : Icons.add_shopping_cart,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.isInCart,
    this.isAddingToCart = false,
  });

  final CatalogProduct product;
  final Future<bool> Function() onAddToCart;
  final bool isInCart;
  final bool isAddingToCart;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _adding = false;
  late bool _inCart;

  @override
  void initState() {
    super.initState();
    _inCart = widget.isInCart;
  }

  Future<void> _addToCart() async {
    if (_adding || widget.isAddingToCart || _inCart) return;
    setState(() => _adding = true);
    try {
      final added = await widget.onAddToCart();
      if (mounted && added) setState(() => _inCart = true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrls = <String>[
      if (publicUrlForCatalogImage(product.primaryImageStoragePath) case final primary?)
        primary,
      ...product.additionalImageStoragePaths
          .map(publicUrlForCatalogImage)
          .whereType<String>(),
    ];
    final stockLabel = _ProductCard._stockLabel(product.stockStatus) ?? product.stockStatus;
    final outOfStock = product.stockStatus == 'out_of_stock';
    final adding = _adding || widget.isAddingToCart;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail du produit')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 1,
                child: imageUrls.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFFEDE0D8),
                        child: Center(child: Icon(Icons.shopping_bag_outlined, size: 56)),
                      )
                    : PageView.builder(
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Color(0xFFEDE0D8),
                              child: Center(child: Icon(Icons.image_not_supported_outlined)),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 26,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2F1B10),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.organizationName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7B4721),
              ),
            ),
            const SizedBox(height: 18),
            _ProductInfoRow(
              icon: Icons.sell_outlined,
              label: 'Prix',
              value: product.unitSalePrice,
            ),
            _ProductInfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Quantite disponible',
              value: stockLabel,
              valueColor: outOfStock ? const Color(0xFFB3261E) : const Color(0xFF2E6F40),
            ),
            _ProductInfoRow(
              icon: Icons.category_outlined,
              label: 'Categorie',
              value: catalogCategoryLabel(product.category),
            ),
            const SizedBox(height: 18),
            if (product.description?.trim().isNotEmpty == true) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2F1B10),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description!.trim(),
                style: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF6A4A35)),
              ),
            ] else
              const Text(
                'Aucune description disponible pour ce produit.',
                style: TextStyle(fontSize: 15, color: Color(0xFF6A4A35)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: FilledButton.icon(
            onPressed: outOfStock || adding || _inCart ? null : _addToCart,
            icon: adding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    _inCart
                        ? Icons.shopping_cart_checkout_rounded
                        : Icons.add_shopping_cart_rounded,
                  ),
            label: Text(
              outOfStock
                  ? 'Produit indisponible'
                  : _inCart
                      ? 'Deja dans le panier'
                      : 'Ajouter au panier',
            ),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
        ),
      ),
    );
  }
}

class _ProductInfoRow extends StatelessWidget {
  const _ProductInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF3F2413),
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFC45A12)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6A4A35)),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
