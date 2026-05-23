// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageFrench => 'Französisch';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageChinese => 'Chinesisch';

  @override
  String get languageSystemDefault =>
      'Standard: Telefonsprache; Französisch, wenn nicht unterstützt';

  @override
  String get onboardingHandpicked => 'Ausgewählt';

  @override
  String get onboardingBrandTitle => 'e-Mall';

  @override
  String get onboardingWelcomeSubtitle =>
      'Entdecke einen kuratierten Marktplatz, auf dem Tradition auf hochwertiges digitales Einkaufen trifft.';

  @override
  String get continueButton => 'Weiter';

  @override
  String get onboardingPhoneTitle => 'Willkommen zurück';

  @override
  String get onboardingPhoneSubtitle =>
      'Gib deine Telefonnummer ein, um auf deine Auswahl zuzugreifen.';

  @override
  String get labelCountry => 'Land';

  @override
  String get labelPhoneNumber => 'Telefonnummer';

  @override
  String get phoneNationalHint => 'Nummer';

  @override
  String get phoneNationalHintNg => '80 000 0000';

  @override
  String get chooseCountryTitle => 'Land auswählen';

  @override
  String get verificationCodeTitle => 'Bestätigungscode';

  @override
  String otpSentToPhone(String phone) {
    return 'Code an $phone gesendet.';
  }

  @override
  String get otpSentGeneric =>
      'Wir haben einen 6-stelligen Code an dein Telefon gesendet.';

  @override
  String get resendCode => 'Code erneut senden';

  @override
  String resendCodeSeconds(int seconds) {
    return 'Code erneut senden (${seconds}s)';
  }

  @override
  String get verifyCodeButton => 'Code bestätigen';

  @override
  String get skipButton => 'Überspringen';

  @override
  String get profileWelcomeNew => 'Willkommen!';

  @override
  String get profileWelcomeComplete => 'Profil vervollständigen';

  @override
  String get profileAllFieldsOptional => 'Alle Felder sind optional.';

  @override
  String get profilePrefsTitle => 'Einstellungen';

  @override
  String get profilePrefsSubtitle =>
      'Wird verwendet, um Produkte, Sprache und Lieferstandardwerte zu personalisieren.';

  @override
  String get labelDefaultLongitude => 'Standard-Längengrad';

  @override
  String get labelDefaultLatitude => 'Standard-Breitengrad';

  @override
  String get labelInterests => 'Interessen';

  @override
  String get interestElectronics => 'Elektronik';

  @override
  String get interestAppliances => 'Haushaltsgeräte';

  @override
  String get interestClothing => 'Mode';

  @override
  String get interestFood => 'Lebensmittel';

  @override
  String get interestBeauty => 'Beauty';

  @override
  String get interestSports => 'Sport';

  @override
  String get interestHome => 'Haus';

  @override
  String get interestOther => 'Andere';

  @override
  String get removePhotoTooltip => 'Foto entfernen';

  @override
  String get chooseFromGallery => 'Bild aus Galerie wählen';

  @override
  String get labelUsername => 'Benutzername';

  @override
  String get labelFirstName => 'Vorname';

  @override
  String get labelLastName => 'Nachname';

  @override
  String get labelEmail => 'E-Mail';

  @override
  String get hintUsername => 'z. B. neo_artisan';

  @override
  String get hintFirstName => 'Vorname';

  @override
  String get hintLastName => 'Nachname';

  @override
  String get hintEmail => 'du@beispiel.com';

  @override
  String get saveButton => 'Speichern';

  @override
  String get errorSupabaseNotConfigured =>
      'Supabase ist nicht konfiguriert. Starte die App mit --dart-define=SUPABASE_URL=... und SUPABASE_ANON_KEY=...';

  @override
  String errorPhoneInvalid(int minNsn, int maxNsn, String countryName) {
    return 'Gib eine gültige Landesvorwahl und nationale Nummer ein ($minNsn-$maxNsn Ziffern für $countryName).';
  }

  @override
  String get errorApiBaseUrlOtp =>
      'API_BASE_URL ist nicht konfiguriert. Füge --dart-define=API_BASE_URL=https://deine-api hinzu';

  @override
  String get errorApiBaseUrlProfile => 'API_BASE_URL ist nicht konfiguriert.';

  @override
  String get errorOtpLength => 'Gib die 6 Ziffern aus der SMS ein.';

  @override
  String get errorGalleryUnavailable =>
      'Galerie nicht verfügbar: Erstelle einen vollständigen Build (siehe Konsole oder App stoppen, flutter clean, flutter pub get, App deinstallieren und flutter run).';

  @override
  String get errorSessionExpired =>
      'Sitzung abgelaufen. Bitte erneut anmelden.';

  @override
  String get errorInvalidEmail => 'Ungültige E-Mail-Adresse.';

  @override
  String get errorInvalidCoordinates =>
      'Gib gültige Werte für Längen- und Breitengrad ein.';

  @override
  String get snackAddedToCart => 'Zum Warenkorb hinzugefügt';

  @override
  String get retryButton => 'Erneut versuchen';

  @override
  String get feedEmptyPosts => 'Noch keine Beiträge.';

  @override
  String get feedFollowingBadge => 'Folge ich';

  @override
  String get feedViewMerchant => 'Shop ansehen';

  @override
  String get snackSubscriptionCancelled => 'Abo beendet';

  @override
  String get snackFollowingShop => 'Du folgst diesem Shop';

  @override
  String get subscribeButton => 'Folgen';

  @override
  String get unsubscribeButton => 'Nicht mehr folgen';

  @override
  String get snackMinMaxPrice =>
      'Minimum muss kleiner oder gleich Maximum sein.';

  @override
  String get applyButton => 'Anwenden';

  @override
  String get resetButton => 'Zurücksetzen';

  @override
  String get navHome => 'Start';

  @override
  String get navNew => 'Neu';

  @override
  String get navMe => 'Ich';

  @override
  String get homeSearchTooltip => 'Suche';

  @override
  String get homeFiltersTooltip => 'Filter';

  @override
  String get homeSearchHint => 'Produkt suchen…';

  @override
  String get homeHeroTitle => 'Sommer\nErnte\nKollektion';

  @override
  String get homeHeroSubtitle =>
      'Direkt von fruchtbaren Farmen in deine Küche.';

  @override
  String get homeCategoriesTitle => 'Kategorien';

  @override
  String get homeSelectionTitle => 'Auswahl';

  @override
  String get homeAllCategories => 'Alle';

  @override
  String get homeEmptyCatalog =>
      'Keine Produkte entsprechen deiner Suche oder den Filtern.';

  @override
  String get filterSheetTitle => 'Filter';

  @override
  String get filterCategoryLabel => 'Kategorie';

  @override
  String get filterPriceLabel => 'Stückpreis (min / max)';

  @override
  String filterPriceSummary(String min, String max) {
    return 'Preis $min - $max';
  }

  @override
  String get errorApiNotConfigured =>
      'API_BASE_URL ist nicht konfiguriert (dart-define).';

  @override
  String get errorSessionMissing => 'Keine Sitzung. Bitte erneut anmelden.';

  @override
  String get merchantDefaultShopName => 'Shop';

  @override
  String subscriberCount(int count) {
    return '$count Abonnenten';
  }

  @override
  String get ordersTitle => 'Meine Bestellungen';

  @override
  String get ordersFilterAll => 'Alle';

  @override
  String get ordersFilterInProgress => 'In Bearbeitung';

  @override
  String get ordersFilterInDelivery => 'In Lieferung';

  @override
  String get ordersFilterCancelled => 'Storniert';

  @override
  String get ordersFilterCompleted => 'Abgeschlossen';

  @override
  String get ordersEmpty => 'Keine Bestellungen in dieser Kategorie.';

  @override
  String ordersArticlesCount(int count) {
    return '$count Artikel';
  }

  @override
  String get orderDetailTitle => 'Bestellung';

  @override
  String get orderShopLabel => 'Shop';

  @override
  String get orderPlacedLabel => 'Aufgegeben';

  @override
  String get orderArticlesTitle => 'Artikel';

  @override
  String get orderFulfillmentPickup => 'Abholung';

  @override
  String get orderFulfillmentDelivery => 'Lieferung';

  @override
  String get orderStatusPending => 'Ausstehend';

  @override
  String get orderStatusInProgress => 'In Bearbeitung';

  @override
  String get orderStatusInDelivery => 'In Lieferung';

  @override
  String get orderStatusCancelled => 'Storniert';

  @override
  String get orderStatusCompleted => 'Abgeschlossen';

  @override
  String get meOrderHistoryTitle => 'Bestellverlauf';

  @override
  String get meOrderHistorySubtitle => 'Einkäufe verfolgen und ansehen';

  @override
  String get meProfileFallback => 'Profil';

  @override
  String get meCompleteProfile => 'Profil vervollständigen';

  @override
  String get meOrdersStat => 'Bestellungen';

  @override
  String get meWishlistStat => 'Favoriten';

  @override
  String get mePointsStat => 'Punkte';

  @override
  String get meAccountTitle => 'Mein Konto';

  @override
  String get meAccountSubtitle => 'Wallet, Zahlungen und Abrechnung';

  @override
  String get meWishlistTitle => 'Meine Favoriten';

  @override
  String get meWishlistSubtitle => 'Deine Lieblingsprodukte';

  @override
  String get meCartTitle => 'Mein Warenkorb';

  @override
  String get meCartSubtitle => 'Artikel bereit zum Bezahlen';

  @override
  String get orderConfirmReceiptTitle => 'Empfang bestätigen';

  @override
  String get orderConfirmReceiptScanTooltip => 'QR-Code scannen';

  @override
  String get orderConfirmReceiptHint =>
      'Richte die Kamera auf den QR-Code des Shops oder Kuriers. Er enthält Bestell-ID und Prüfcode.';

  @override
  String get orderConfirmReceiptNoteLabel => 'Optionale Notiz';

  @override
  String get orderConfirmReceiptSuccess => 'Empfang bestätigt.';

  @override
  String get orderDetailConfirmReceipt => 'Empfang bestätigen (QR)';

  @override
  String get orderManualQrLabel => 'QR-Inhalt einfügen';

  @override
  String get orderManualQrSubmit => 'Senden';

  @override
  String get orderScannerWebHint =>
      'Kamerascan kann im Browser eingeschränkt sein; füge bei Bedarf den QR-Inhalt unten ein.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get editProfileTooltip => 'Profil bearbeiten';

  @override
  String get settingsProfileSection => 'Profil';

  @override
  String get settingsPreferencesSection => 'Einstellungen';

  @override
  String get settingsAccountSection => 'Konto';

  @override
  String get settingsInterestsSection => 'Interessen';

  @override
  String get settingsNameLabel => 'Name';

  @override
  String get settingsPhoneLabel => 'Telefon';

  @override
  String get settingsLocationLabel => 'Standort';

  @override
  String get settingsRegionLabel => 'Region';

  @override
  String get settingsLanguageLabel => 'Sprache';

  @override
  String get settingsUndefined => 'Nicht festgelegt';

  @override
  String get profileUpdateTitle => 'Profil bearbeiten';

  @override
  String get profileUpdateSaveTooltip => 'Speichern';

  @override
  String get profileUpdateGenericError =>
      'Profil konnte nicht aktualisiert werden. Versuche es erneut.';

  @override
  String get profileUpdateConflictError =>
      'E-Mail oder Benutzername wird bereits verwendet. Wähle einen anderen Wert.';

  @override
  String get profileUpdatePhotoError =>
      'Dieses Foto kann nicht ausgewählt werden.';

  @override
  String get profileUpdateLocationTitle => 'Standort';

  @override
  String get profileUpdateLocationSubtitle =>
      'Nutze deine aktuelle Position oder tippe auf die Karte.';

  @override
  String get profileUpdateExpiredSession =>
      'Sitzung abgelaufen. Bitte erneut anmelden.';

  @override
  String get signOutMenuTitle => 'Abmelden';

  @override
  String get signOutMenuSubtitle => 'Dieses Telefon von e-Mall trennen';

  @override
  String get signOutDialogTitle => 'Abmelden?';

  @override
  String get signOutDialogBody =>
      'Du musst dich erneut mit deiner Telefonnummer anmelden.';

  @override
  String get signOutConfirm => 'Abmelden';

  @override
  String get signOutCancel => 'Abbrechen';
}
