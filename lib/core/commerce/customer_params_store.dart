import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'customer_sale_models.dart';

/// Conserve les paramètres customer (`/api/v1/customers/me/params`) pour l'UI.
class CustomerParamsStore extends ChangeNotifier {
  CustomerParamsStore._();

  static final CustomerParamsStore instance = CustomerParamsStore._();

  static const _prefsKey = 'customer_params_snapshot_v1';

  CustomerMeParams? _params;
  CustomerMeParams? get params => _params;

  Future<void> setParams(CustomerMeParams data) async {
    _params = data;
    notifyListeners();
    await _persist(data);
  }

  Future<void> clear() async {
    _params = null;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefsKey);
  }

  Future<void> restoreFromPrefs() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      await clear();
      return;
    }

    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_prefsKey);
    if (raw == null) return;

    try {
      final outer = jsonDecode(raw) as Map<String, dynamic>;
      final authId = outer['auth_user_id'] as String?;
      if (authId != session.user.id) {
        await clear();
        return;
      }
      final map = outer['params'] as Map<String, dynamic>?;
      if (map == null) {
        await clear();
        return;
      }
      _params = CustomerMeParams.fromJson(map);
      notifyListeners();
    } catch (_) {
      await p.remove(_prefsKey);
    }
  }

  Future<void> _persist(CustomerMeParams data) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final p = await SharedPreferences.getInstance();
    await p.setString(
      _prefsKey,
      jsonEncode({
        'auth_user_id': uid,
        'params': data.toJson(),
      }),
    );
  }
}
