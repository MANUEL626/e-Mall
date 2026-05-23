import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/auth/auth_service.dart';
import '../../../services/settings/settings_service.dart';
import '../../../services/users/users_service.dart';
import '../../../core/branding/app_branding.dart';
import '../../../core/config/app_config.dart';
import '../../../core/location/location_picker.dart';
import '../../../core/locale/app_locale_controller.dart';
import '../../../core/phone/phone_country.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final _phoneController = TextEditingController();
  final _dialDigitsController =
      TextEditingController(text: defaultPhoneCountry.dialCode);
  final _otpController = TextEditingController();
  final _usernameController = TextEditingController();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _mailController = TextEditingController();
  final _countryController = TextEditingController(text: defaultPhoneCountry.iso2);
  final _longitudeController = TextEditingController();
  final _latitudeController = TextEditingController();

  PhoneCountry _selectedPhoneCountry = defaultPhoneCountry;
  final Set<String> _selectedInterestCodes = <String>{};

  int _step = 0;
  String? _phoneE164;
  BootstrapCustomerResult? _bootstrapResult;
  Uint8List? _profilePhotoBytes;

  bool _phoneLoading = false;
  bool _otpLoading = false;
  bool _profileLoading = false;
  String? _stepError;

  int _resendSecondsLeft = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _dialDigitsController.addListener(_syncCountryFromDialDigits);
  }

  void _syncCountryFromDialDigits() {
    if (!mounted) return;
    final digits = _dialDigitsController.text.trim();
    if (digits.isEmpty) return;
    final match = matchPhoneCountryByDialPrefix(digits);
    if (match == null || match.iso2 == _selectedPhoneCountry.iso2) return;

    final sameDialCount =
        kPhoneCountriesDisplay.where((c) => c.dialCode == match.dialCode).length;
    if (sameDialCount > 1 && digits == match.dialCode) {
      return;
    }
    setState(() {
      _selectedPhoneCountry = match;
      _countryController.text = match.iso2;
    });
  }

  void _selectPhoneCountry(PhoneCountry country) {
    setState(() {
      _selectedPhoneCountry = country;
      _countryController.text = country.iso2;
      _dialDigitsController.text = country.dialCode;
      _dialDigitsController.selection = TextSelection.collapsed(offset: _dialDigitsController.text.length);
    });
  }

  /// Numéro national + indicatif → E.164 (8–15 chiffres au total hors « + »).
  String? _composePhoneE164() {
    final cc = _dialDigitsController.text.replaceAll(RegExp(r'\D'), '');
    var nsn = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (cc.isEmpty || nsn.isEmpty) return null;
    if (nsn.startsWith('0')) nsn = nsn.substring(1);
    if (nsn.isEmpty) return null;
    final fullDigits = cc + nsn;
    if (fullDigits.length < 8 || fullDigits.length > 15) return null;

    final matchedByDial = matchPhoneCountryByDialPrefix(cc);
    final forLength = matchedByDial ?? _selectedPhoneCountry;
    if (nsn.length < forLength.minNsnDigits || nsn.length > forLength.maxNsnDigits) {
      return null;
    }
    return '+$fullDigits';
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _dialDigitsController.removeListener(_syncCountryFromDialDigits);
    _dialDigitsController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _usernameController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _mailController.dispose();
    _countryController.dispose();
    _longitudeController.dispose();
    _latitudeController.dispose();
    super.dispose();
  }

  void _startResendCooldown({int seconds = 45}) {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSecondsLeft <= 1) {
        t.cancel();
        setState(() => _resendSecondsLeft = 0);
      } else {
        setState(() => _resendSecondsLeft--);
      }
    });
  }

  Future<void> _submitPhone() async {
    setState(() {
      _stepError = null;
    });
    if (!AppConfig.isSupabaseConfigured) {
      setState(() {
        _stepError = AppLocalizations.of(context)!.errorSupabaseNotConfigured;
      });
      return;
    }
    final e164 = _composePhoneE164();
    if (e164 == null) {
      setState(() {
        _stepError = AppLocalizations.of(context)!.errorPhoneInvalid(
          _selectedPhoneCountry.minNsnDigits,
          _selectedPhoneCountry.maxNsnDigits,
          _selectedPhoneCountry.name,
        );
      });
      return;
    }
    setState(() => _phoneLoading = true);
    try {
      await CustomerAuthService.instance.signInWithOtp(phoneE164: e164);
      if (!mounted) return;
      setState(() {
        _phoneE164 = e164;
        _step = 2;
        _phoneLoading = false;
      });
      _startResendCooldown();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _stepError = e.message;
        _phoneLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stepError = e.toString();
        _phoneLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    final phone = _phoneE164;
    if (phone == null || _resendSecondsLeft > 0) return;
    setState(() => _stepError = null);
    try {
      await CustomerAuthService.instance.resendOtp(phoneE164: phone);
      if (!mounted) return;
      _startResendCooldown();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _stepError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _stepError = e.toString());
    }
  }

  Future<void> _verifyOtpAndBootstrap() async {
    final phone = _phoneE164;
    if (phone == null) return;
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _stepError = AppLocalizations.of(context)!.errorOtpLength);
      return;
    }
    setState(() {
      _stepError = null;
      _otpLoading = true;
    });
    try {
      final session = await CustomerAuthService.instance.verifyOtp(
        phoneE164: phone,
        codeSixDigits: code,
      );
      if (!AppConfig.isApiConfigured) {
        if (!mounted) return;
        setState(() {
          _stepError = AppLocalizations.of(context)!.errorApiBaseUrlOtp;
          _otpLoading = false;
        });
        return;
      }
      final bootstrap = await CustomerAuthService.instance.bootstrapCustomer(
        session,
        profile: const <String, dynamic>{},
      );
      await CustomerProfileStore.instance.setProfile(bootstrap);
      if (bootstrap.isNewCustomer) {
        await _saveLocaleParam(accessToken: session.accessToken);
      } else {
        await _loadCustomerParams(accessToken: session.accessToken);
      }
      if (!mounted) return;
      setState(() {
        _bootstrapResult = bootstrap;
        _otpLoading = false;
      });
      _routeAfterBootstrap(bootstrap);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _stepError = e.message;
        _otpLoading = false;
      });
    } on CustomerBootstrapException catch (e) {
      if (!mounted) return;
      setState(() {
        _stepError = e.message;
        _otpLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stepError = e.toString();
        _otpLoading = false;
      });
    }
  }

  /// Après OTP + bootstrap : nouveaux comptes → complétion du profil ; sinon → accueil.
  void _routeAfterBootstrap(BootstrapCustomerResult bootstrap) {
    if (bootstrap.isNewCustomer) {
      final u = bootstrap.username;
      if (u != null && u.isNotEmpty) {
        _usernameController.text = u;
      }
      final p = bootstrap.prenom;
      if (p != null && p.isNotEmpty) {
        _prenomController.text = p;
      }
      final n = bootstrap.nom;
      if (n != null && n.isNotEmpty) {
        _nomController.text = n;
      }
      final m = bootstrap.mail;
      if (m != null && m.isNotEmpty) {
        _mailController.text = m;
      }
      setState(() => _step = 3);
      return;
    }
    _goHome();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
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
        _stepError = null;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _stepError = AppLocalizations.of(context)!.errorGalleryUnavailable;
      });
    }
  }

  void _clearProfilePhoto() {
    setState(() => _profilePhotoBytes = null);
  }

  Future<void> _finishProfile() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() => _stepError = AppLocalizations.of(context)!.errorSessionExpired);
      return;
    }
    final username = _usernameController.text.trim();
    final prenom = _prenomController.text.trim();
    final nom = _nomController.text.trim();
    final mail = _mailController.text.trim();
    if (mail.isNotEmpty && !_isValidEmail(mail)) {
      setState(() => _stepError = AppLocalizations.of(context)!.errorInvalidEmail);
      return;
    }
    final photo = _profilePhotoBytes;
    final hasPhoto = photo != null && photo.isNotEmpty;

    final body = <String, dynamic>{};
    if (username.isNotEmpty) {
      body['username'] = username;
    }
    if (prenom.isNotEmpty) {
      body['prenom'] = prenom;
    }
    if (nom.isNotEmpty) {
      body['nom'] = nom;
    }
    if (mail.isNotEmpty) {
      body['mail'] = mail;
    }

    if (!AppConfig.isApiConfigured) {
      setState(() => _stepError = AppLocalizations.of(context)!.errorApiBaseUrlProfile);
      return;
    }

    final longitude = _parseOptionalCoordinate(_longitudeController.text);
    final latitude = _parseOptionalCoordinate(_latitudeController.text);
    if ((_longitudeController.text.trim().isNotEmpty && longitude == null) ||
        (_latitudeController.text.trim().isNotEmpty && latitude == null)) {
      setState(() => _stepError = AppLocalizations.of(context)!.errorInvalidCoordinates);
      return;
    }

    setState(() {
      _stepError = null;
      _profileLoading = true;
    });
    try {
      if (hasPhoto) {
        final url = await ProfilePhotoStorage.uploadProfilePhoto(photo);
        body['profilepicture'] = url;
      }
      if (body.isNotEmpty) {
        final updated =
            await CustomerAuthService.instance.updateCustomerProfile(session, profile: body);
        await CustomerProfileStore.instance.setProfile(updated);
      }
      await _saveCustomerParams(
        accessToken: session.accessToken,
        longitude: longitude,
        latitude: latitude,
      );
      if (!mounted) return;
      setState(() => _profileLoading = false);
      _goHome();
    } on CustomerBootstrapException catch (e) {
      if (!mounted) return;
      setState(() {
        _stepError = e.message;
        _profileLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stepError = e.toString();
        _profileLoading = false;
      });
    }
  }

  double? _parseOptionalCoordinate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  Future<void> _saveCustomerParams({
    required String accessToken,
    double? longitude,
    double? latitude,
  }) async {
    final params = await CustomerSaleService.instance.patchMyParams(
      accessToken: accessToken,
      locale: AppLocaleController.instance.locale.languageCode,
      defaultLongitude: longitude,
      defaultLatitude: latitude,
      country: _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim().toUpperCase(),
      interests: _selectedInterestCodes.toList(growable: false),
    );
    await CustomerParamsStore.instance.setParams(params);
    await _applyLocaleFromParams(params.locale);
  }

  Future<void> _saveLocaleParam({required String accessToken}) async {
    try {
      final params = await CustomerSaleService.instance.patchMyParams(
        accessToken: accessToken,
        locale: AppLocaleController.instance.locale.languageCode,
      );
      await CustomerParamsStore.instance.setParams(params);
      await _applyLocaleFromParams(params.locale);
    } catch (_) {}
  }

  Future<void> _loadCustomerParams({required String accessToken}) async {
    try {
      final params = await CustomerSaleService.instance.getMyParams(
        accessToken: accessToken,
      );
      await CustomerParamsStore.instance.setParams(params);
      await _applyLocaleFromParams(params.locale);
    } catch (_) {}
  }

  Future<void> _applyLocaleFromParams(String? locale) async {
    if (!AppLocaleController.isSupported(locale)) return;
    await AppLocaleController.instance.setLocale(Locale(locale!.toLowerCase()));
  }

  Future<void> _skipProfileStep() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && AppConfig.isApiConfigured) {
      await _saveLocaleParam(accessToken: session.accessToken);
    }
    _goHome();
  }

  void _toggleInterest(String code) {
    setState(() {
      if (!_selectedInterestCodes.add(code)) {
        _selectedInterestCodes.remove(code);
      }
    });
  }

  Future<void> _goHome() async {
    await AuthGateService.completeAuthFlowToMain();
  }

  void _nextWelcome() {
    setState(() => _step = 1);
  }

  void _openLanguagePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFFF8F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.languageTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3F2413),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.flag_rounded, color: Color(0xFF3F2413)),
                  title: Text(l10n.languageFrench),
                  onTap: () {
                    unawaited(AppLocaleController.instance.setLocale(const Locale('fr')));
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Color(0xFF3F2413)),
                  title: Text(l10n.languageEnglish),
                  onTap: () {
                    unawaited(AppLocaleController.instance.setLocale(const Locale('en')));
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Color(0xFF3F2413)),
                  title: Text(l10n.languageGerman),
                  onTap: () {
                    unawaited(AppLocaleController.instance.setLocale(const Locale('de')));
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Color(0xFF3F2413)),
                  title: Text(l10n.languageChinese),
                  onTap: () {
                    unawaited(AppLocaleController.instance.setLocale(const Locale('zh')));
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = <Widget>[
      _WelcomeStep(
        l10n: l10n,
        onNext: _nextWelcome,
      ),
      _PhoneStep(
        l10n: l10n,
        dialDigitsController: _dialDigitsController,
        nationalController: _phoneController,
        selectedCountry: _selectedPhoneCountry,
        onCountrySelected: _selectPhoneCountry,
        onDialDigitsEdited: _syncCountryFromDialDigits,
        errorText: _stepError,
        isLoading: _phoneLoading,
        onSubmit: _submitPhone,
      ),
      _OtpStep(
        l10n: l10n,
        phoneMasked: _phoneE164,
        controller: _otpController,
        errorText: _stepError,
        isLoading: _otpLoading,
        resendSecondsLeft: _resendSecondsLeft,
        onVerify: _verifyOtpAndBootstrap,
        onResend: _resendOtp,
      ),
      _ProfileStep(
        l10n: l10n,
        usernameController: _usernameController,
        prenomController: _prenomController,
        nomController: _nomController,
        mailController: _mailController,
        countryController: _countryController,
        longitudeController: _longitudeController,
        latitudeController: _latitudeController,
        selectedInterestCodes: _selectedInterestCodes,
        onToggleInterest: _toggleInterest,
        profilePhotoBytes: _profilePhotoBytes,
        onPickPhoto: _pickProfilePhoto,
        onClearPhoto: _clearProfilePhoto,
        onSkip: _skipProfileStep,
        isNewCustomer: _bootstrapResult?.isNewCustomer ?? false,
        errorText: _stepError,
        isLoading: _profileLoading,
        onFinish: _finishProfile,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: pages[_step],
              ),
            ),
          ),
          if (_step == 0)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.language_rounded),
                    tooltip: l10n.languageTitle,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF8F3),
                      foregroundColor: const Color(0xFF3F2413),
                    ),
                    onPressed: () => _openLanguagePicker(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    required this.l10n,
    required this.onNext,
  });

  final AppLocalizations l10n;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      height: 300,
                      width: double.infinity,
                      color: const Color(0xFFEAD9B7),
                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: AppBranding.logoImage(height: 210),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              margin: const EdgeInsets.all(14),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC45A12),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.onboardingHandpicked,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.onboardingBrandTitle,
                    style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w700, color: Color(0xFF3F2413)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.languageSystemDefault,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6D513E)),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.onboardingWelcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, height: 1.4, color: Color(0xFF6D513E)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _PrimaryButton(label: l10n.continueButton, onTap: onNext),
        ],
      ),
    );
  }

}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    required this.l10n,
    required this.dialDigitsController,
    required this.nationalController,
    required this.selectedCountry,
    required this.onCountrySelected,
    required this.onDialDigitsEdited,
    required this.onSubmit,
    this.errorText,
    this.isLoading = false,
  });

  final AppLocalizations l10n;
  final TextEditingController dialDigitsController;
  final TextEditingController nationalController;
  final PhoneCountry selectedCountry;
  final void Function(PhoneCountry country) onCountrySelected;
  final VoidCallback onDialDigitsEdited;
  final VoidCallback onSubmit;
  final String? errorText;
  final bool isLoading;

  static const _fieldFill = Color(0xFFF3E4D9);

  Future<void> _openCountryPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF8F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.72;
        return SafeArea(
          child: SizedBox(
            height: maxH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    l10n.chooseCountryTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF3F2413)),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: kPhoneCountriesDisplay.length,
                    itemBuilder: (_, i) {
                      final c = kPhoneCountriesDisplay[i];
                      final selected = c.iso2 == selectedCountry.iso2;
                      return ListTile(
                        leading: Text(c.emoji, style: const TextStyle(fontSize: 28)),
                        title: Text(c.name),
                        subtitle: Text(c.displayDial, style: const TextStyle(color: Color(0xFF6D513E))),
                        trailing: selected ? const Icon(Icons.check_circle, color: Color(0xFFC45A12)) : null,
                        onTap: () {
                          onCountrySelected(c);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('phone'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: AppBranding.appIcon(size: 40),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.onboardingPhoneTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 36, color: Color(0xFF3F2413)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.onboardingPhoneSubtitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.labelCountry, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: _fieldFill,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      onTap: () => _openCountryPicker(context),
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Text(selectedCountry.emoji, style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedCountry.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF3F2413)),
                                  ),
                                  Text(
                                    selectedCountry.displayDial,
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF6D513E)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6D513E)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.labelPhoneNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _fieldFill,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 14, right: 2),
                              child: Text(
                                '+',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF3F2413)),
                              ),
                            ),
                            SizedBox(
                              width: 76,
                              child: TextField(
                                controller: dialDigitsController,
                                onChanged: (_) => onDialDigitsEdited(),
                                keyboardType: TextInputType.phone,
                                textAlign: TextAlign.left,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                decoration: const InputDecoration(
                                  hintText: '234',
                                  filled: false,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: nationalController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            hintText: selectedCountry.iso2 == 'NG' ? l10n.phoneNationalHintNg : l10n.phoneNationalHint,
                            filled: true,
                            fillColor: _fieldFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _PrimaryButton(
            label: l10n.continueButton,
            onTap: isLoading ? null : onSubmit,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    required this.l10n,
    required this.controller,
    required this.onVerify,
    required this.onResend,
    this.phoneMasked,
    this.errorText,
    this.isLoading = false,
    this.resendSecondsLeft = 0,
  });

  final AppLocalizations l10n;
  final TextEditingController controller;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final String? phoneMasked;
  final String? errorText;
  final bool isLoading;
  final int resendSecondsLeft;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('otp'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.verificationCodeTitle,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF3F2413)),
          ),
          const SizedBox(height: 10),
          Text(
            phoneMasked != null && phoneMasked!.isNotEmpty ? l10n.otpSentToPhone(phoneMasked!) : l10n.otpSentGeneric,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 26),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.w600),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              hintText: '• • • • • •',
              filled: true,
              fillColor: const Color(0xFFF3E4D9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: (resendSecondsLeft > 0 || isLoading) ? null : onResend,
            child: Text(
              resendSecondsLeft > 0 ? l10n.resendCodeSeconds(resendSecondsLeft) : l10n.resendCode,
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const Spacer(),
          _PrimaryButton(
            label: l10n.verifyCodeButton,
            onTap: isLoading ? null : onVerify,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.l10n,
    required this.usernameController,
    required this.prenomController,
    required this.nomController,
    required this.mailController,
    required this.countryController,
    required this.longitudeController,
    required this.latitudeController,
    required this.selectedInterestCodes,
    required this.onToggleInterest,
    required this.onPickPhoto,
    required this.onClearPhoto,
    required this.onSkip,
    required this.onFinish,
    this.profilePhotoBytes,
    this.isNewCustomer = false,
    this.errorText,
    this.isLoading = false,
  });

  final AppLocalizations l10n;
  final TextEditingController usernameController;
  final TextEditingController prenomController;
  final TextEditingController nomController;
  final TextEditingController mailController;
  final TextEditingController countryController;
  final TextEditingController longitudeController;
  final TextEditingController latitudeController;
  final Set<String> selectedInterestCodes;
  final void Function(String code) onToggleInterest;
  final Uint8List? profilePhotoBytes;
  final Future<void> Function() onPickPhoto;
  final VoidCallback onClearPhoto;
  final Future<void> Function() onSkip;
  final VoidCallback onFinish;
  final bool isNewCustomer;
  final String? errorText;
  final bool isLoading;

  static const _fill = Color(0xFFF3E4D9);

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
    );
  }

  PhoneCountry _countryFromController() {
    final iso = countryController.text.trim().toUpperCase();
    return kPhoneCountriesDisplay.firstWhere(
      (country) => country.iso2 == iso,
      orElse: () => defaultPhoneCountry,
    );
  }

  Future<void> _openSupportedCountryPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF8F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.72;
        final currentIso = countryController.text.trim().toUpperCase();
        return SafeArea(
          child: SizedBox(
            height: maxH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    l10n.chooseCountryTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3F2413),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: kPhoneCountriesDisplay.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      final country = kPhoneCountriesDisplay[i];
                      final selected = country.iso2 == currentIso;
                      return ListTile(
                        leading: Text(country.emoji, style: const TextStyle(fontSize: 28)),
                        title: Text(country.name),
                        subtitle: Text(
                          '${country.iso2} - ${country.displayDial}',
                          style: const TextStyle(color: Color(0xFF6D513E)),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check_circle, color: Color(0xFFC45A12))
                            : null,
                        onTap: () {
                          countryController.text = country.iso2;
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profilePhotoBytes != null && profilePhotoBytes!.isNotEmpty;

    return Padding(
      key: const ValueKey('profile'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : () => unawaited(onSkip()),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF6D513E)),
              child: Text(l10n.skipButton),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isNewCustomer ? l10n.profileWelcomeNew : l10n.profileWelcomeComplete,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF3F2413)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.profileAllFieldsOptional,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6D513E)),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Material(
                          color: const Color(0xFFF2DDCF),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: isLoading ? null : () => onPickPhoto(),
                            child: SizedBox(
                              width: 112,
                              height: 112,
                              child: hasPhoto
                                  ? Image.memory(
                                      profilePhotoBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.add_photo_alternate_outlined, size: 48, color: Color(0xFFC45A12)),
                            ),
                          ),
                        ),
                        if (hasPhoto)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Material(
                              color: const Color(0xFFF26D21),
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                onPressed: isLoading ? null : onClearPhoto,
                                tooltip: l10n.removePhotoTooltip,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: isLoading ? null : () => onPickPhoto(),
                    child: Text(l10n.chooseFromGallery),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.labelUsername, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration(l10n.hintUsername),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.labelFirstName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: prenomController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration(l10n.hintFirstName),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.labelLastName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nomController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration(l10n.hintLastName),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.labelEmail, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: mailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    decoration: _fieldDecoration(l10n.hintEmail),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.profilePrefsTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3F2413),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.profilePrefsSubtitle,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6D513E)),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.labelCountry, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: countryController,
                    builder: (context, _, __) {
                      final country = _countryFromController();
                      return Material(
                        color: _fill,
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          onTap: isLoading ? null : () => _openSupportedCountryPicker(context),
                          borderRadius: BorderRadius.circular(22),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                Text(country.emoji, style: const TextStyle(fontSize: 26)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        country.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Color(0xFF3F2413),
                                        ),
                                      ),
                                      Text(
                                        '${country.iso2} - ${country.displayDial}',
                                        style: const TextStyle(fontSize: 14, color: Color(0xFF6D513E)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6D513E)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  LocationPicker(
                    longitudeController: longitudeController,
                    latitudeController: latitudeController,
                    title: 'Position par defaut',
                    subtitle: 'Utilisez votre position actuelle ou touchez la carte.',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.labelInterests, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _InterestOption.all.map((option) {
                      final selected = selectedInterestCodes.contains(option.code);
                      return FilterChip(
                        selected: selected,
                        label: Text(option.label(l10n)),
                        selectedColor: const Color(0xFFF2C6A8),
                        checkmarkColor: const Color(0xFFC45A12),
                        backgroundColor: const Color(0xFFF3E4D9),
                        side: BorderSide(
                          color: selected ? const Color(0xFFC45A12) : Colors.transparent,
                        ),
                        onSelected: isLoading ? null : (_) => onToggleInterest(option.code),
                      );
                    }).toList(),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _PrimaryButton(
            label: l10n.saveButton,
            onTap: isLoading ? null : onFinish,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF26D21),
          foregroundColor: Colors.white,
          elevation: 2,
          disabledBackgroundColor: const Color(0xFFF26D21).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
