import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../config/app_config.dart';
import 'customer_auth_service.dart';

/// Dialogue de confirmation puis [CustomerAuthService.signOut] (Supabase).
Future<void> presentSignOutFlow(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  if (!AppConfig.isSupabaseConfigured) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.errorSupabaseNotConfigured)),
    );
    return;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.signOutDialogTitle),
      content: Text(l10n.signOutDialogBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.signOutCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.signOutConfirm),
        ),
      ],
    ),
  );

  if (ok != true || !context.mounted) return;

  try {
    await CustomerAuthService.instance.signOut();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
