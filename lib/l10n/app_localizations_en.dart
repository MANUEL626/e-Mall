// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageTitle => 'Language';

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
      'Default: your phone language, French if unsupported';

  @override
  String get onboardingHandpicked => 'Handpicked';

  @override
  String get onboardingBrandTitle => 'e-Mall';

  @override
  String get onboardingWelcomeSubtitle =>
      'Discover a curated marketplace where heritage meets high-end digital shopping.';

  @override
  String get continueButton => 'Continue';

  @override
  String get onboardingPhoneTitle => 'Welcome back';

  @override
  String get onboardingPhoneSubtitle =>
      'Enter your phone number to access your artisan collection.';

  @override
  String get labelCountry => 'Country';

  @override
  String get labelPhoneNumber => 'Phone number';

  @override
  String get phoneNationalHint => 'Number';

  @override
  String get phoneNationalHintNg => '80 000 0000';

  @override
  String get chooseCountryTitle => 'Choose a country';

  @override
  String get verificationCodeTitle => 'Verification code';

  @override
  String otpSentToPhone(String phone) {
    return 'Code sent to $phone.';
  }

  @override
  String get otpSentGeneric =>
      'We\'ve sent a 6-digit code to your mobile device.';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendCodeSeconds(int seconds) {
    return 'Resend code (${seconds}s)';
  }

  @override
  String get verifyCodeButton => 'Verify code';

  @override
  String get skipButton => 'Skip';

  @override
  String get profileWelcomeNew => 'Welcome!';

  @override
  String get profileWelcomeComplete => 'Complete your profile';

  @override
  String get profileAllFieldsOptional => 'All fields are optional.';

  @override
  String get profilePrefsTitle => 'Preferences';

  @override
  String get profilePrefsSubtitle =>
      'Used to personalize products, language and delivery defaults.';

  @override
  String get labelDefaultLongitude => 'Default longitude';

  @override
  String get labelDefaultLatitude => 'Default latitude';

  @override
  String get labelInterests => 'Interests';

  @override
  String get interestElectronics => 'Electronics';

  @override
  String get interestAppliances => 'Appliances';

  @override
  String get interestClothing => 'Clothing';

  @override
  String get interestFood => 'Food';

  @override
  String get interestBeauty => 'Beauty';

  @override
  String get interestSports => 'Sports';

  @override
  String get interestHome => 'Home';

  @override
  String get interestOther => 'Other';

  @override
  String get removePhotoTooltip => 'Remove photo';

  @override
  String get chooseFromGallery => 'Choose an image from gallery';

  @override
  String get labelUsername => 'Username';

  @override
  String get labelFirstName => 'First name';

  @override
  String get labelLastName => 'Last name';

  @override
  String get labelEmail => 'E-mail';

  @override
  String get hintUsername => 'e.g. neo_artisan';

  @override
  String get hintFirstName => 'First name';

  @override
  String get hintLastName => 'Last name';

  @override
  String get hintEmail => 'you@example.com';

  @override
  String get saveButton => 'Save';

  @override
  String get errorSupabaseNotConfigured =>
      'Supabase is not configured. Run the app with --dart-define=SUPABASE_URL=... and SUPABASE_ANON_KEY=...';

  @override
  String errorPhoneInvalid(int minNsn, int maxNsn, String countryName) {
    return 'Enter a valid country code and national number ($minNsn–$maxNsn digits for $countryName).';
  }

  @override
  String get errorApiBaseUrlOtp =>
      'API_BASE_URL is not configured. Add --dart-define=API_BASE_URL=https://your-api';

  @override
  String get errorApiBaseUrlProfile => 'API_BASE_URL is not configured.';

  @override
  String get errorOtpLength => 'Enter the 6 digits from the SMS.';

  @override
  String get errorGalleryUnavailable =>
      'Gallery unavailable: do a full build (see console message or stop the app, flutter clean, flutter pub get, uninstall the app then flutter run).';

  @override
  String get errorSessionExpired => 'Session expired. Sign in again.';

  @override
  String get errorInvalidEmail => 'Invalid email address.';

  @override
  String get errorInvalidCoordinates =>
      'Enter valid longitude and latitude values.';

  @override
  String get snackAddedToCart => 'Added to cart';

  @override
  String get retryButton => 'Retry';

  @override
  String get feedEmptyPosts => 'No posts yet.';

  @override
  String get feedFollowingBadge => 'Following';

  @override
  String get feedViewMerchant => 'View shop';

  @override
  String get snackSubscriptionCancelled => 'Subscription cancelled';

  @override
  String get snackFollowingShop => 'You are following this shop';

  @override
  String get subscribeButton => 'Subscribe';

  @override
  String get unsubscribeButton => 'Unsubscribe';

  @override
  String get snackMinMaxPrice => 'Min must be ≤ max.';

  @override
  String get applyButton => 'Apply';

  @override
  String get resetButton => 'Reset';

  @override
  String get navHome => 'Home';

  @override
  String get navNew => 'New';

  @override
  String get navMe => 'Me';

  @override
  String get homeSearchTooltip => 'Search';

  @override
  String get homeFiltersTooltip => 'Filters';

  @override
  String get homeSearchHint => 'Search for a product…';

  @override
  String get homeHeroTitle => 'Summer\nHarvest\nCollective';

  @override
  String get homeHeroSubtitle =>
      'Directly from the fertile valley farms to your kitchen.';

  @override
  String get homeCategoriesTitle => 'Categories';

  @override
  String get homeSelectionTitle => 'Selection';

  @override
  String get homeAllCategories => 'All';

  @override
  String get homeEmptyCatalog => 'No products match your search or filters.';

  @override
  String get filterSheetTitle => 'Filters';

  @override
  String get filterCategoryLabel => 'Category';

  @override
  String get filterPriceLabel => 'Unit price (min / max)';

  @override
  String filterPriceSummary(String min, String max) {
    return 'Price $min — $max';
  }

  @override
  String get errorApiNotConfigured =>
      'API_BASE_URL is not configured (dart-define).';

  @override
  String get errorSessionMissing => 'No session. Sign in again.';

  @override
  String get merchantDefaultShopName => 'Shop';

  @override
  String subscriberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subscribers',
      one: '$count subscriber',
    );
    return '$_temp0';
  }

  @override
  String get ordersTitle => 'My orders';

  @override
  String get ordersFilterAll => 'All';

  @override
  String get ordersFilterInProgress => 'In progress';

  @override
  String get ordersFilterInDelivery => 'In delivery';

  @override
  String get ordersFilterCancelled => 'Cancelled';

  @override
  String get ordersFilterCompleted => 'Completed';

  @override
  String get ordersEmpty => 'No orders in this category.';

  @override
  String ordersArticlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get orderDetailTitle => 'Order';

  @override
  String get orderShopLabel => 'Shop';

  @override
  String get orderPlacedLabel => 'Placed';

  @override
  String get orderArticlesTitle => 'Items';

  @override
  String get orderFulfillmentPickup => 'Pickup';

  @override
  String get orderFulfillmentDelivery => 'Delivery';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusInProgress => 'In progress';

  @override
  String get orderStatusInDelivery => 'In delivery';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderStatusCompleted => 'Completed';

  @override
  String get meOrderHistoryTitle => 'Order history';

  @override
  String get meOrderHistorySubtitle => 'Track and review your purchases';

  @override
  String get meProfileFallback => 'Profile';

  @override
  String get meCompleteProfile => 'Complete your profile';

  @override
  String get meOrdersStat => 'Orders';

  @override
  String get meWishlistStat => 'Wishlist';

  @override
  String get mePointsStat => 'Points';

  @override
  String get meAccountTitle => 'My account';

  @override
  String get meAccountSubtitle => 'Wallet, payments, and billing';

  @override
  String get meWishlistTitle => 'My wishlist';

  @override
  String get meWishlistSubtitle => 'Your favorite products';

  @override
  String get meCartTitle => 'My cart';

  @override
  String get meCartSubtitle => 'Items ready for checkout';

  @override
  String get orderConfirmReceiptTitle => 'Confirm receipt';

  @override
  String get orderConfirmReceiptScanTooltip => 'Scan receipt QR';

  @override
  String get orderConfirmReceiptHint =>
      'Point the camera at the QR shown by the shop or courier. It contains your order id and validation secret.';

  @override
  String get orderConfirmReceiptNoteLabel => 'Optional note';

  @override
  String get orderConfirmReceiptSuccess => 'Receipt confirmed.';

  @override
  String get orderDetailConfirmReceipt => 'Confirm receipt (QR)';

  @override
  String get orderManualQrLabel => 'Paste QR content';

  @override
  String get orderManualQrSubmit => 'Submit';

  @override
  String get orderScannerWebHint =>
      'Camera scanning may be limited in the browser — paste the QR payload below if needed.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get editProfileTooltip => 'Edit profile';

  @override
  String get settingsProfileSection => 'Profile';

  @override
  String get settingsPreferencesSection => 'Preferences';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String get settingsInterestsSection => 'Interests';

  @override
  String get settingsNameLabel => 'Name';

  @override
  String get settingsPhoneLabel => 'Phone';

  @override
  String get settingsLocationLabel => 'Location';

  @override
  String get settingsRegionLabel => 'Region';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsUndefined => 'Not set';

  @override
  String get profileUpdateTitle => 'Edit profile';

  @override
  String get profileUpdateSaveTooltip => 'Save';

  @override
  String get profileUpdateGenericError =>
      'Unable to update the profile. Try again.';

  @override
  String get profileUpdateConflictError =>
      'Email or username already used. Choose another value.';

  @override
  String get profileUpdatePhotoError => 'Unable to choose this photo.';

  @override
  String get profileUpdateLocationTitle => 'Location';

  @override
  String get profileUpdateLocationSubtitle =>
      'Use your current position or tap the map.';

  @override
  String get profileUpdateExpiredSession => 'Session expired. Sign in again.';

  @override
  String get signOutMenuTitle => 'Sign out';

  @override
  String get signOutMenuSubtitle => 'Disconnect this phone from e-Mall';

  @override
  String get signOutDialogTitle => 'Sign out?';

  @override
  String get signOutDialogBody =>
      'You will need to sign in again with your phone number.';

  @override
  String get signOutConfirm => 'Sign out';

  @override
  String get signOutCancel => 'Cancel';
}
