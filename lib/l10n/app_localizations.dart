import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rahiq Driver'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @welcomeToTheDriverDashboard.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Driver Dashboard'**
  String get welcomeToTheDriverDashboard;

  /// No description provided for @manageAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage account settings'**
  String get manageAccountSettings;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @appInformation.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInformation;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @managePreferencesAndAppInfo.
  ///
  /// In en, this message translates to:
  /// **'Manage preferences and app info'**
  String get managePreferencesAndAppInfo;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @autodelivery.
  ///
  /// In en, this message translates to:
  /// **'Autodelivery'**
  String get autodelivery;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderNumber(String id);

  /// No description provided for @autoOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Auto Order #{id}'**
  String autoOrderNumber(String id);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @mosqueFront.
  ///
  /// In en, this message translates to:
  /// **'Mosque Front'**
  String get mosqueFront;

  /// No description provided for @mosqueInsideImage.
  ///
  /// In en, this message translates to:
  /// **'Mosque Inside Image'**
  String get mosqueInsideImage;

  /// No description provided for @productInsideMosque.
  ///
  /// In en, this message translates to:
  /// **'Product Inside Mosque'**
  String get productInsideMosque;

  /// No description provided for @mosqueName.
  ///
  /// In en, this message translates to:
  /// **'Mosque Name'**
  String get mosqueName;

  /// No description provided for @productPlaced.
  ///
  /// In en, this message translates to:
  /// **'Product Placed'**
  String get productPlaced;

  /// No description provided for @takeAVideo.
  ///
  /// In en, this message translates to:
  /// **'Take a Video'**
  String get takeAVideo;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takeAPhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {errorText}'**
  String error(String errorText);

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'عربي'**
  String get arabic;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @driverType.
  ///
  /// In en, this message translates to:
  /// **'Driver Type'**
  String get driverType;

  /// No description provided for @vehicleId.
  ///
  /// In en, this message translates to:
  /// **'Vehicle ID'**
  String get vehicleId;

  /// No description provided for @accountHistory.
  ///
  /// In en, this message translates to:
  /// **'Account History'**
  String get accountHistory;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @normalOrders.
  ///
  /// In en, this message translates to:
  /// **'Normal orders'**
  String get normalOrders;

  /// No description provided for @autoOrders.
  ///
  /// In en, this message translates to:
  /// **'Auto orders'**
  String get autoOrders;

  /// No description provided for @uploadMediaToSupportDeliveryCompletion.
  ///
  /// In en, this message translates to:
  /// **'Upload media to support delivery completion'**
  String get uploadMediaToSupportDeliveryCompletion;

  /// No description provided for @viewAndManageAssignedOrders.
  ///
  /// In en, this message translates to:
  /// **'View and manage your assigned orders'**
  String get viewAndManageAssignedOrders;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No {tabLabel}'**
  String noOrders(String tabLabel);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @completeOrder.
  ///
  /// In en, this message translates to:
  /// **'Complete order'**
  String get completeOrder;

  /// No description provided for @completeSelectedOrders.
  ///
  /// In en, this message translates to:
  /// **'Complete selected orders'**
  String get completeSelectedOrders;

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetails;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @orderInfo.
  ///
  /// In en, this message translates to:
  /// **'Order Info'**
  String get orderInfo;

  /// No description provided for @paymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @subOrdersLabel.
  ///
  /// In en, this message translates to:
  /// **'Sub Orders'**
  String get subOrdersLabel;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @unknownCustomer.
  ///
  /// In en, this message translates to:
  /// **'Unknown Customer'**
  String get unknownCustomer;

  /// No description provided for @batchDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Batch Deliveries'**
  String get batchDeliveries;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes: {notes}'**
  String notes(String notes);

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {date}'**
  String assigned(String date);

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty}'**
  String qty(String qty);

  /// No description provided for @subOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Sub-order #{id}'**
  String subOrderNumber(String id);

  /// No description provided for @uploadingProof.
  ///
  /// In en, this message translates to:
  /// **'Uploading proof, please wait...'**
  String get uploadingProof;

  /// No description provided for @completingOrder.
  ///
  /// In en, this message translates to:
  /// **'Completing order...'**
  String get completingOrder;

  /// No description provided for @submitDeliveryProof.
  ///
  /// In en, this message translates to:
  /// **'Submit Delivery Proof'**
  String get submitDeliveryProof;

  /// No description provided for @imagesInstructions.
  ///
  /// In en, this message translates to:
  /// **'Images (Please take three correct images)'**
  String get imagesInstructions;

  /// No description provided for @proofsUploaded.
  ///
  /// In en, this message translates to:
  /// **'Proofs uploaded successfully!'**
  String get proofsUploaded;

  /// No description provided for @completeOrders.
  ///
  /// In en, this message translates to:
  /// **'Complete orders'**
  String get completeOrders;

  /// No description provided for @selectSource.
  ///
  /// In en, this message translates to:
  /// **'Select Source'**
  String get selectSource;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @yourPersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Your personal information'**
  String get yourPersonalInformation;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @accountBlocked.
  ///
  /// In en, this message translates to:
  /// **'Account Blocked'**
  String get accountBlocked;

  /// No description provided for @accountSuspendedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been temporarily suspended.\nPlease contact our support team to resolve this issue and restore your access.'**
  String get accountSuspendedMessage;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get needHelp;

  /// No description provided for @contactOurTeam.
  ///
  /// In en, this message translates to:
  /// **'Contact Our Team'**
  String get contactOurTeam;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @contactSupportMessage.
  ///
  /// In en, this message translates to:
  /// **'Please reach out to our support team:\n\n info@suqyarahiq.com'**
  String get contactSupportMessage;

  /// No description provided for @activeDriver.
  ///
  /// In en, this message translates to:
  /// **'Active Driver'**
  String get activeDriver;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @assignedStat.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assignedStat;

  /// No description provided for @confirmedStat.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmedStat;

  /// No description provided for @packagesStat.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get packagesStat;

  /// No description provided for @todayDeliveriesStat.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Deliveries'**
  String get todayDeliveriesStat;

  /// No description provided for @todayPackagesStat.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Packages'**
  String get todayPackagesStat;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @zoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zoneLabel;

  /// No description provided for @totalPackagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Packages'**
  String get totalPackagesLabel;

  /// No description provided for @typeCampaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get typeCampaign;

  /// No description provided for @typeCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get typeCategory;

  /// No description provided for @typeOrphanage.
  ///
  /// In en, this message translates to:
  /// **'Orphanage'**
  String get typeOrphanage;

  /// No description provided for @typeLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get typeLocation;

  /// No description provided for @saveImages.
  ///
  /// In en, this message translates to:
  /// **'Save Images'**
  String get saveImages;

  /// No description provided for @uploadBatchImages.
  ///
  /// In en, this message translates to:
  /// **'Upload Batch Images'**
  String get uploadBatchImages;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @inTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get inTransit;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @latest_updates_and_alerts.
  ///
  /// In en, this message translates to:
  /// **'Latest updates and alerts'**
  String get latest_updates_and_alerts;

  /// No description provided for @mark_all_read.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get mark_all_read;

  /// No description provided for @clear_notifications.
  ///
  /// In en, this message translates to:
  /// **'Clear notifications'**
  String get clear_notifications;

  /// No description provided for @failed_to_clear_notifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear notifications'**
  String get failed_to_clear_notifications;

  /// No description provided for @failed_to_mark_all_as_read.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark all as read'**
  String get failed_to_mark_all_as_read;

  /// No description provided for @no_new_notifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get no_new_notifications;

  /// No description provided for @bankAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Details'**
  String get bankAccountDetails;

  /// No description provided for @bankFullName.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name'**
  String get bankFullName;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @bankAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get bankAccountNumber;

  /// No description provided for @bankIbanNumber.
  ///
  /// In en, this message translates to:
  /// **'IBAN Number'**
  String get bankIbanNumber;

  /// No description provided for @noBankDetails.
  ///
  /// In en, this message translates to:
  /// **'No bank details added'**
  String get noBankDetails;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @viewAndManageOrders.
  ///
  /// In en, this message translates to:
  /// **'View and manage assigned orders'**
  String get viewAndManageOrders;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @vehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details'**
  String get vehicleDetails;

  /// No description provided for @vehicleName.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Name'**
  String get vehicleName;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @videoDurationLimitNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Video duration should not exceed 10 seconds.'**
  String get videoDurationLimitNote;

  /// No description provided for @videoDurationLimitError.
  ///
  /// In en, this message translates to:
  /// **'Video duration should not exceed 10 seconds.'**
  String get videoDurationLimitError;

  /// No description provided for @missingMediaError.
  ///
  /// In en, this message translates to:
  /// **'Please provide all required media.'**
  String get missingMediaError;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
