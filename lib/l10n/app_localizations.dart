import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @onboardingHandpicked.
  ///
  /// In en, this message translates to:
  /// **'Handpicked'**
  String get onboardingHandpicked;

  /// No description provided for @onboardingBrandTitle.
  ///
  /// In en, this message translates to:
  /// **'e-Mall'**
  String get onboardingBrandTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover a curated marketplace where heritage meets high-end digital shopping.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @onboardingPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get onboardingPhoneTitle;

  /// No description provided for @onboardingPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to access your artisan collection.'**
  String get onboardingPhoneSubtitle;

  /// No description provided for @labelCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get labelCountry;

  /// No description provided for @labelPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get labelPhoneNumber;

  /// No description provided for @phoneNationalHint.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get phoneNationalHint;

  /// No description provided for @phoneNationalHintNg.
  ///
  /// In en, this message translates to:
  /// **'80 000 0000'**
  String get phoneNationalHintNg;

  /// No description provided for @chooseCountryTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a country'**
  String get chooseCountryTitle;

  /// No description provided for @verificationCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCodeTitle;

  /// No description provided for @otpSentToPhone.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phone}.'**
  String otpSentToPhone(String phone);

  /// No description provided for @otpSentGeneric.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 6-digit code to your mobile device.'**
  String get otpSentGeneric;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendCodeSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend code ({seconds}s)'**
  String resendCodeSeconds(int seconds);

  /// No description provided for @verifyCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get verifyCodeButton;

  /// No description provided for @skipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// No description provided for @profileWelcomeNew.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get profileWelcomeNew;

  /// No description provided for @profileWelcomeComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profileWelcomeComplete;

  /// No description provided for @profileAllFieldsOptional.
  ///
  /// In en, this message translates to:
  /// **'All fields are optional.'**
  String get profileAllFieldsOptional;

  /// No description provided for @removePhotoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhotoTooltip;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose an image from gallery'**
  String get chooseFromGallery;

  /// No description provided for @labelUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get labelUsername;

  /// No description provided for @labelFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get labelFirstName;

  /// No description provided for @labelLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get labelLastName;

  /// No description provided for @labelEmail.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get labelEmail;

  /// No description provided for @hintUsername.
  ///
  /// In en, this message translates to:
  /// **'e.g. neo_artisan'**
  String get hintUsername;

  /// No description provided for @hintFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get hintFirstName;

  /// No description provided for @hintLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get hintLastName;

  /// No description provided for @hintEmail.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get hintEmail;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @errorSupabaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Supabase is not configured. Run the app with --dart-define=SUPABASE_URL=... and SUPABASE_ANON_KEY=...'**
  String get errorSupabaseNotConfigured;

  /// No description provided for @errorPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid country code and national number ({minNsn}–{maxNsn} digits for {countryName}).'**
  String errorPhoneInvalid(int minNsn, int maxNsn, String countryName);

  /// No description provided for @errorApiBaseUrlOtp.
  ///
  /// In en, this message translates to:
  /// **'API_BASE_URL is not configured. Add --dart-define=API_BASE_URL=https://your-api'**
  String get errorApiBaseUrlOtp;

  /// No description provided for @errorApiBaseUrlProfile.
  ///
  /// In en, this message translates to:
  /// **'API_BASE_URL is not configured.'**
  String get errorApiBaseUrlProfile;

  /// No description provided for @errorOtpLength.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6 digits from the SMS.'**
  String get errorOtpLength;

  /// No description provided for @errorGalleryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Gallery unavailable: do a full build (see console message or stop the app, flutter clean, flutter pub get, uninstall the app then flutter run).'**
  String get errorGalleryUnavailable;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get errorInvalidEmail;

  /// No description provided for @snackAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get snackAddedToCart;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @feedEmptyPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get feedEmptyPosts;

  /// No description provided for @feedFollowingBadge.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedFollowingBadge;

  /// No description provided for @feedViewMerchant.
  ///
  /// In en, this message translates to:
  /// **'View shop'**
  String get feedViewMerchant;

  /// No description provided for @snackSubscriptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Subscription cancelled'**
  String get snackSubscriptionCancelled;

  /// No description provided for @snackFollowingShop.
  ///
  /// In en, this message translates to:
  /// **'You are following this shop'**
  String get snackFollowingShop;

  /// No description provided for @subscribeButton.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribeButton;

  /// No description provided for @unsubscribeButton.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get unsubscribeButton;

  /// No description provided for @snackMinMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Min must be ≤ max.'**
  String get snackMinMaxPrice;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButton;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get navNew;

  /// No description provided for @navMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navMe;

  /// No description provided for @homeSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearchTooltip;

  /// No description provided for @homeFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get homeFiltersTooltip;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a product…'**
  String get homeSearchHint;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Summer\nHarvest\nCollective'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Directly from the fertile valley farms to your kitchen.'**
  String get homeHeroSubtitle;

  /// No description provided for @homeCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get homeCategoriesTitle;

  /// No description provided for @homeSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get homeSelectionTitle;

  /// No description provided for @homeAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeAllCategories;

  /// No description provided for @homeEmptyCatalog.
  ///
  /// In en, this message translates to:
  /// **'No products match your search or filters.'**
  String get homeEmptyCatalog;

  /// No description provided for @filterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterSheetTitle;

  /// No description provided for @filterCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategoryLabel;

  /// No description provided for @filterPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit price (min / max)'**
  String get filterPriceLabel;

  /// No description provided for @filterPriceSummary.
  ///
  /// In en, this message translates to:
  /// **'Price {min} — {max}'**
  String filterPriceSummary(String min, String max);

  /// No description provided for @errorApiNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'API_BASE_URL is not configured (dart-define).'**
  String get errorApiNotConfigured;

  /// No description provided for @errorSessionMissing.
  ///
  /// In en, this message translates to:
  /// **'No session. Sign in again.'**
  String get errorSessionMissing;

  /// No description provided for @merchantDefaultShopName.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get merchantDefaultShopName;

  /// No description provided for @subscriberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} subscriber} other{{count} subscribers}}'**
  String subscriberCount(int count);

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get ordersTitle;

  /// No description provided for @ordersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersFilterAll;

  /// No description provided for @ordersFilterInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get ordersFilterInProgress;

  /// No description provided for @ordersFilterInDelivery.
  ///
  /// In en, this message translates to:
  /// **'In delivery'**
  String get ordersFilterInDelivery;

  /// No description provided for @ordersFilterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ordersFilterCancelled;

  /// No description provided for @ordersFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ordersFilterCompleted;

  /// No description provided for @ordersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No orders in this category.'**
  String get ordersEmpty;

  /// No description provided for @ordersArticlesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item} other{{count} items}}'**
  String ordersArticlesCount(int count);

  /// No description provided for @orderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderDetailTitle;

  /// No description provided for @orderShopLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get orderShopLabel;

  /// No description provided for @orderPlacedLabel.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get orderPlacedLabel;

  /// No description provided for @orderArticlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get orderArticlesTitle;

  /// No description provided for @orderFulfillmentPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get orderFulfillmentPickup;

  /// No description provided for @orderFulfillmentDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get orderFulfillmentDelivery;

  /// No description provided for @orderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderStatusPending;

  /// No description provided for @orderStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get orderStatusInProgress;

  /// No description provided for @orderStatusInDelivery.
  ///
  /// In en, this message translates to:
  /// **'In delivery'**
  String get orderStatusInDelivery;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orderStatusCompleted;

  /// No description provided for @meOrderHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Order history'**
  String get meOrderHistoryTitle;

  /// No description provided for @meOrderHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track and review your purchases'**
  String get meOrderHistorySubtitle;

  /// No description provided for @orderConfirmReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm receipt'**
  String get orderConfirmReceiptTitle;

  /// No description provided for @orderConfirmReceiptScanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt QR'**
  String get orderConfirmReceiptScanTooltip;

  /// No description provided for @orderConfirmReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR shown by the shop or courier. It contains your order id and validation secret.'**
  String get orderConfirmReceiptHint;

  /// No description provided for @orderConfirmReceiptNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get orderConfirmReceiptNoteLabel;

  /// No description provided for @orderConfirmReceiptSuccess.
  ///
  /// In en, this message translates to:
  /// **'Receipt confirmed.'**
  String get orderConfirmReceiptSuccess;

  /// No description provided for @orderDetailConfirmReceipt.
  ///
  /// In en, this message translates to:
  /// **'Confirm receipt (QR)'**
  String get orderDetailConfirmReceipt;

  /// No description provided for @orderManualQrLabel.
  ///
  /// In en, this message translates to:
  /// **'Paste QR content'**
  String get orderManualQrLabel;

  /// No description provided for @orderManualQrSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get orderManualQrSubmit;

  /// No description provided for @orderScannerWebHint.
  ///
  /// In en, this message translates to:
  /// **'Camera scanning may be limited in the browser — paste the QR payload below if needed.'**
  String get orderScannerWebHint;

  /// No description provided for @signOutMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutMenuTitle;

  /// No description provided for @signOutMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect this phone from e-Mall'**
  String get signOutMenuSubtitle;

  /// No description provided for @signOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutDialogTitle;

  /// No description provided for @signOutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again with your phone number.'**
  String get signOutDialogBody;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutConfirm;

  /// No description provided for @signOutCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get signOutCancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
