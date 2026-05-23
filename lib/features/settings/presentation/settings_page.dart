import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/phone/phone_country.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/settings/settings_service.dart';
import '../../../services/users/users_service.dart';
import 'profile_update_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _muted = Color(0xFF7D6A62);
  static const _surface = Color(0xFFFFF9F5);

  bool _refreshingParams = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshParams());
  }

  Future<void> _refreshParams() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || _refreshingParams) return;
    setState(() => _refreshingParams = true);
    try {
      final params = await CustomerSaleService.instance.getMyParams(
        accessToken: session.accessToken,
      );
      await CustomerParamsStore.instance.setParams(params);
      await _applyLocaleFromParams(params.locale);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _refreshingParams = false);
    }
  }

  Future<void> _applyLocaleFromParams(String? locale) async {
    if (!AppLocaleController.isSupported(locale)) return;
    await AppLocaleController.instance.setLocale(Locale(locale!.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.editProfileTooltip,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileUpdatePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          CustomerProfileStore.instance,
          CustomerParamsStore.instance,
        ]),
        builder: (context, _) {
          final profile = CustomerProfileStore.instance.profile;
          final params = CustomerParamsStore.instance.params;
          final sessionUser = Supabase.instance.client.auth.currentUser;
          final username = _valueOrDash(profile?.username);
          final fullName = _fullName(profile?.prenom, profile?.nom);
          final displayName = fullName == '-' ? profile?.displayName ?? '-' : fullName;
          final phone = _valueOrDash(sessionUser?.phone);
          final mail = _valueOrDash(profile?.mail ?? sessionUser?.email);
          final country = _countryLabel(params?.country, l10n.settingsUndefined);
          final locale = _localeLabel(params?.locale, l10n);
          final location = _locationLabel(
            params?.defaultLongitude,
            params?.defaultLatitude,
            l10n.settingsUndefined,
          );

          return RefreshIndicator(
            onRefresh: _refreshParams,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(
                    displayName: displayName,
                    username: username,
                    profilePicture: profile?.profilePicture,
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(label: l10n.settingsProfileSection),
                  const SizedBox(height: 14),
                  _SettingsGroupCard(
                    children: [
                      _InfoTile(
                        title: l10n.settingsNameLabel,
                        value: displayName,
                        icon: Icons.badge_outlined,
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        title: l10n.labelUsername,
                        value: username == '-' ? '-' : '@$username',
                        icon: Icons.alternate_email,
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        title: l10n.settingsPhoneLabel,
                        value: phone,
                        icon: Icons.phone_android,
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        title: l10n.labelEmail,
                        value: mail,
                        icon: Icons.mail_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(label: l10n.settingsPreferencesSection),
                  const SizedBox(height: 14),
                  _SettingsGroupCard(
                    children: [
                      _InfoTile(
                        title: l10n.settingsLocationLabel,
                        value: location,
                        icon: Icons.location_on_outlined,
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        title: l10n.settingsRegionLabel,
                        value: country,
                        icon: Icons.public_outlined,
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        title: l10n.settingsLanguageLabel,
                        value: locale,
                        icon: Icons.language_rounded,
                        trailing: _refreshingParams
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                    ],
                  ),
                  if ((params?.interests ?? const <String>[]).isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionTitle(label: l10n.settingsInterestsSection),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: params!.interests
                          .map(
                            (interest) => Chip(
                              label: Text(_interestLabel(interest, l10n)),
                              backgroundColor: const Color(0xFFF3E5DB),
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _SectionTitle(label: l10n.settingsAccountSection),
                  const SizedBox(height: 14),
                  _SettingsGroupCard(
                    children: [
                      _MenuTile(
                        title: l10n.signOutMenuTitle,
                        subtitle: l10n.signOutMenuSubtitle,
                        icon: Icons.logout_outlined,
                        isDestructive: true,
                        onTap: () => presentSignOutFlow(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'e-Mall - v1.0.0',
                      style: TextStyle(
                        color: _muted.withValues(alpha: 0.85),
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _valueOrDash(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '-';
    return trimmed;
  }

  static String _fullName(String? firstName, String? lastName) {
    final value = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return value.isEmpty ? '-' : value;
  }

  static String _locationLabel(
    double? longitude,
    double? latitude,
    String undefined,
  ) {
    if (longitude == null && latitude == null) return undefined;
    final lng = longitude?.toStringAsFixed(6) ?? '-';
    final lat = latitude?.toStringAsFixed(6) ?? '-';
    return 'Lat $lat, Lng $lng';
  }

  static String _countryLabel(String? code, String undefined) {
    final normalized = code?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return undefined;
    final match = kPhoneCountriesDisplay.where((country) => country.iso2 == normalized);
    if (match.isEmpty) return normalized;
    final country = match.first;
    return '${country.emoji} ${country.name} ($normalized)';
  }

  static String _localeLabel(String? code, AppLocalizations l10n) {
    switch (code?.trim().toLowerCase()) {
      case 'fr':
        return l10n.languageFrench;
      case 'en':
        return l10n.languageEnglish;
      case 'de':
        return l10n.languageGerman;
      case 'zh':
        return l10n.languageChinese;
      case null:
      case '':
        return l10n.settingsUndefined;
      default:
        return code!;
    }
  }

  static String _interestLabel(String code, AppLocalizations l10n) {
    switch (code) {
      case 'electronics':
        return l10n.interestElectronics;
      case 'appliances':
        return l10n.interestAppliances;
      case 'clothing':
        return l10n.interestClothing;
      case 'food':
        return l10n.interestFood;
      case 'beauty':
        return l10n.interestBeauty;
      case 'sports':
        return l10n.interestSports;
      case 'home':
        return l10n.interestHome;
      case 'other':
        return l10n.interestOther;
      default:
        return code;
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.username,
    required this.profilePicture,
  });

  final String displayName;
  final String username;
  final String? profilePicture;

  @override
  Widget build(BuildContext context) {
    final photo = profilePicture?.trim();
    final hasPhoto = photo != null && photo.isNotEmpty;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE8D5C8), width: 2),
          ),
          child: CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFFF1DACB),
            backgroundImage: hasPhoto ? NetworkImage(photo!) : null,
            child: hasPhoto
                ? null
                : const Icon(Icons.person, size: 42, color: Color(0xFF6A4A35)),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3F2413),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          username == '-' ? '@-' : '@$username',
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF7D6A62),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Color(0xFF8B7355),
      ),
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String value;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF1DACB),
            child: Icon(icon, color: const Color(0xFF4E2D1D), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF3F2413),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF7D6A62),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isDestructive = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final destructiveColor = const Color(0xFF9A2F20);
    final iconColor = isDestructive ? destructiveColor : const Color(0xFF4E2D1D);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF1DACB),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDestructive
                            ? destructiveColor
                            : const Color(0xFF3F2413),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF7D6A62),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isDestructive
                      ? destructiveColor.withValues(alpha: 0.6)
                      : const Color(0xFFC4B5A8),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
