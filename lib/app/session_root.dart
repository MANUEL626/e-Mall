import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth/auth_service.dart';
import '../core/config/app_config.dart';
import '../features/onboarding/presentation/onboarding_flow_page.dart';
import '../features/shell/presentation/main_shell_page.dart';

/// Racine : accueil si session Supabase restaurée + flux déjà complété sur l’appareil, sinon onboarding.
class SessionRoot extends StatefulWidget {
  const SessionRoot({super.key});

  @override
  State<SessionRoot> createState() => _SessionRootState();
}

enum _SessionTarget { loading, onboarding, mainShell }

class _SessionRootState extends State<SessionRoot> with WidgetsBindingObserver {
  _SessionTarget _target = _SessionTarget.loading;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthGateService.registerMainHandler(_onAuthFlowCompleted);
    unawaited(_bootstrap());
    if (AppConfig.isSupabaseConfigured) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (!mounted) return;
        if (data.event == AuthChangeEvent.signedOut) {
          unawaited(_onSignedOut());
        } else {
          unawaited(_refreshTargetFromSession());
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshTargetFromSession());
    }
  }

  void _onAuthFlowCompleted() {
    if (!mounted) return;
    _applyTarget(_SessionTarget.mainShell);
  }

  Future<void> _bootstrap() async {
    await _refreshTargetFromSession();
    // Second passage : le recover async du SDK ou le stream auth peut arriver après le premier build.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await _refreshTargetFromSession();
    });
  }

  Future<void> _onSignedOut() async {
    await AuthEntryPrefs.setAuthFlowDone(false);
    if (!mounted) return;
    _applyTarget(_SessionTarget.onboarding);
  }

  Future<void> _refreshTargetFromSession() async {
    if (!AppConfig.isSupabaseConfigured) {
      _applyTarget(_SessionTarget.onboarding);
      return;
    }
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _applyTarget(_SessionTarget.onboarding);
      return;
    }
    final done = await AuthEntryPrefs.isAuthFlowDone();
    if (!mounted) return;
    _applyTarget(done ? _SessionTarget.mainShell : _SessionTarget.onboarding);
  }

  void _applyTarget(_SessionTarget next) {
    if (_target == next) return;
    setState(() => _target = next);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthGateService.unregisterMainHandler();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_target) {
      case _SessionTarget.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case _SessionTarget.mainShell:
        return const MainShellPage();
      case _SessionTarget.onboarding:
        return const OnboardingFlowPage();
    }
  }
}
