import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/orders/orders_service.dart';
import '../services/users/users_service.dart';
import '../core/branding/app_branding.dart';
import '../core/config/app_config.dart';
import '../core/locale/app_locale_controller.dart';
import 'session_root.dart';
import '../features/new_feed/presentation/new_feed_page.dart';
import '../features/orders/presentation/confirm_receipt_scan_page.dart';
import '../l10n/app_localizations.dart';

class ECommerceApp extends StatefulWidget {
  const ECommerceApp({super.key});

  @override
  State<ECommerceApp> createState() => _ECommerceAppState();
}

class _ECommerceAppState extends State<ECommerceApp> {
  final GlobalKey<NavigatorState> _rootNavKey = GlobalKey<NavigatorState>();

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<Uri>? _appLinkSub;

  String? _lastDeepLinkRaw;
  DateTime? _lastDeepLinkAt;
  static const _deepLinkDedupWindow = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    unawaited(_restoreUserSnapshots());
    if (AppConfig.isSupabaseConfigured) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedOut) {
          unawaited(CustomerProfileStore.instance.clear());
          unawaited(CustomerParamsStore.instance.clear());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _rootNavKey.currentState?.popUntil((route) => route.isFirst);
          });
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_initAppLinks()));
  }

  Future<void> _restoreUserSnapshots() async {
    await CustomerProfileStore.instance.restoreFromPrefs();
    await CustomerParamsStore.instance.restoreFromPrefs();
    final locale = CustomerParamsStore.instance.params?.locale;
    if (AppLocaleController.isSupported(locale)) {
      await AppLocaleController.instance.setLocale(Locale(locale!.toLowerCase()));
    }
  }

  Future<void> _initAppLinks() async {
    final appLinks = AppLinks();
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) {
        _handleAppLinkUri(initial);
      }
    } catch (_) {}

    await _appLinkSub?.cancel();
    _appLinkSub = appLinks.uriLinkStream.listen(_handleAppLinkUri, onError: (_) {});
  }

  void _handleAppLinkUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final isEmallLink = scheme == 'emall';
    final expectedShareHost = Uri.tryParse(AppConfig.shareBaseUrl)?.host.toLowerCase();
    final isWebShareLink =
        (scheme == 'https' || scheme == 'http') &&
            expectedShareHost != null &&
            uri.host.toLowerCase() == expectedShareHost &&
            uri.pathSegments.length >= 2 &&
            uri.pathSegments[uri.pathSegments.length - 2].toLowerCase() == 'new';
    if (!isEmallLink && !isWebShareLink) return;

    if (uri.host.toLowerCase() == 'new' || isWebShareLink) {
      final raw = uri.toString();
      final now = DateTime.now();
      if (_lastDeepLinkRaw == raw &&
          _lastDeepLinkAt != null &&
          now.difference(_lastDeepLinkAt!) < _deepLinkDedupWindow) {
        return;
      }
      _lastDeepLinkRaw = raw;
      _lastDeepLinkAt = now;

      final articleId = isWebShareLink
          ? uri.pathSegments.last
          : uri.pathSegments.isNotEmpty
              ? uri.pathSegments.first
              : null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final nav = _rootNavKey.currentState;
        if (nav == null) return;
        unawaited(
          nav.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => NewFeedPage(initialArticleId: articleId),
            ),
          ),
        );
      });
      return;
    }

    final normalized = EmallDeepLink.normalizeToQrPayload(uri);
    final payload = SaleQrPayload.tryParse(normalized);
    if (payload == null) return;

    final now = DateTime.now();
    if (_lastDeepLinkRaw == normalized &&
        _lastDeepLinkAt != null &&
        now.difference(_lastDeepLinkAt!) < _deepLinkDedupWindow) {
      return;
    }
    _lastDeepLinkRaw = normalized;
    _lastDeepLinkAt = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = _rootNavKey.currentState;
      if (nav == null) return;
      unawaited(
        nav.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ConfirmReceiptScanPage(
              expectedOrderId: payload.orderId,
              prefilledQrPayload: normalized,
              autoSubmitFromDeepLink: true,
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _appLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const baseBg = Color(0xFFF5ECE7);
    const textPrimary = Color(0xFF3F2413);

    return ListenableBuilder(
      listenable: AppLocaleController.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: _rootNavKey,
          debugShowCheckedModeBanner: false,
          title: AppBranding.appName,
          locale: AppLocaleController.instance.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: baseBg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF26D21),
              primary: const Color(0xFFF26D21),
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              titleLarge: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF6A4A35)),
              bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF7D5D47)),
            ),
          ),
          home: const SessionRoot(),
        );
      },
    );
  }
}
