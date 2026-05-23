import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppFeedbackLevel { info, warning, error, success }

class AppFeedbackMessage {
  const AppFeedbackMessage({
    required this.text,
    this.level = AppFeedbackLevel.info,
  });

  final String text;
  final AppFeedbackLevel level;
}

class AppFeedback {
  const AppFeedback._();

  static String userErrorMessage(Object error, {String? fallback}) {
    final raw = error.toString().trim();
    final lower = raw.toLowerCase();

    if (raw.isEmpty) {
      return fallback ?? 'Une erreur est survenue. Veuillez reessayer.';
    }

    if (lower.contains('api_base_url')) {
      return 'Le service est momentanement indisponible. Veuillez reessayer plus tard.';
    }

    if (lower.contains('session absente') ||
        lower.contains('session missing') ||
        lower.contains('jwt') ||
        lower.contains('401') ||
        lower.contains('unauthorized')) {
      return 'Votre session a expire. Reconnectez-vous pour continuer.';
    }

    if (lower.contains('clientexception') ||
        lower.contains('socketexception') ||
        lower.contains('connection closed') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('network unreachable') ||
        lower.contains('connection reset') ||
        lower.contains('timed out') ||
        lower.contains('timeout') ||
        lower.contains('xmlhttprequest error')) {
      return 'Connexion instable. Verifiez votre connexion internet, puis reessayez.';
    }

    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('internal server error') ||
        lower.contains('bad gateway') ||
        lower.contains('service unavailable')) {
      return 'Le service rencontre un probleme temporaire. Veuillez reessayer dans un instant.';
    }

    if (lower.contains('404') || lower.contains('not found')) {
      return 'Ce contenu est indisponible ou a ete retire.';
    }

    if (lower.contains('409') ||
        lower.contains('conflict') ||
        lower.contains('deja utilise')) {
      return 'Cette information est deja utilisee. Essayez une autre valeur.';
    }

    if (raw.startsWith('{') || raw.startsWith('[') || raw.contains('https://')) {
      return fallback ?? 'Impossible de charger les donnees. Veuillez reessayer.';
    }

    if (raw.length > 140) {
      return fallback ?? 'Une erreur est survenue. Veuillez reessayer.';
    }

    return raw;
  }

  static AppFeedbackMessage locationError(Object error) {
    final code = error is PlatformException ? error.code : '';
    final raw = error.toString().toLowerCase();

    if (code == 'LOCATION_SERVICES_DISABLED' ||
        raw.contains('location_services_disabled') ||
        raw.contains('location services are disabled')) {
      return const AppFeedbackMessage(
        level: AppFeedbackLevel.warning,
        text: 'Le telephone ne fournit pas encore la position. Verifiez que la localisation est activee, puis reessayez.',
      );
    }

    if (code == 'PERMISSION_DENIED' ||
        raw.contains('permission_denied') ||
        raw.contains('autorisation de localisation refusee')) {
      return const AppFeedbackMessage(
        level: AppFeedbackLevel.warning,
        text: 'Autorisez la localisation pour utiliser votre position actuelle.',
      );
    }

    if (code == 'PERMISSION_DENIED_NEVER_ASK' ||
        raw.contains('deniedforever') ||
        raw.contains('bloquee')) {
      return const AppFeedbackMessage(
        level: AppFeedbackLevel.warning,
        text: 'La localisation est bloquee pour cette app. Ouvrez les parametres pour l autoriser.',
      );
    }

    if (raw.contains('timeout') || raw.contains('indisponible')) {
      return const AppFeedbackMessage(
        level: AppFeedbackLevel.warning,
        text: 'Impossible de trouver votre position pour le moment. Verifiez le GPS et reessayez.',
      );
    }

    return const AppFeedbackMessage(
      level: AppFeedbackLevel.error,
      text: 'La position actuelle est indisponible. Vous pouvez choisir un point sur la carte.',
    );
  }

  static AppFeedbackMessage error(String text) {
    return AppFeedbackMessage(level: AppFeedbackLevel.error, text: text);
  }

  static AppFeedbackMessage warning(String text) {
    return AppFeedbackMessage(level: AppFeedbackLevel.warning, text: text);
  }

  static AppFeedbackMessage success(String text) {
    return AppFeedbackMessage(level: AppFeedbackLevel.success, text: text);
  }

  static void show(
    BuildContext context,
    AppFeedbackMessage message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final colors = _colors(message.level);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.background,
          content: Row(
            children: [
              Icon(_icon(message.level), color: colors.foreground, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message.text,
                  style: TextStyle(color: colors.foreground),
                ),
              ),
            ],
          ),
          action: actionLabel == null || onAction == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  textColor: colors.action,
                  onPressed: onAction,
                ),
        ),
      );
  }

  static _FeedbackColors _colors(AppFeedbackLevel level) {
    switch (level) {
      case AppFeedbackLevel.success:
        return const _FeedbackColors(
          background: Color(0xFF0F5132),
          foreground: Colors.white,
          action: Color(0xFFCFF8DC),
        );
      case AppFeedbackLevel.warning:
        return const _FeedbackColors(
          background: Color(0xFF5F3B00),
          foreground: Colors.white,
          action: Color(0xFFFFD58A),
        );
      case AppFeedbackLevel.error:
        return const _FeedbackColors(
          background: Color(0xFF8C1D18),
          foreground: Colors.white,
          action: Color(0xFFFFDAD6),
        );
      case AppFeedbackLevel.info:
        return const _FeedbackColors(
          background: Color(0xFF24435C),
          foreground: Colors.white,
          action: Color(0xFFCBE6FF),
        );
    }
  }

  static IconData _icon(AppFeedbackLevel level) {
    switch (level) {
      case AppFeedbackLevel.success:
        return Icons.check_circle_outline;
      case AppFeedbackLevel.warning:
        return Icons.warning_amber_rounded;
      case AppFeedbackLevel.error:
        return Icons.error_outline;
      case AppFeedbackLevel.info:
        return Icons.info_outline;
    }
  }
}

class _FeedbackColors {
  const _FeedbackColors({
    required this.background,
    required this.foreground,
    required this.action,
  });

  final Color background;
  final Color foreground;
  final Color action;
}
