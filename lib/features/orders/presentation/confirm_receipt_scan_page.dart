import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/catalog/customer_catalog_service.dart';
import '../../../core/commerce/customer_sale_service.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';

/// Scan du QR marchand / livreur puis `POST /api/v1/customer-sales/{order_id}/confirm-receipt`
/// (`guide_api.md` — body `{ "secret", "note?" }`, QR parse via [SaleQrPayload] côté service).
class ConfirmReceiptScanPage extends StatefulWidget {
  const ConfirmReceiptScanPage({
    super.key,
    this.expectedOrderId,
    this.prefilledQrPayload,
    this.autoSubmitFromDeepLink = false,
  });

  /// Si renseigné (écran détail commande), le QR doit correspondre à cette commande.
  final String? expectedOrderId;

  /// Ligne `emall:order:…` (souvent issue d’un lien `emall://order/…/…`).
  final String? prefilledQrPayload;

  /// Si vrai + [prefilledQrPayload] non vide : tentative de confirmation API au chargement.
  final bool autoSubmitFromDeepLink;

  @override
  State<ConfirmReceiptScanPage> createState() => _ConfirmReceiptScanPageState();
}

class _ConfirmReceiptScanPageState extends State<ConfirmReceiptScanPage> {
  late final MobileScannerController _scannerController;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _manualController = TextEditingController();

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
    final pre = widget.prefilledQrPayload?.trim();
    if (widget.autoSubmitFromDeepLink && pre != null && pre.isNotEmpty) {
      _manualController.text = pre;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_confirmFromDeepLink(pre));
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _noteController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _confirmFromDeepLink(String trimmed) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _executeConfirm(trimmed);
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _busy = false);
    } on StateError {
      if (mounted) setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _busy = false);
    }
  }

  Future<void> _executeConfirm(String trimmed) async {
    final l10n = AppLocalizations.of(context)!;

    if (!AppConfig.isApiConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorApiNotConfigured)));
      throw StateError('no-api');
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorSessionMissing)));
      throw StateError('no-session');
    }

    final note = _noteController.text.trim();
    await CustomerSaleService.instance.confirmReceiptFromQrScan(
      accessToken: session.accessToken,
      scannedRaw: trimmed,
      expectedOrderId: widget.expectedOrderId,
      note: note.isEmpty ? null : note,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.orderConfirmReceiptSuccess)),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _processCamera(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      setState(() => _busy = false);
      return;
    }

    await _scannerController.stop();

    try {
      await _executeConfirm(trimmed);
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _busy = false);
      await _scannerController.start();
    } on StateError {
      setState(() => _busy = false);
      await _scannerController.start();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _busy = false);
      await _scannerController.start();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy) return;
    final codes = capture.barcodes;
    if (codes.isEmpty) return;
    final b = codes.first;
    final raw = b.rawValue ?? b.displayValue;
    if (raw == null || raw.isEmpty) return;

    _busy = true;
    setState(() {});
    unawaited(_processCamera(raw));
  }

  Future<void> _processManual() async {
    if (_busy) return;
    final trimmed = _manualController.text.trim();
    if (trimmed.isEmpty) return;

    setState(() => _busy = true);

    try {
      await _executeConfirm(trimmed);
    } on CatalogApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _busy = false);
    } on StateError {
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderConfirmReceiptTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              l10n.orderConfirmReceiptHint,
              style: const TextStyle(color: Color(0xFF6D513E)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _noteController,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: l10n.orderConfirmReceiptNoteLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l10n.orderScannerWebHint,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6D513E)),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) {
                        final msg = error.errorDetails?.message ?? error.toString();
                        return ColoredBox(
                          color: Colors.black87,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                msg,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_busy)
                      const ColoredBox(
                        color: Color(0x66000000),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _manualController,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: l10n.orderManualQrLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 4,
              autocorrect: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton.icon(
              onPressed: _busy ? null : () => unawaited(_processManual()),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.orderManualQrSubmit),
            ),
          ),
        ],
      ),
    );
  }
}
