import 'package:shared_preferences/shared_preferences.dart';

/// Indique que l’utilisateur a terminé le flux onboarding / connexion au moins une fois sur cet appareil.
/// Utilisé avec une session Supabase restaurée pour ouvrir directement l’accueil.
class AuthEntryPrefs {
  AuthEntryPrefs._();

  static const _kAuthFlowDone = 'emall_customer_auth_flow_done';

  static Future<bool> isAuthFlowDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kAuthFlowDone) ?? false;
  }

  static Future<void> setAuthFlowDone(bool value) async {
    final p = await SharedPreferences.getInstance();
    if (value) {
      await p.setBool(_kAuthFlowDone, true);
    } else {
      await p.remove(_kAuthFlowDone);
    }
  }
}
