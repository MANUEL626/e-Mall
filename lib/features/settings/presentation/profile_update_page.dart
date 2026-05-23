import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/location/location_picker.dart';
import '../../../core/phone/phone_country.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/settings/settings_service.dart';
import '../../../services/users/users_service.dart';

class ProfileUpdatePage extends StatefulWidget {
  const ProfileUpdatePage({super.key});

  @override
  State<ProfileUpdatePage> createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  final _usernameController = TextEditingController();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _mailController = TextEditingController();
  final _countryController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _latitudeController = TextEditingController();

  final Set<String> _selectedInterestCodes = <String>{};
  Uint8List? _profilePhotoBytes;
  String? _profilePhotoUrl;
  String _localeCode = 'fr';
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final profile = CustomerProfileStore.instance.profile;
    final params = CustomerParamsStore.instance.params;
    _usernameController.text = profile?.username ?? '';
    _prenomController.text = profile?.prenom ?? '';
    _nomController.text = profile?.nom ?? '';
    _mailController.text = profile?.mail ?? '';
    _profilePhotoUrl = profile?.profilePicture;
    _countryController.text = params?.country ?? defaultPhoneCountry.iso2;
    _longitudeController.text = params?.defaultLongitude?.toString() ?? '';
    _latitudeController.text = params?.defaultLatitude?.toString() ?? '';
    _selectedInterestCodes.addAll(params?.interests ?? const <String>[]);
    _localeCode = _supportedLocaleCode(
      params?.locale ?? AppLocaleController.instance.locale.languageCode,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _mailController.dispose();
    _countryController.dispose();
    _longitudeController.dispose();
    _latitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (x == null || !mounted) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _profilePhotoBytes = bytes;
        _errorText = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = AppLocalizations.of(context)!.profileUpdatePhotoError);
    }
  }

  double? _parseOptionalCoordinate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  Future<void> _save() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() => _errorText = AppLocalizations.of(context)!.profileUpdateExpiredSession);
      return;
    }

    final mail = _mailController.text.trim();
    if (mail.isNotEmpty && !_isValidEmail(mail)) {
      setState(() => _errorText = AppLocalizations.of(context)!.errorInvalidEmail);
      return;
    }

    final longitude = _parseOptionalCoordinate(_longitudeController.text);
    final latitude = _parseOptionalCoordinate(_latitudeController.text);
    if ((_longitudeController.text.trim().isNotEmpty && longitude == null) ||
        (_latitudeController.text.trim().isNotEmpty && latitude == null)) {
      setState(() => _errorText = AppLocalizations.of(context)!.errorInvalidCoordinates);
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      final profileBody = <String, dynamic>{};
      final username = _usernameController.text.trim();
      final prenom = _prenomController.text.trim();
      final nom = _nomController.text.trim();
      if (username.isNotEmpty) profileBody['username'] = username;
      if (prenom.isNotEmpty) profileBody['prenom'] = prenom;
      if (nom.isNotEmpty) profileBody['nom'] = nom;
      if (mail.isNotEmpty) profileBody['mail'] = mail;

      final photo = _profilePhotoBytes;
      if (photo != null && photo.isNotEmpty) {
        final url = await ProfilePhotoStorage.uploadProfilePhoto(photo);
        profileBody['profilepicture'] = url;
      }

      if (profileBody.isNotEmpty) {
        final updated = await CustomerAuthService.instance.updateCustomerProfile(
          session,
          profile: profileBody,
        );
        await CustomerProfileStore.instance.setProfile(updated);
      }

      final params = await CustomerSaleService.instance.patchMyParams(
        accessToken: session.accessToken,
        locale: _localeCode,
        defaultLongitude: longitude,
        defaultLatitude: latitude,
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim().toUpperCase(),
        interests: _selectedInterestCodes.toList(growable: false),
      );
      await CustomerParamsStore.instance.setParams(params);
      await AppLocaleController.instance.setLocale(Locale(_localeCode));

      if (!mounted) return;
      Navigator.of(context).pop();
    } on CustomerBootstrapException catch (e) {
      if (!mounted) return;
      _showError(_profileUpdateErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context)!.profileUpdateGenericError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _profileUpdateErrorMessage(CustomerBootstrapException error) {
    final raw = error.message.trim();
    final lower = raw.toLowerCase();
    if (error.statusCode == 400 &&
        (lower.contains('email') ||
            lower.contains('mail') ||
            lower.contains('username') ||
            lower.contains('nom d') ||
            lower.contains('utilisateur') ||
            lower.contains('deja') ||
            lower.contains('déjà'))) {
      return AppLocalizations.of(context)!.profileUpdateConflictError;
    }
    if (raw.isNotEmpty) return raw;
    return AppLocalizations.of(context)!.profileUpdateGenericError;
  }

  void _showError(String message) {
    setState(() => _errorText = message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openCountryPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF8F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final currentIso = _countryController.text.trim().toUpperCase();
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.72,
            child: ListView.separated(
              itemCount: kPhoneCountriesDisplay.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                final country = kPhoneCountriesDisplay[i];
                final selected = country.iso2 == currentIso;
                return ListTile(
                  leading: Text(country.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(country.name),
                  subtitle: Text('${country.iso2} - ${country.displayDial}'),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: Color(0xFFC45A12))
                      : null,
                  onTap: () {
                    setState(() => _countryController.text = country.iso2);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  PhoneCountry _selectedCountry() {
    final iso = _countryController.text.trim().toUpperCase();
    return kPhoneCountriesDisplay.firstWhere(
      (country) => country.iso2 == iso,
      orElse: () => defaultPhoneCountry,
    );
  }

  void _toggleInterest(String code) {
    setState(() {
      if (!_selectedInterestCodes.add(code)) {
        _selectedInterestCodes.remove(code);
      }
    });
  }

  String _supportedLocaleCode(String? code) {
    switch (code?.trim().toLowerCase()) {
      case 'en':
      case 'de':
      case 'zh':
        return code!.trim().toLowerCase();
      case 'fr':
      default:
        return 'fr';
    }
  }

  ImageProvider? _profileImageProvider() {
    final bytes = _profilePhotoBytes;
    if (bytes != null) return MemoryImage(bytes);
    final url = _profilePhotoUrl?.trim();
    if (url == null || url.isEmpty) return null;
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final country = _selectedCountry();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F5),
      appBar: AppBar(
        title: Text(l10n.profileUpdateTitle),
        backgroundColor: const Color(0xFFFFF9F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.profileUpdateSaveTooltip,
            onPressed: _saving ? null : () => unawaited(_save()),
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFF1DACB),
                  backgroundImage: _profileImageProvider(),
                  child: _profilePhotoBytes == null &&
                          (_profilePhotoUrl?.trim().isNotEmpty != true)
                      ? const Icon(Icons.person, size: 42, color: Color(0xFF6A4A35))
                      : null,
                ),
                IconButton.filled(
                  onPressed: _saving ? null : () => unawaited(_pickProfilePhoto()),
                  icon: const Icon(Icons.photo_camera_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Field(controller: _usernameController, label: l10n.labelUsername),
          _Field(controller: _prenomController, label: l10n.labelFirstName),
          _Field(controller: _nomController, label: l10n.labelLastName),
          _Field(
            controller: _mailController,
            label: l10n.labelEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          _SectionTitle(label: l10n.settingsPreferencesSection),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _localeCode,
            decoration: _inputDecoration('Langue'),
            items: const [
              DropdownMenuItem(value: 'fr', child: Text('Français')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'de', child: Text('Deutsch')),
              DropdownMenuItem(value: 'zh', child: Text('中文')),
            ],
            onChanged: _saving ? null : (value) => setState(() => _localeCode = value ?? 'fr'),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _saving ? null : () => unawaited(_openCountryPicker()),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Text(country.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${country.name} (${country.iso2})'),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          LocationPicker(
            longitudeController: _longitudeController,
            latitudeController: _latitudeController,
            title: l10n.profileUpdateLocationTitle,
            subtitle: l10n.profileUpdateLocationSubtitle,
            compact: true,
            enabled: !_saving,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.labelInterests,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _InterestOption.all.map((option) {
              final selected = _selectedInterestCodes.contains(option.code);
              return FilterChip(
                selected: selected,
                label: Text(option.label(l10n)),
                selectedColor: const Color(0xFFF2C6A8),
                checkmarkColor: const Color(0xFFC45A12),
                backgroundColor: const Color(0xFFF3E4D9),
                side: BorderSide(
                  color: selected ? const Color(0xFFC45A12) : Colors.transparent,
                ),
                onSelected: _saving ? null : (_) => _toggleInterest(option.code),
              );
            }).toList(),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 14),
            Text(
              _errorText!,
              style: const TextStyle(color: Color(0xFF9A2F20)),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : () => unawaited(_save()),
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.saveButton),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
      ),
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

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _InterestOption {
  const _InterestOption(this.code);

  final String code;

  static const all = <_InterestOption>[
    _InterestOption('electronics'),
    _InterestOption('appliances'),
    _InterestOption('clothing'),
    _InterestOption('food'),
    _InterestOption('beauty'),
    _InterestOption('sports'),
    _InterestOption('home'),
    _InterestOption('other'),
  ];

  String label(AppLocalizations l10n) {
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
      default:
        return l10n.interestOther;
    }
  }
}
