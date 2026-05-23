import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/cart/cart_service.dart';
import '../../../services/catalog/catalog_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../services/news/news_service.dart';
import '../../../services/organizations/organizations_service.dart';
import '../../../l10n/app_localizations.dart';
import 'merchant_organization_page.dart';
import 'new_feed_search_page.dart';

class NewFeedPage extends StatefulWidget {
  const NewFeedPage({
    super.key,
    this.initialArticleId,
    this.isVisible = true,
  });

  final String? initialArticleId;
  final bool isVisible;

  @override
  State<NewFeedPage> createState() => _NewFeedPageState();
}

class _NewFeedPageCache {
  static List<ArticlePostFeedItem> items = <ArticlePostFeedItem>[];
  static int total = 0;
  static int nextOffset = 0;
  static int currentPageIndex = 0;
  static bool mayHaveMorePosts = true;
  static Set<String> wishlistArticleIds = <String>{};
  static Set<String> subscribedOrgIds = <String>{};
  static Set<String> cartTouchedArticleIds = <String>{};

  static bool get hasData => items.isNotEmpty;
}

class _NewFeedPageState extends State<NewFeedPage> {
  static const int _pageSize = 12;

  final PageController _pageController = PageController();

  List<ArticlePostFeedItem> _items = [];
  int _total = 0;
  int _nextFeedOffset = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _mayHaveMorePosts = true;
  bool _endSwipeProbeTried = false;
  String? _error;
  int _currentPageIndex = 0;

  final Set<String> _wishlistArticleIds = <String>{};
  final Set<String> _subscribedOrgIds = <String>{};
  final Set<String> _cartTouchedArticleIds = <String>{};
  String? _pendingArticleId;
  Timer? _realtimeRefreshDebounce;
  RealtimeChannel? _postsChannel;
  bool _realtimeRefreshInFlight = false;
  int _feedRequestSequence = 0;

  @override
  void initState() {
    super.initState();
    _pendingArticleId = widget.initialArticleId;
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final restored = _restoreCachedState();
    _subscribeToPostUpdates();
    if (restored) {
      _focusPendingArticle();
      unawaited(_loadFeed(reset: true, silent: true));
      unawaited(_refreshSideData());
      return;
    }

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
      _saveCachedState();
    } catch (_) {
      // Silencieux : le feed peut fonctionner sans ces listes.
    }
  }

  @override
  void dispose() {
    _realtimeRefreshDebounce?.cancel();
    final channel = _postsChannel;
    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }
    _pageController.dispose();
    super.dispose();
  }

  bool _restoreCachedState() {
    if (!_NewFeedPageCache.hasData) return false;
    _items = List<ArticlePostFeedItem>.from(_NewFeedPageCache.items);
    _total = _NewFeedPageCache.total;
    _nextFeedOffset = _NewFeedPageCache.nextOffset > 0
        ? _NewFeedPageCache.nextOffset
        : _items.length;
    _mayHaveMorePosts = _NewFeedPageCache.mayHaveMorePosts || _items.isNotEmpty;
    _currentPageIndex = _NewFeedPageCache.currentPageIndex.clamp(0, _items.length - 1).toInt();
    _wishlistArticleIds
      ..clear()
      ..addAll(_NewFeedPageCache.wishlistArticleIds);
    _subscribedOrgIds
      ..clear()
      ..addAll(_NewFeedPageCache.subscribedOrgIds);
    _cartTouchedArticleIds
      ..clear()
      ..addAll(_NewFeedPageCache.cartTouchedArticleIds);
    _loading = false;
    _error = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients || _currentPageIndex <= 0) return;
      _pageController.jumpToPage(_currentPageIndex);
    });
    return true;
  }

  void _saveCachedState() {
    _NewFeedPageCache.items = List<ArticlePostFeedItem>.from(_items);
    _NewFeedPageCache.total = _total;
    _NewFeedPageCache.nextOffset = _nextFeedOffset;
    _NewFeedPageCache.currentPageIndex = _currentPageIndex;
    _NewFeedPageCache.mayHaveMorePosts = _mayHaveMorePosts;
    _NewFeedPageCache.wishlistArticleIds = Set<String>.from(_wishlistArticleIds);
    _NewFeedPageCache.subscribedOrgIds = Set<String>.from(_subscribedOrgIds);
    _NewFeedPageCache.cartTouchedArticleIds = Set<String>.from(_cartTouchedArticleIds);
  }

  void _subscribeToPostUpdates() {
    if (_postsChannel != null) return;
    if (!AppConfig.isSupabaseConfigured) return;
    if (Supabase.instance.client.auth.currentSession == null) return;

    final channel = Supabase.instance.client.channel(
      'customer-post-feed-${identityHashCode(this)}',
    );
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'organization_article_posts',
          callback: (_) => _scheduleRealtimeRefresh(),
        )
        .subscribe();
    _postsChannel = channel;
  }

  void _scheduleRealtimeRefresh() {
    if (!mounted) return;
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted || _realtimeRefreshInFlight) return;
      _realtimeRefreshInFlight = true;
      try {
        await _loadFeed(reset: true, silent: true);
      } finally {
        _realtimeRefreshInFlight = false;
      }
    });
  }

  bool get _hasMorePosts {
    if (_items.isEmpty) return false;
    if (_total > 0 && _items.length < _total) return true;
    return _mayHaveMorePosts;
  }

  bool get _showLoadMorePage =>
      _hasMorePosts ||
      _loadingMore ||
      (_error != null && _items.isNotEmpty) ||
      (!_endSwipeProbeTried && _items.isNotEmpty);

  Future<void> _loadFeed({
    required bool reset,
    bool silent = false,
    bool forceEndProbe = false,
  }) async {
    if (!AppConfig.isApiConfigured) {
      if (silent && _items.isNotEmpty) return;
      setState(() {
        _loading = false;
        _error = 'API_BASE_URL non configurée (dart-define).';
      });
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (silent && _items.isNotEmpty) return;
      setState(() {
        _loading = false;
        _error = 'Session absente. Reconnectez-vous.';
      });
      return;
    }

    if (_loadingMore && !reset) return;
    if (reset && silent && _loadingMore) return;
    if (!reset && !_hasMorePosts) {
      if (!forceEndProbe || _endSwipeProbeTried) return;
    }

    final requestSequence = ++_feedRequestSequence;
    final offset = reset ? 0 : _nextFeedOffset;
    final limit = reset && silent && _items.isNotEmpty
        ? math.min(math.max(_nextFeedOffset, _pageSize), 100)
        : _pageSize;
    if (kDebugMode) {
      debugPrint(
        'NEW_FEED_LOAD start reset=$reset silent=$silent '
        'offset=$offset limit=$limit current=${_items.length} '
        'next=$_nextFeedOffset total=$_total hasMore=$_hasMorePosts',
      );
    }
    if (reset) {
      if (!silent || _items.isEmpty) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }
    } else {
      setState(() {
        _loadingMore = true;
        _error = null;
        if (forceEndProbe) _endSwipeProbeTried = true;
      });
    }

    try {
      final token = session.accessToken;
      final page = await CustomerFeedService.instance.postsFeed(
        accessToken: token,
        limit: limit,
        offset: offset,
      );

      if (!mounted) return;
      if (reset && silent && requestSequence != _feedRequestSequence) {
        if (kDebugMode) {
          debugPrint(
            'NEW_FEED_LOAD ignored stale silent reset '
            'request=$requestSequence latest=$_feedRequestSequence',
          );
        }
        return;
      }
      setState(() {
        _total = page.total;
        final effectiveLimit = page.limit > 0 ? page.limit : _pageSize;
        final receivedCount = page.items.length;
        final knownTotalHasMore = page.total > 0 &&
            (offset + receivedCount) < page.total;
        final pageLooksFull = receivedCount >= effectiveLimit;
        _nextFeedOffset = offset + receivedCount;
        if (reset) {
          _items = List<ArticlePostFeedItem>.from(page.items);
          _currentPageIndex = _items.isEmpty
              ? 0
              : _currentPageIndex.clamp(0, _items.length - 1).toInt();
          _mayHaveMorePosts = receivedCount > 0;
          _endSwipeProbeTried = false;
        } else {
          _items = [..._items, ...page.items];
          _mayHaveMorePosts = receivedCount > 0 &&
              (knownTotalHasMore || pageLooksFull || receivedCount > 0);
          if (receivedCount > 0) _endSwipeProbeTried = false;
        }
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
      if (kDebugMode) {
        debugPrint(
          'NEW_FEED_LOAD done reset=$reset silent=$silent '
          'received=${page.items.length} items=${_items.length} '
          'next=$_nextFeedOffset total=$_total hasMore=$_hasMorePosts',
        );
      }
      _saveCachedState();
      _focusPendingArticle();
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

  void _focusPendingArticle() {
    final target = _pendingArticleId;
    if (target == null || target.isEmpty) return;

    final index = _items.indexWhere((item) => item.organizationArticleId == target);
    if (index >= 0) {
      _pendingArticleId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_pageController.hasClients) return;
        _pageController.jumpToPage(index);
      });
      return;
    }

    if (_total > 0 && _items.length < _total && !_loadingMore) {
      unawaited(_loadFeed(reset: false));
    } else {
      _pendingArticleId = null;
      if (widget.initialArticleId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final nav = Navigator.of(context);
          if (nav.canPop()) nav.pop();
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPageIndex = index);
    _saveCachedState();
    if (_loadingMore || _error != null) return;
    if (index >= _items.length) {
      final canProbeEnd = !_hasMorePosts && !_endSwipeProbeTried;
      if (_hasMorePosts || canProbeEnd) {
        unawaited(_loadFeed(reset: false, forceEndProbe: canProbeEnd));
      }
    }
  }

  void _retryLoadMore() {
    if (_loadingMore) return;
    setState(() => _error = null);
    final canProbeEnd = !_hasMorePosts && !_endSwipeProbeTried;
    if (_hasMorePosts || canProbeEnd) {
      unawaited(_loadFeed(reset: false, forceEndProbe: canProbeEnd));
    }
  }

  bool _handleFeedScrollNotification(ScrollNotification notification) {
    if (_items.isEmpty || _loadingMore || _error != null) return false;
    if (notification.metrics.axis != Axis.vertical) return false;

    final atBottom = notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 8;
    final isBottomOverscroll = notification is OverscrollNotification &&
        notification.overscroll > 0 &&
        atBottom;
    final endedAtBottom = notification is ScrollEndNotification && atBottom;

    if (isBottomOverscroll || endedAtBottom) {
      final canProbeEnd = !_hasMorePosts && !_endSwipeProbeTried;
      if (_hasMorePosts || canProbeEnd) {
        unawaited(_loadFeed(reset: false, forceEndProbe: canProbeEnd));
      }
    }
    return false;
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
        _saveCachedState();
      } else {
        await CustomerShoppingService.instance.addWishlistItem(
          accessToken: session.accessToken,
          organizationArticleId: id,
        );
        if (!mounted) return;
        setState(() => _wishlistArticleIds.add(id));
        _saveCachedState();
      }
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      AppFeedback.show(context, AppFeedback.error(AppFeedback.userErrorMessage(e.message)));
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
      _saveCachedState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.snackAddedToCart)),
      );
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      AppFeedback.show(context, AppFeedback.error(AppFeedback.userErrorMessage(e.message)));
    }
  }

  String _shareLinkFor(ArticlePostFeedItem item) {
    final base = AppConfig.shareBaseUrl.trim();
    if (base.startsWith('http://') || base.startsWith('https://')) {
      final baseUri = Uri.parse(base.endsWith('/') ? base : '$base/');
      return baseUri.replace(
        pathSegments: [
          ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
          'new',
          item.organizationArticleId,
        ],
      ).toString();
    }

    return Uri(
      scheme: 'emall',
      host: 'new',
      pathSegments: [item.organizationArticleId],
    ).toString();
  }

  String _formatSharePrice(String raw) {
    final n = num.tryParse(raw.trim());
    if (n == null) return raw.trim();
    final value = n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
    final chars = value.split('').reversed.toList();
    final out = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) out.write(' ');
      out.write(chars[i]);
    }
    return out.toString().split('').reversed.join();
  }

  String _sharePriceLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Prix non precise';
    if (RegExp(r'[A-Za-z]').hasMatch(trimmed)) return trimmed;
    return '${_formatSharePrice(trimmed)} FCFA';
  }

  String _shareTextFor(ArticlePostFeedItem item) {
    final link = _shareLinkFor(item);
    final price = _sharePriceLabel(item.unitSalePrice);
    return 'e-Mall - Article a decouvrir\n\n'
        'Article : ${item.name}\n'
        'Prix : $price\n\n'
        'Ouvrir dans l application :\n'
        '$link';
  }

  Future<void> _shareNew(ArticlePostFeedItem item) async {
    final link = _shareLinkFor(item);
    final text = _shareTextFor(item);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: height < 620 ? 0.88 : 0.58,
          minChildSize: 0.36,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return GridView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                mainAxisExtent: 92,
              ),
              children: [
                _ShareTargetTile(
                  asset: 'assets/image/whatsapp-icon.svg',
                  label: 'WhatsApp',
                  onTap: () => _openShareTarget(
                    sheetContext,
                    'whatsapp://send?text=${Uri.encodeComponent(text)}',
                  ),
                ),
                _ShareTargetTile(
                  asset: 'assets/image/telegram.svg',
                  label: 'Telegram',
                  onTap: () => _openShareTarget(
                    sheetContext,
                    'tg://msg?text=${Uri.encodeComponent(text)}',
                  ),
                ),
                _ShareTargetTile(
                  asset: 'assets/image/share-email.png',
                  label: 'Mail',
                  onTap: () => _openShareTarget(
                    sheetContext,
                    Uri(
                      scheme: 'mailto',
                      queryParameters: {
                        'subject': item.name,
                        'body': text,
                      },
                    ).toString(),
                  ),
                ),
                _ShareTargetTile(
                  asset: 'assets/image/instagram-icon.svg',
                  label: 'Instagram',
                  onTap: () => _openShareTarget(
                    sheetContext,
                    'instagram://app',
                    copyBeforeOpen: link,
                  ),
                ),
                _ShareTargetTile(
                  asset: 'assets/image/snapchat.svg',
                  label: 'Snapchat',
                  onTap: () => _openShareTarget(
                    sheetContext,
                    'snapchat://',
                    copyBeforeOpen: link,
                  ),
                ),
                _ShareTargetTile(
                  asset: 'assets/image/TikTok_dark.svg',
                  label: 'TikTok',
                  onTap: () => _openShareTarget(
                    sheetContext,
                    'tiktok://',
                    copyBeforeOpen: link,
                  ),
                ),
                _ShareTargetTile(
                  asset: 'assets/image/messenger.svg',
                  label: 'Messenger',
                  onTap: () => _openShareTarget(
                    sheetContext,
                    'fb-messenger://share?link=${Uri.encodeComponent(link)}',
                    copyBeforeOpen: link,
                  ),
                ),
                _ShareTargetTile(
                  asset: 'assets/image/linkedin.svg',
                  label: 'LinkedIn',
                  onTap: () => _openShareTarget(
                    sheetContext,
                    'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(link)}',
                  ),
                ),
                _ShareTargetTile(
                  asset: 'assets/image/share-copy.png',
                  label: 'Copier',
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lien copie.')),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openShareTarget(
    BuildContext sheetContext,
    String rawUri, {
    String? copyBeforeOpen,
  }) async {
    if (copyBeforeOpen != null) {
      await Clipboard.setData(ClipboardData(text: copyBeforeOpen));
    }
    final uri = Uri.parse(rawUri);
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!sheetContext.mounted) return;
    Navigator.of(sheetContext).pop();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune application compatible trouvee.')),
      );
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
              NotificationListener<ScrollNotification>(
                onNotification: _handleFeedScrollNotification,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _onPageChanged,
                  itemCount: _items.length + (_showLoadMorePage ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _items.length) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted || _loadingMore || _error != null) {
                          return;
                        }
                        final canProbeEnd = !_hasMorePosts && !_endSwipeProbeTried;
                        if (_hasMorePosts || canProbeEnd) {
                          unawaited(_loadFeed(reset: false, forceEndProbe: canProbeEnd));
                        }
                      });
                      return _FeedLoadingMoreItem(
                        error: _error,
                        onRetry: _retryLoadMore,
                      );
                    }

                    final item = _items[index];
                    final inWishlist = _wishlistArticleIds.contains(item.organizationArticleId);
                    final inCartHint = _cartTouchedArticleIds.contains(item.organizationArticleId);
                    return _FeedFullScreenItem(
                      item: item,
                      isActive: widget.isVisible && index == _currentPageIndex,
                      isLiked: inWishlist,
                      isAdded: inCartHint,
                      isFollowingMerchant: _subscribedOrgIds.contains(item.organizationId),
                      onLikeTap: () => unawaited(_toggleWishlist(item)),
                      onAddTap: () => unawaited(_addToCart(item)),
                      onShareTap: () => unawaited(_shareNew(item)),
                      onMerchantTap: () => _openMerchant(item),
                    );
                  },
                ),
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

class _FeedLoadingMoreItem extends StatelessWidget {
  const _FeedLoadingMoreItem({
    required this.error,
    required this.onRetry,
  });

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final errorText = error;
    if (errorText != null && errorText.isNotEmpty) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  errorText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(AppLocalizations.of(context)!.retryButton),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFFF3D4BE)),
      ),
    );
  }
}

class _ShareTargetTile extends StatelessWidget {
  const _ShareTargetTile({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSvg = asset.toLowerCase().endsWith('.svg');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSvg)
              SvgPicture.asset(
                asset,
                width: 42,
                height: 42,
                placeholderBuilder: (_) => const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.share_outlined, size: 36),
                ),
              )
            else
              Image.asset(
                asset,
                width: 42,
                height: 42,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.share_outlined, size: 36),
              ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedFullScreenItem extends StatelessWidget {
  const _FeedFullScreenItem({
    required this.item,
    required this.isActive,
    required this.isLiked,
    required this.isAdded,
    required this.isFollowingMerchant,
    required this.onLikeTap,
    required this.onAddTap,
    required this.onShareTap,
    required this.onMerchantTap,
  });

  final ArticlePostFeedItem item;
  final bool isActive;
  final bool isLiked;
  final bool isAdded;
  final bool isFollowingMerchant;
  final VoidCallback onLikeTap;
  final VoidCallback onAddTap;
  final VoidCallback onShareTap;
  final VoidCallback onMerchantTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _FeedBackdrop(item: item, isActive: isActive),
        IgnorePointer(
          child: DecoratedBox(
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
        ),
        Positioned(
          right: 14,
          bottom: 156,
          child: Column(
            children: [
              _ActionRoundButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: 'WISHLIST',
                bgColor: isLiked ? const Color(0xFFF47A2B) : const Color(0x57FFFFFF),
                iconColor: Colors.white,
                onTap: onLikeTap,
              ),
              const SizedBox(height: 12),
              _ActionRoundButton(
                icon: Icons.shopping_cart,
                label: 'ADD',
                bgColor: isAdded ? const Color(0xFFF47A2B) : const Color(0x57FFFFFF),
                iconColor: Colors.white,
                onTap: onAddTap,
              ),
              const SizedBox(height: 12),
              _ActionRoundButton(icon: Icons.share, label: '', onTap: onShareTap),
            ],
          ),
        ),
        Positioned(
          left: 18,
          right: 74,
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
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD98652),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.storefront, color: Colors.white, size: 19),
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
                                    fontSize: 14,
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
                              fontSize: 12,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 6),
              if (_subtitleLine(item).isNotEmpty)
                Text(
                  _subtitleLine(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE3DCD7),
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                item.unitSalePrice,
                style: const TextStyle(
                  color: Color(0xFFF47A2B),
                  fontSize: 24,
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
  const _FeedBackdrop({required this.item, required this.isActive});

  final ArticlePostFeedItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final mediaPath =
        item.isVideo ? item.preferredVideoStoragePath : item.mediaStoragePath;
    final postUrl = publicUrlForPostMedia(mediaPath.isNotEmpty ? mediaPath : null);
    final thumbnailUrl = publicUrlForPostMedia(item.thumbnailStoragePath);
    final catalogUrl = publicUrlForCatalogImage(item.primaryImageStoragePath);

    if (item.isVideo) {
      if (kDebugMode) {
        debugPrint('NEW_VIDEO mediaKind=${item.mediaKind}');
        debugPrint('NEW_VIDEO processingStatus=${item.processingStatus}');
        debugPrint('NEW_VIDEO mediaStoragePath=${item.mediaStoragePath}');
        debugPrint('NEW_VIDEO mobileLow=${item.videoMobileLowStoragePath}');
        debugPrint('NEW_VIDEO selectedPath=$mediaPath');
        debugPrint('NEW_VIDEO finalUrl=$postUrl');
        debugPrint('NEW_VIDEO isActive=$isActive isReady=${item.isVideoReady}');
      }
      final fallbackUrl = thumbnailUrl ?? catalogUrl;
      if (item.isVideoReady && postUrl != null && isActive) {
        return Stack(
          fit: StackFit.expand,
          children: [
            _NetworkBackdropImage(url: fallbackUrl, fallbackUrl: catalogUrl),
            _VideoBackdrop(
              key: ValueKey<String>(postUrl),
              url: postUrl,
              fallbackUrl: fallbackUrl,
            ),
          ],
        );
      }
      return _NetworkBackdropImage(url: fallbackUrl, fallbackUrl: catalogUrl);
    }

    final imageUrl = postUrl ?? catalogUrl;
    return _NetworkBackdropImage(url: imageUrl, fallbackUrl: catalogUrl);
  }
}

class _NetworkBackdropImage extends StatelessWidget {
  const _NetworkBackdropImage({required this.url, this.fallbackUrl});

  final String? url;
  final String? fallbackUrl;

  @override
  Widget build(BuildContext context) {
    if (url == null) return _GradientFallback(catalogUrl: fallbackUrl);
    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => _GradientFallback(catalogUrl: fallbackUrl),
    );
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
  late final Player _player;
  late final VideoController _controller;
  StreamSubscription<String>? _errorSub;
  bool _videoFailed = false;
  bool _pausedByUser = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('VIDEO_INIT url=${widget.url}');
    }
    _player = Player();
    _controller = VideoController(_player);
    _errorSub = _player.stream.error.listen(_onVideoError);
    unawaited(_initializeVideo());
  }

  void _onVideoError(String error) {
    if (_videoFailed) return;
    if (!mounted) return;
    if (kDebugMode) {
      debugPrint('VIDEO_ERROR $error');
    }
    setState(() => _videoFailed = true);
  }

  Future<void> _initializeVideo() async {
    try {
      await _player.setPlaylistMode(PlaylistMode.loop);
      await _player.open(Media(widget.url), play: true);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('VIDEO_INIT_ERROR $e');
      }
      setState(() => _videoFailed = true);
    }
  }

  Future<void> _play() async {
    try {
      await _player.play();
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('VIDEO_PLAY_ERROR $e');
      }
      setState(() => _videoFailed = true);
    }
  }

  Future<void> _togglePlayback() async {
    if (_videoFailed) return;
    if (!_pausedByUser) {
      await _player.pause();
      if (!mounted) return;
      setState(() => _pausedByUser = true);
      return;
    }

    setState(() => _pausedByUser = false);
    await _play();
  }

  Future<void> _playFrom(Duration position) async {
    if (_videoFailed) return;
    try {
      await _player.seek(position);
      await _player.play();
      if (!mounted) return;
      setState(() => _pausedByUser = false);
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('VIDEO_SEEK_ERROR $e');
      }
      setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    unawaited(_errorSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoFailed) {
      return _GradientFallback(catalogUrl: widget.fallbackUrl);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Video(
          controller: _controller,
          fit: BoxFit.cover,
          controls: NoVideoControls,
        ),
        Positioned.fill(
          bottom: 62,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => unawaited(_togglePlayback()),
          ),
        ),
        Positioned(
          left: 14,
          right: 78,
          bottom: 12,
          child: _VideoInlineControls(
            player: _player,
            pausedByUser: _pausedByUser,
            onPlayPause: () => unawaited(_togglePlayback()),
            onSeek: (position) => unawaited(_playFrom(position)),
          ),
        ),
        if (_pausedByUser)
          IgnorePointer(
            child: const Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x66000000),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoInlineControls extends StatelessWidget {
  const _VideoInlineControls({
    required this.player,
    required this.pausedByUser,
    required this.onPlayPause,
    required this.onSeek,
  });

  final Player player;
  final bool pausedByUser;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.stream.duration,
      initialData: player.state.duration,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: player.stream.position,
          initialData: player.state.position,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final totalMs = duration.inMilliseconds;
            final positionMs = position.inMilliseconds.clamp(0, totalMs).toInt();
            final value = totalMs <= 0 ? 0.0 : positionMs / totalMs;
            final sliderValue = value.clamp(0.0, 1.0).toDouble();

            return DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x99000000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 24,
                        color: Colors.white,
                        onPressed: onPlayPause,
                        icon: Icon(
                          pausedByUser
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: const Color(0xFFF47A2B),
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: sliderValue,
                          onChanged: totalMs <= 0
                              ? null
                              : (next) {
                                  final target = Duration(
                                    milliseconds: (totalMs * next).round(),
                                  );
                                  onSeek(target);
                                },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text(
                        '${_formatVideoTime(position)} / ${_formatVideoTime(duration)}',
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String _formatVideoTime(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = (totalSeconds ~/ 60).toString();
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}
