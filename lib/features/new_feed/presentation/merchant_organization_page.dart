import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/catalog/catalog_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../services/organizations/organizations_service.dart';
import '../../../l10n/app_localizations.dart';

/// Fiche marchand : `GET .../customers/organizations/{id}` + abonnement / désabonnement.
class MerchantOrganizationPage extends StatefulWidget {
  const MerchantOrganizationPage({
    super.key,
    required this.organizationId,
    this.initialName,
  });

  final String organizationId;
  final String? initialName;

  @override
  State<MerchantOrganizationPage> createState() => _MerchantOrganizationPageState();
}

class _MerchantOrganizationPageState extends State<MerchantOrganizationPage> {
  bool _loading = true;
  String? _error;
  OrganizationPreview? _preview;
  bool _subscribed = false;

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

    setState(() {
      _loading = true;
      _error = null;
    });

    final token = session.accessToken;
    final orgSvc = CustomerOrganizationService.instance;

    try {
      final results = await Future.wait<Object>([
        orgSvc.getOrganization(accessToken: token, organizationId: widget.organizationId),
        orgSvc.listSubscriptions(accessToken: token),
      ]);

      final preview = results[0] as OrganizationPreview;
      final subs = results[1] as CustomerSubscriptionsPage;

      final active = subs.items.any(
        (s) =>
            s.organizationId == widget.organizationId && s.status.toLowerCase() == 'active',
      );

      if (!mounted) return;
      setState(() {
        _preview = preview;
        _subscribed = active;
        _loading = false;
      });
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppFeedback.userErrorMessage(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppFeedback.userErrorMessage(e);
      });
    }
  }

  Future<void> _toggleSubscribe() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    final orgSvc = CustomerOrganizationService.instance;
    final token = session.accessToken;

    try {
      if (_subscribed) {
        await orgSvc.unsubscribe(accessToken: token, organizationId: widget.organizationId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.snackSubscriptionCancelled)),
        );
      } else {
        await orgSvc.subscribe(accessToken: token, organizationId: widget.organizationId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.snackFollowingShop)),
        );
      }
      await _load();
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      AppFeedback.show(context, AppFeedback.error(AppFeedback.userErrorMessage(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = _preview?.name ?? widget.initialName ?? l10n.merchantDefaultShopName;
    final subs = _preview?.subscriberCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: Text(l10n.retryButton)),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.subscriberCount(subs),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _toggleSubscribe,
                      icon: Icon(_subscribed ? Icons.person_remove_outlined : Icons.person_add_alt_1_outlined),
                      label: Text(_subscribed ? l10n.unsubscribeButton : l10n.subscribeButton),
                    ),
                  ],
                ),
    );
  }
}
