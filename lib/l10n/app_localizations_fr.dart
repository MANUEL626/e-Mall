// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get languageTitle => 'Langue';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageChinese => '中文';

  @override
  String get languageSystemDefault =>
      'Par défaut : langue du téléphone, français si non supportée';

  @override
  String get onboardingHandpicked => 'Sélectionné';

  @override
  String get onboardingBrandTitle => 'e-Mall';

  @override
  String get onboardingWelcomeSubtitle =>
      'Découvrez une marketplace où le patrimoine rencontre le commerce digital haut de gamme.';

  @override
  String get continueButton => 'Continuer';

  @override
  String get onboardingPhoneTitle => 'Bon retour';

  @override
  String get onboardingPhoneSubtitle =>
      'Entrez votre numéro de téléphone pour accéder à votre collection d’artisans.';

  @override
  String get labelCountry => 'Pays';

  @override
  String get labelPhoneNumber => 'Numéro de téléphone';

  @override
  String get phoneNationalHint => 'Numéro';

  @override
  String get phoneNationalHintNg => '80 000 0000';

  @override
  String get chooseCountryTitle => 'Choisir un pays';

  @override
  String get verificationCodeTitle => 'Code de vérification';

  @override
  String otpSentToPhone(String phone) {
    return 'Code envoyé au $phone.';
  }

  @override
  String get otpSentGeneric =>
      'Nous avons envoyé un code à 6 chiffres sur votre téléphone.';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String resendCodeSeconds(int seconds) {
    return 'Renvoyer le code (${seconds}s)';
  }

  @override
  String get verifyCodeButton => 'Vérifier le code';

  @override
  String get skipButton => 'Passer';

  @override
  String get profileWelcomeNew => 'Bienvenue !';

  @override
  String get profileWelcomeComplete => 'Complétez votre profil';

  @override
  String get profileAllFieldsOptional => 'Tous les champs sont facultatifs.';

  @override
  String get profilePrefsTitle => 'Préférences';

  @override
  String get profilePrefsSubtitle =>
      'Utilisées pour personnaliser les produits, la langue et la livraison.';

  @override
  String get labelDefaultLongitude => 'Longitude par défaut';

  @override
  String get labelDefaultLatitude => 'Latitude par défaut';

  @override
  String get labelInterests => 'Intérêts';

  @override
  String get interestElectronics => 'Électronique';

  @override
  String get interestAppliances => 'Électroménager';

  @override
  String get interestClothing => 'Mode';

  @override
  String get interestFood => 'Alimentation';

  @override
  String get interestBeauty => 'Beauté';

  @override
  String get interestSports => 'Sport';

  @override
  String get interestHome => 'Maison';

  @override
  String get interestOther => 'Autre';

  @override
  String get removePhotoTooltip => 'Retirer la photo';

  @override
  String get chooseFromGallery => 'Choisir une image dans la galerie';

  @override
  String get labelUsername => 'Pseudo';

  @override
  String get labelFirstName => 'Prénom';

  @override
  String get labelLastName => 'Nom';

  @override
  String get labelEmail => 'E-mail';

  @override
  String get hintUsername => 'ex. neo_artisan';

  @override
  String get hintFirstName => 'Prénom';

  @override
  String get hintLastName => 'Nom';

  @override
  String get hintEmail => 'vous@exemple.com';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get errorSupabaseNotConfigured =>
      'Supabase non configuré. Lancez l’app avec --dart-define=SUPABASE_URL=... et SUPABASE_ANON_KEY=...';

  @override
  String errorPhoneInvalid(int minNsn, int maxNsn, String countryName) {
    return 'Entrez un indicatif pays valide et un numéro national ($minNsn–$maxNsn chiffres pour $countryName).';
  }

  @override
  String get errorApiBaseUrlOtp =>
      'API_BASE_URL non configurée. Ajoutez --dart-define=API_BASE_URL=https://votre-api';

  @override
  String get errorApiBaseUrlProfile => 'API_BASE_URL non configurée.';

  @override
  String get errorOtpLength => 'Saisissez les 6 chiffres du SMS.';

  @override
  String get errorGalleryUnavailable =>
      'Galerie indisponible : faites un build complet (voir message dans la console ou arrêtez l’app, flutter clean, flutter pub get, désinstallez l’app puis flutter run).';

  @override
  String get errorSessionExpired => 'Session expirée. Reconnectez-vous.';

  @override
  String get errorInvalidEmail => 'Adresse e-mail invalide.';

  @override
  String get errorInvalidCoordinates =>
      'Indiquez une longitude et une latitude valides.';

  @override
  String get snackAddedToCart => 'Ajouté au panier';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get feedEmptyPosts => 'Aucun post pour le moment.';

  @override
  String get feedFollowingBadge => 'Abonné';

  @override
  String get feedViewMerchant => 'Voir la boutique';

  @override
  String get snackSubscriptionCancelled => 'Abonnement résilié';

  @override
  String get snackFollowingShop => 'Vous suivez cette boutique';

  @override
  String get subscribeButton => 'S’abonner';

  @override
  String get unsubscribeButton => 'Se désabonner';

  @override
  String get snackMinMaxPrice => 'min ≤ max requis.';

  @override
  String get applyButton => 'Appliquer';

  @override
  String get resetButton => 'Réinitialiser';

  @override
  String get navHome => 'Accueil';

  @override
  String get navNew => 'Nouveau';

  @override
  String get navMe => 'Moi';

  @override
  String get homeSearchTooltip => 'Recherche';

  @override
  String get homeFiltersTooltip => 'Filtres';

  @override
  String get homeSearchHint => 'Rechercher un produit…';

  @override
  String get homeHeroTitle => 'Summer\nHarvest\nCollective';

  @override
  String get homeHeroSubtitle =>
      'Directement des fermes de la vallée fertile jusqu’à votre cuisine.';

  @override
  String get homeCategoriesTitle => 'Catégories';

  @override
  String get homeSelectionTitle => 'Sélection';

  @override
  String get homeAllCategories => 'Toutes';

  @override
  String get homeEmptyCatalog =>
      'Aucun produit ne correspond à votre recherche ou vos filtres.';

  @override
  String get filterSheetTitle => 'Filtres';

  @override
  String get filterCategoryLabel => 'Catégorie';

  @override
  String get filterPriceLabel => 'Prix unitaire (min / max)';

  @override
  String filterPriceSummary(String min, String max) {
    return 'Prix $min — $max';
  }

  @override
  String get errorApiNotConfigured =>
      'API_BASE_URL non configurée (dart-define).';

  @override
  String get errorSessionMissing => 'Session absente. Reconnectez-vous.';

  @override
  String get merchantDefaultShopName => 'Boutique';

  @override
  String subscriberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abonnés',
      one: '$count abonné',
    );
    return '$_temp0';
  }

  @override
  String get ordersTitle => 'Mes commandes';

  @override
  String get ordersFilterAll => 'Toutes';

  @override
  String get ordersFilterInProgress => 'En cours';

  @override
  String get ordersFilterInDelivery => 'En livraison';

  @override
  String get ordersFilterCancelled => 'Annulées';

  @override
  String get ordersFilterCompleted => 'Terminées';

  @override
  String get ordersEmpty => 'Aucune commande dans cette catégorie.';

  @override
  String ordersArticlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '$count article',
    );
    return '$_temp0';
  }

  @override
  String get orderDetailTitle => 'Commande';

  @override
  String get orderShopLabel => 'Boutique';

  @override
  String get orderPlacedLabel => 'Passée le';

  @override
  String get orderArticlesTitle => 'Articles';

  @override
  String get orderFulfillmentPickup => 'Retrait';

  @override
  String get orderFulfillmentDelivery => 'Livraison';

  @override
  String get orderStatusPending => 'En attente';

  @override
  String get orderStatusInProgress => 'En cours';

  @override
  String get orderStatusInDelivery => 'En livraison';

  @override
  String get orderStatusCancelled => 'Annulée';

  @override
  String get orderStatusCompleted => 'Terminée';

  @override
  String get meOrderHistoryTitle => 'Historique des commandes';

  @override
  String get meOrderHistorySubtitle => 'Suivre et consulter vos achats';

  @override
  String get meProfileFallback => 'Profil';

  @override
  String get meCompleteProfile => 'Complétez votre profil';

  @override
  String get meOrdersStat => 'Commandes';

  @override
  String get meWishlistStat => 'Favoris';

  @override
  String get mePointsStat => 'Points';

  @override
  String get meAccountTitle => 'Mon compte';

  @override
  String get meAccountSubtitle => 'Portefeuille, paiements et facturation';

  @override
  String get meWishlistTitle => 'Mes favoris';

  @override
  String get meWishlistSubtitle => 'Vos produits favoris';

  @override
  String get meCartTitle => 'Mon panier';

  @override
  String get meCartSubtitle => 'Articles prêts pour la commande';

  @override
  String get orderConfirmReceiptTitle => 'Confirmer la réception';

  @override
  String get orderConfirmReceiptScanTooltip => 'Scanner le QR de réception';

  @override
  String get orderConfirmReceiptHint =>
      'Visez le code QR affiché par la boutique ou le livreur. Il contient l’identifiant de commande et le secret de validation.';

  @override
  String get orderConfirmReceiptNoteLabel => 'Note (facultatif)';

  @override
  String get orderConfirmReceiptSuccess => 'Réception confirmée.';

  @override
  String get orderDetailConfirmReceipt => 'Confirmer la réception (QR)';

  @override
  String get orderManualQrLabel => 'Coller le contenu du QR';

  @override
  String get orderManualQrSubmit => 'Valider';

  @override
  String get orderScannerWebHint =>
      'Le scan par caméra peut être limité dans le navigateur — collez le contenu du QR ci-dessous si besoin.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get editProfileTooltip => 'Modifier le profil';

  @override
  String get settingsProfileSection => 'Profil';

  @override
  String get settingsPreferencesSection => 'Préférences';

  @override
  String get settingsAccountSection => 'Compte';

  @override
  String get settingsInterestsSection => 'Centres d’intérêt';

  @override
  String get settingsNameLabel => 'Nom';

  @override
  String get settingsPhoneLabel => 'Téléphone';

  @override
  String get settingsLocationLabel => 'Localisation';

  @override
  String get settingsRegionLabel => 'Région';

  @override
  String get settingsLanguageLabel => 'Langue';

  @override
  String get settingsUndefined => 'Non défini';

  @override
  String get profileUpdateTitle => 'Modifier le profil';

  @override
  String get profileUpdateSaveTooltip => 'Enregistrer';

  @override
  String get profileUpdateGenericError =>
      'Impossible de mettre le profil à jour. Réessayez.';

  @override
  String get profileUpdateConflictError =>
      'Email ou nom d’utilisateur déjà utilisé. Choisissez une autre valeur.';

  @override
  String get profileUpdatePhotoError => 'Impossible de choisir cette photo.';

  @override
  String get profileUpdateLocationTitle => 'Localisation';

  @override
  String get profileUpdateLocationSubtitle =>
      'Utilisez votre position actuelle ou touchez la carte.';

  @override
  String get profileUpdateExpiredSession =>
      'Session expirée. Reconnectez-vous.';

  @override
  String get signOutMenuTitle => 'Se déconnecter';

  @override
  String get signOutMenuSubtitle => 'Délier ce téléphone du compte e-Mall';

  @override
  String get signOutDialogTitle => 'Se déconnecter ?';

  @override
  String get signOutDialogBody =>
      'Vous devrez vous reconnecter avec votre numéro de téléphone.';

  @override
  String get signOutConfirm => 'Se déconnecter';

  @override
  String get signOutCancel => 'Annuler';
}
