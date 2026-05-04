/// Pays avec indicatif téléphonique (sans libphonenumber).
class PhoneCountry {
  const PhoneCountry({
    required this.iso2,
    required this.name,
    required this.dialCode,
    required this.emoji,
    this.minNsnDigits = 8,
    this.maxNsnDigits = 12,
  });

  final String iso2;
  final String name;
  /// Chiffres uniquement, sans « + » (ex. `234`).
  final String dialCode;
  final String emoji;
  final int minNsnDigits;
  final int maxNsnDigits;

  String get displayDial => '+$dialCode';

  @override
  bool operator ==(Object other) =>
      other is PhoneCountry && other.iso2 == iso2;

  @override
  int get hashCode => iso2.hashCode;
}

/// Liste affichée dans le sélecteur (ordre UX).
const List<PhoneCountry> kPhoneCountriesDisplay = [
  PhoneCountry(iso2: 'NG', name: 'Nigeria', dialCode: '234', emoji: '🇳🇬', minNsnDigits: 10, maxNsnDigits: 10),
  PhoneCountry(iso2: 'CI', name: "Côte d'Ivoire", dialCode: '225', emoji: '🇨🇮'),
  PhoneCountry(iso2: 'SN', name: 'Sénégal', dialCode: '221', emoji: '🇸🇳'),
  PhoneCountry(iso2: 'CM', name: 'Cameroun', dialCode: '237', emoji: '🇨🇲'),
  PhoneCountry(iso2: 'GH', name: 'Ghana', dialCode: '233', emoji: '🇬🇭'),
  PhoneCountry(iso2: 'BJ', name: 'Bénin', dialCode: '229', emoji: '🇧🇯'),
  PhoneCountry(iso2: 'TG', name: 'Togo', dialCode: '228', emoji: '🇹🇬'),
  PhoneCountry(iso2: 'ML', name: 'Mali', dialCode: '223', emoji: '🇲🇱'),
  PhoneCountry(iso2: 'BF', name: 'Burkina Faso', dialCode: '226', emoji: '🇧🇫'),
  PhoneCountry(iso2: 'NE', name: 'Niger', dialCode: '227', emoji: '🇳🇪'),
  PhoneCountry(iso2: 'FR', name: 'France', dialCode: '33', emoji: '🇫🇷'),
  PhoneCountry(iso2: 'BE', name: 'Belgique', dialCode: '32', emoji: '🇧🇪'),
  PhoneCountry(iso2: 'DE', name: 'Allemagne', dialCode: '49', emoji: '🇩🇪'),
  PhoneCountry(iso2: 'GB', name: 'Royaume-Uni', dialCode: '44', emoji: '🇬🇧'),
  PhoneCountry(iso2: 'US', name: 'États-Unis', dialCode: '1', emoji: '🇺🇸', minNsnDigits: 10, maxNsnDigits: 10),
  PhoneCountry(iso2: 'CA', name: 'Canada', dialCode: '1', emoji: '🇨🇦', minNsnDigits: 10, maxNsnDigits: 10),
];

/// Pour la résolution d’indicatif : codes les plus longs en premier (ex. +1242 avant +1).
final List<PhoneCountry> kPhoneCountriesByDialLengthDesc = () {
  final unique = List<PhoneCountry>.from(kPhoneCountriesDisplay);
  unique.sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
  return unique;
}();

/// Résout le pays à partir des chiffres saisis dans le champ indicatif.
///
/// 1) Saisie complète ou sur-longue : [digitsOnly] commence par un indicatif connu.
/// 2) Saisie progressive : un seul pays a un indicatif qui commence par [digitsOnly]
///    (ex. « 225 » → Côte d’Ivoire ; « 22 » reste ambigu → null).
PhoneCountry? matchPhoneCountryByDialPrefix(String digitsOnly) {
  if (digitsOnly.isEmpty) return null;

  for (final c in kPhoneCountriesByDialLengthDesc) {
    if (digitsOnly.startsWith(c.dialCode)) return c;
  }

  final narrowing = kPhoneCountriesDisplay.where((c) => c.dialCode.startsWith(digitsOnly)).toList();
  if (narrowing.length == 1) return narrowing.first;
  return null;
}

PhoneCountry get defaultPhoneCountry =>
    kPhoneCountriesDisplay.firstWhere((c) => c.iso2 == 'NG');
