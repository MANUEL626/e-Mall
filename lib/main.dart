import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/locale/app_locale_controller.dart';

/// Le SDK lance `recoverSession()` en parallèle après [Supabase.initialize] sans l’attendre.
/// Si le JWT stocké est expiré, le refresh peut encore être en cours : on laisse le temps
/// à la session de se stabiliser avant [runApp] pour éviter un premier frame « sans session ».
Future<void> _coalesceSupabaseRecoverAfterInit() async {
  final auth = Supabase.instance.client.auth;
  final s0 = auth.currentSession;
  if (s0 == null) return;
  if (!s0.isExpired) return;
  for (var i = 0; i < 60; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final s = auth.currentSession;
    if (s == null) return;
    if (!s.isExpired) return;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await AppLocaleController.instance.load();

  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    await _coalesceSupabaseRecoverAfterInit();
  }

  runApp(const ECommerceApp());
}
