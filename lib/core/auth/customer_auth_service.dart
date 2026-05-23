import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'bootstrap_customer_result.dart';

/// Flux guide_api.md : OTP via Supabase, profil métier via `POST .../customer/bootstrap`.
class CustomerAuthService {
  CustomerAuthService._();

  static final CustomerAuthService instance = CustomerAuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  String _messageFromErrorBody(String body, String fallback) {
    if (body.isEmpty) return fallback;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
        if (detail is Map && detail['message'] != null) {
          return detail['message'].toString();
        }
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
        }
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        final error = decoded['error'];
        if (error is String && error.trim().isNotEmpty) {
          return error.trim();
        }
      }
    } catch (_) {}
    return body;
  }

  /// Étape 1 — envoi du SMS OTP (GoTrue / Twilio côté Supabase).
  Future<void> signInWithOtp({required String phoneE164}) async {
    await _client.auth.signInWithOtp(phone: phoneE164);
  }

  /// Étape 2 bis — renvoi du code (même numéro).
  Future<void> resendOtp({required String phoneE164}) async {
    await _client.auth.signInWithOtp(phone: phoneE164);
  }

  /// Étape 2 — validation du code ; persiste la session via le SDK.
  Future<Session> verifyOtp({
    required String phoneE164,
    required String codeSixDigits,
  }) async {
    final res = await _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phoneE164,
      token: codeSixDigits,
    );
    final session = res.session;
    if (session == null) {
      throw AuthException('Session absente après verifyOTP');
    }
    return session;
  }

  /// Étape 3 — bootstrap backend FastAPI.
  Future<BootstrapCustomerResult> bootstrapCustomer(
    Session session, {
    Map<String, dynamic>? profile,
  }) async {
    final base = AppConfig.apiBaseUrl.trim();
    if (base.isEmpty) {
      throw CustomerBootstrapException(
        'API_BASE_URL non configurée (dart-define).',
      );
    }
    final uri = Uri.parse(
      '${base.endsWith('/') ? base.substring(0, base.length - 1) : base}'
      '/api/v1/auth/customer/bootstrap',
    );
    final token = session.accessToken;
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(profile ?? <String, dynamic>{}),
    );
    if (resp.statusCode >= 400) {
      throw CustomerBootstrapException(
        _messageFromErrorBody(resp.body, 'Bootstrap échoué'),
        statusCode: resp.statusCode,
      );
    }
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return BootstrapCustomerResult.fromJson(map);
  }

  /// Mise à jour du profil customer (`PATCH`) — réponse JSON alignée sur le bootstrap.
  Future<BootstrapCustomerResult> updateCustomerProfile(
    Session session, {
    required Map<String, dynamic> profile,
  }) async {
    final base = AppConfig.apiBaseUrl.trim();
    if (base.isEmpty) {
      throw CustomerBootstrapException(
        'API_BASE_URL non configurée (dart-define).',
      );
    }
    final uri = Uri.parse(
      '${base.endsWith('/') ? base.substring(0, base.length - 1) : base}'
      '/api/v1/auth/customer/profile',
    );
    final token = session.accessToken;
    final resp = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(profile),
    );
    if (resp.statusCode >= 400) {
      throw CustomerBootstrapException(
        _messageFromErrorBody(resp.body, 'Mise à jour du profil échouée'),
        statusCode: resp.statusCode,
      );
    }
    if (resp.body.isEmpty) {
      throw CustomerBootstrapException('Réponse profil vide');
    }
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return BootstrapCustomerResult.fromJson(map);
  }

  /// Déconnexion locale + serveur GoTrue (session téléphone OTP effacée sur l’appareil).
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
