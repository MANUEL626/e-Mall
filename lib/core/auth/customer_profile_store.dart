import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bootstrap_customer_result.dart';

/// Conserve le dernier profil métier (bootstrap ou PATCH profile) pour l’UI et le disque.
///
/// À appeler après `POST .../bootstrap` et après `PATCH .../customer/profile` avec la réponse JSON.
class CustomerProfileStore extends ChangeNotifier {
  CustomerProfileStore._();

  static final CustomerProfileStore instance = CustomerProfileStore._();

  static const _prefsKey = 'customer_profile_snapshot_v1';

  BootstrapCustomerResult? _profile;
  BootstrapCustomerResult? get profile => _profile;

  /// Enregistre en mémoire et dans [SharedPreferences] (lié à l’utilisateur Auth courant).
  Future<void> setProfile(BootstrapCustomerResult data) async {
    _profile = data;
    notifyListeners();
    await _persist(data);
  }

  Future<void> clear() async {
    _profile = null;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefsKey);
  }

  /// Au démarrage : recharge si une session Supabase existe et que le snapshot correspond au même compte.
  Future<void> restoreFromPrefs() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      await clear();
      return;
    }
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_prefsKey);
    if (raw == null) {
      return;
    }
    try {
      final outer = jsonDecode(raw) as Map<String, dynamic>;
      final authId = outer['auth_user_id'] as String?;
      if (authId != session.user.id) {
        await clear();
        return;
      }
      final map = outer['profile'] as Map<String, dynamic>?;
      if (map == null) {
        await clear();
        return;
      }
      _profile = BootstrapCustomerResult.fromJson(map);
      notifyListeners();
    } catch (_) {
      await p.remove(_prefsKey);
    }
  }

  Future<void> _persist(BootstrapCustomerResult data) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      return;
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _prefsKey,
      jsonEncode({
        'auth_user_id': uid,
        'profile': data.toJson(),
      }),
    );
  }
}
