import 'auth_entry_prefs.dart';

/// Point d’accès sans dépendance vers [SessionRoot] (évite import circulaire onboarding ↔ session_root).
class AuthGateService {
  AuthGateService._();

  static void Function()? _onCompleteToMain;

  static void registerMainHandler(void Function() onCompleteToMain) {
    _onCompleteToMain = onCompleteToMain;
  }

  static void unregisterMainHandler() {
    _onCompleteToMain = null;
  }

  /// À appeler quand l’utilisateur a terminé connexion / profil (équivalent ancien push vers l’accueil).
  static Future<void> completeAuthFlowToMain() async {
    await AuthEntryPrefs.setAuthFlowDone(true);
    _onCompleteToMain?.call();
  }
}
