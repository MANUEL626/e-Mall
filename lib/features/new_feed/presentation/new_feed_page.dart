import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../core/catalog/customer_catalog_service.dart';
import '../../../core/catalog/product_image_url.dart';
import '../../../core/commerce/customer_shopping_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/feeds/article_post_feed_models.dart';
import '../../../core/feeds/customer_feed_service.dart';
import '../../../core/organizations/customer_organization_service.dart';
import '../../../l10n/app_localizations.dart';
import 'merchant_organization_page.dart';
import 'new_feed_search_page.dart';

class NewFeedPage extends StatefulWidget {
  const NewFeedPage({super.key});

  @override
  State<NewFeedPage> createState() => _NewFeedPageState();
}

class _NewFeedPageState extends State<NewFeedPage> {
  static const int _pageSize = 12;

  final PageController _pageController = PageController();

  List<ArticlePostFeedItem> _items = [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  final Set<String> _wishlistArticleIds = <String>{};
  final Set<String> _subscribedOrgIds = <String>{};
  final Set<String> _cartTouchedArticleIds = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future.wait<void>([
      _loadFeed(reset: true),
      _refreshSideData(),
    ]);
  }

  Future<void> _refreshSideData() async {
    if (!AppConfig.isApiConfigured) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    final token = session.accessToken;
    try {
      final subs = await CustomerOrganizationService.instance.listSubscriptions(accessToken: token);
      final wish = await CustomerShoppingService.instance.getWishlist(accessToken: token);
      if (!mounted) return;
      setState(() {
        _subscribedOrgIds
          ..clear()
          ..addAll(
            subs.items
                .where((s) => s.status.toLowerCase() == 'active')
                .map((s) => s.organizationId),
          );
        _wishlistArticleIds
          ..clear()
          ..addAll(wish.map((p) => p.id));
      });
    } catch (_) {
      // Silencieux : le feed peut fonctionner sans ces listes.
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed({required bool reset}) async {
    if (!AppConfig.isApiConfigured) {
      setState(() {
        _loading = false;
        _error = 'API_BASE_URL non configurée (dart-define).';
      });
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        _loading = false;
        _error = 'Session absente. Reconnectez-vous.';
      });
      return;
    }

    if (_loadingMore && !reset) return;
    if (!reset && _items.length >= _total && _total > 0) return;

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
      final page = await CustomerFeedService.instance.postsFeed(
        accessToken: token,
        limit: _pageSize,
        offset: offset,
      );

      if (!mounted) return;
      setState(() {
        _total = page.total;
        if (reset) {
          _items = List<ArticlePostFeedItem>.from(page.items);
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

  void _onPageChanged(int index) {
    if (_loadingMore || _error != null) return;
    if (_items.length >= _total && _total > 0) return;
    if (_items.length - index <= 4) {
      unawaited(_loadFeed(reset: false));
    }
  }

  Future<void> _toggleWishlist(ArticlePostFeedItem item) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    final id = item.organizationArticleId;
    final inList = _wishlistArticleIds.contains(id);
    try {
      if (inList) {
        await CustomerShoppingService.instance.removeWishlistItem(
          accessToken: session.accessToken,
          organizationArticleId: id,
        );
        if (!mounted) return;
        setState(() => _wishlistArticleIds.remove(id));
      } else {
        await CustomerShoppingService.instance.addWishlistItem(
          accessToken: session.accessToken,
          organizationArticleId: id,
        );
        if (!mounted) return;
        setState(() => _wishlistArticleIds.add(id));
      }
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _addToCart(ArticlePostFeedItem item) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    try {
      await CustomerShoppingService.instance.addCartLine(
        accessToken: session.accessToken,
        organizationArticleId: item.organizationArticleId,
        quantity: 1,
      );
      if (!mounted) return;
      setState(() => _cartTouchedArticleIds.add(item.organizationArticleId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.snackAddedToCart)),
      );
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openMerchant(ArticlePostFeedItem item) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MerchantOrganizationPage(
          organizationId: item.organizationId,
          initialName: item.organizationName,
        ),
      ),
    ).then((_) {
      if (mounted) unawaited(_refreshSideData());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_loading && _items.isEmpty)
              const Center(child: CircularProgressIndicator(color: Color(0xFFF3D4BE)))
            else if (_error != null && _items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => unawaited(_bootstrap()),
                        child: Text(AppLocalizations.of(context)!.retryButton),
                      ),
                    ],
                  ),
                ),
              )
            else if (_items.isEmpty)
              Center(
                child: Text(
                  AppLocalizations.of(context)!.feedEmptyPosts,
                  style: const TextStyle(color: Colors.white70),
                ),
              )
            else
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: _onPageChanged,
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final inWishlist = _wishlistArticleIds.contains(item.organizationArticleId);
                  final inCartHint = _cartTouchedArticleIds.contains(item.organizationArticleId);
                  return _FeedFullScreenItem(
                    item: item,
                    isLiked: inWishlist,
                    isAdded: inCartHint,
                    isFollowingMerchant: _subscribedOrgIds.contains(item.organizationId),
                    onLikeTap: () => unawaited(_toggleWishlist(item)),
                    onAddTap: () => unawaited(_addToCart(item)),
                    onMerchantTap: () => _openMerchant(item),
                  );
                },
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC000000), Color(0x00000000)],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const NewFeedSearchPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.search, color: Colors.white),
                        ),
                        const Text(
                          'e-Mall',
                          style: TextStyle(
                            color: Color(0xFFF3D4BE),
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _subtitleLine(ArticlePostFeedItem item) {
  final cap = item.caption?.trim();
  if (cap != null && cap.isNotEmpty) return cap;
  final desc = item.description?.trim();
  if (desc != null && desc.isNotEmpty) return desc;
  return '';
}

class _FeedFullScreenItem extends StatelessWidget {
  const _FeedFullScreenItem({
    required this.item,
    required this.isLiked,
    required this.isAdded,
    required this.isFollowingMerchant,
    required this.onLikeTap,
    required this.onAddTap,
    required this.onMerchantTap,
  });

  final ArticlePostFeedItem item;
  final bool isLiked;
  final bool isAdded;
  final bool isFollowingMerchant;
  final VoidCallback onLikeTap;
  final VoidCallback onAddTap;
  final VoidCallback onMerchantTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _FeedBackdrop(item: item),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.38),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 170,
          child: Column(
            children: [
              _ActionRoundButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: 'WISHLIST',
                bgColor: isLiked ? const Color(0xFFF47A2B) : const Color(0x57FFFFFF),
                iconColor: Colors.white,
                onTap: onLikeTap,
              ),
              const SizedBox(height: 16),
              _ActionRoundButton(
                icon: Icons.shopping_cart,
                label: 'ADD',
                bgColor: isAdded ? const Color(0xFFF47A2B) : const Color(0x57FFFFFF),
                iconColor: Colors.white,
                onTap: onAddTap,
              ),
              const SizedBox(height: 16),
              _ActionRoundButton(icon: Icons.share, label: ''),
            ],
          ),
        ),
        Positioned(
          left: 18,
          right: 80,
          bottom: 64,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onMerchantTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD98652),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.storefront, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.organizationName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isFollowingMerchant) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.feedFollowingBadge,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            AppLocalizations.of(context)!.feedViewMerchant,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              if (_subtitleLine(item).isNotEmpty)
                Text(
                  _subtitleLine(item),
                  style: const TextStyle(
                    color: Color(0xFFE3DCD7),
                    fontSize: 20,
                    height: 1.3,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                item.unitSalePrice,
                style: const TextStyle(
                  color: Color(0xFFF47A2B),
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedBackdrop extends StatelessWidget {
  const _FeedBackdrop({required this.item});

  final ArticlePostFeedItem item;

  @override
  Widget build(BuildContext context) {
    final postUrl = publicUrlForPostMedia(item.mediaStoragePath.isNotEmpty ? item.mediaStoragePath : null);
    final catalogUrl = publicUrlForCatalogImage(item.primaryImageStoragePath);

    if (item.isVideo && postUrl != null) {
      return _VideoBackdrop(key: ValueKey<String>(postUrl), url: postUrl, fallbackUrl: catalogUrl);
    }

    final imageUrl = postUrl ?? catalogUrl;
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => _GradientFallback(catalogUrl: catalogUrl),
      );
    }

    return _GradientFallback(catalogUrl: catalogUrl);
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback({this.catalogUrl});

  final String? catalogUrl;

  @override
  Widget build(BuildContext context) {
    if (catalogUrl != null) {
      return Image.network(
        catalogUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const _PlainGradientFallback(),
      );
    }
    return const _PlainGradientFallback();
  }
}

class _PlainGradientFallback extends StatelessWidget {
  const _PlainGradientFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B3127), Color(0xFF8C765F)],
        ),
      ),
    );
  }
}

class _VideoBackdrop extends StatefulWidget {
  const _VideoBackdrop({super.key, required this.url, this.fallbackUrl});

  final String url;
  final String? fallbackUrl;

  @override
  State<_VideoBackdrop> createState() => _VideoBackdropState();
}

class _VideoBackdropState extends State<_VideoBackdrop> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          unawaited(_controller.play());
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return _GradientFallback(catalogUrl: widget.fallbackUrl);
    }

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

class _ActionRoundButton extends StatelessWidget {
  const _ActionRoundButton({
    required this.icon,
    required this.label,
    this.bgColor = const Color(0x57FFFFFF),
    this.iconColor = Colors.white,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ],
    );
  }
}
