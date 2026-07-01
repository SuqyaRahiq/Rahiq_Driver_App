// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rahiq Driver';

  @override
  String get login => 'Login';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get password => 'Password';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get logout => 'Logout';

  @override
  String get supplier => 'Supplier';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get myAccount => 'My Account';

  @override
  String get termsConditions => 'Terms & Conditions';

  @override
  String get accountSection => 'Account';

  @override
  String get welcomeToTheDriverDashboard => 'Welcome to the Driver Dashboard';

  @override
  String get manageAccountSettings => 'Manage account settings';

  @override
  String get appSettings => 'App Settings';

  @override
  String get buildNumber => 'Build Number';

  @override
  String get version => 'Version';

  @override
  String get appInformation => 'App Information';

  @override
  String get appLanguage => 'App Language';

  @override
  String get managePreferencesAndAppInfo => 'Manage preferences and app info';

  @override
  String get home => 'Home';

  @override
  String get orders => 'Orders';

  @override
  String get autodelivery => 'Autodelivery';

  @override
  String get dashboard => 'Dashboard';

  @override
  String orderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String autoOrderNumber(String id) {
    return 'Auto Order #$id';
  }

  @override
  String get tryAgain => 'Try Again';

  @override
  String get video => 'Video';

  @override
  String get mosqueFront => 'Mosque Front';

  @override
  String get mosqueInsideImage => 'Mosque Inside Image';

  @override
  String get productInsideMosque => 'Product Inside Mosque';

  @override
  String get mosqueName => 'Mosque Name';

  @override
  String get productPlaced => 'Product Placed';

  @override
  String get takeAVideo => 'Take a Video';

  @override
  String get takeAPhoto => 'Take a Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String error(String errorText) {
    return 'Error: $errorText';
  }

  @override
  String get english => 'English';

  @override
  String get arabic => 'عربي';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get email => 'Email';

  @override
  String get gender => 'Gender';

  @override
  String get contactDetails => 'Contact Details';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get status => 'Status';

  @override
  String get driverType => 'Driver Type';

  @override
  String get vehicleId => 'Vehicle ID';

  @override
  String get accountHistory => 'Account History';

  @override
  String get memberSince => 'Member Since';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get enterPhoneNumber => 'Enter phone number';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get normalOrders => 'Normal orders';

  @override
  String get autoOrders => 'Auto orders';

  @override
  String get uploadMediaToSupportDeliveryCompletion =>
      'Upload media to support delivery completion';

  @override
  String get viewAndManageAssignedOrders =>
      'View and manage your assigned orders';

  @override
  String noOrders(String tabLabel) {
    return 'No $tabLabel';
  }

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get completeOrder => 'Complete order';

  @override
  String get completeSelectedOrders => 'Complete selected orders';

  @override
  String get customerDetails => 'Customer Details';

  @override
  String get nameLabel => 'Name';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get addressLabel => 'Address';

  @override
  String get orderInfo => 'Order Info';

  @override
  String get paymentLabel => 'Payment';

  @override
  String get totalLabel => 'Total';

  @override
  String get subOrdersLabel => 'Sub Orders';

  @override
  String get pending => 'Pending';

  @override
  String get delivered => 'Delivered';

  @override
  String get unknownCustomer => 'Unknown Customer';

  @override
  String get batchDeliveries => 'Batch Deliveries';

  @override
  String notes(String notes) {
    return 'Notes: $notes';
  }

  @override
  String assigned(String date) {
    return 'Assigned: $date';
  }

  @override
  String get product => 'Product';

  @override
  String qty(String qty) {
    return 'Qty: $qty';
  }

  @override
  String subOrderNumber(String id) {
    return 'Sub-order #$id';
  }

  @override
  String get uploadingProof => 'Uploading proof, please wait...';

  @override
  String get completingOrder => 'Completing order...';

  @override
  String get submitDeliveryProof => 'Submit Delivery Proof';

  @override
  String get imagesInstructions => 'Images (Please take three correct images)';

  @override
  String get proofsUploaded => 'Proofs uploaded successfully!';

  @override
  String get completeOrders => 'Complete orders';

  @override
  String get selectSource => 'Select Source';

  @override
  String get requiredField => 'Required';

  @override
  String get yourPersonalInformation => 'Your personal information';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get accountBlocked => 'Account Blocked';

  @override
  String get accountSuspendedMessage =>
      'Your account has been temporarily suspended.\nPlease contact our support team to resolve this issue and restore your access.';

  @override
  String get needHelp => 'Need help?';

  @override
  String get contactOurTeam => 'Contact Our Team';

  @override
  String get goBack => 'Go Back';

  @override
  String get contactSupportMessage =>
      'Please reach out to our support team:\n\n info@suqyarahiq.com';

  @override
  String get activeDriver => 'Active Driver';

  @override
  String get getDirections => 'Get Directions';

  @override
  String get assignedStat => 'Assigned';

  @override
  String get confirmedStat => 'Confirmed';

  @override
  String get packagesStat => 'Packages';

  @override
  String get todayDeliveriesStat => 'Today\'s Deliveries';

  @override
  String get todayPackagesStat => 'Today\'s Packages';

  @override
  String get typeLabel => 'Type';

  @override
  String get locationLabel => 'Location';

  @override
  String get cityLabel => 'City';

  @override
  String get zoneLabel => 'Zone';

  @override
  String get totalPackagesLabel => 'Total Packages';

  @override
  String get typeCampaign => 'Campaign';

  @override
  String get typeCategory => 'Category';

  @override
  String get typeOrphanage => 'Orphanage';

  @override
  String get typeLocation => 'Location';

  @override
  String get saveImages => 'Save Images';

  @override
  String get uploadBatchImages => 'Upload Batch Images';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get rejected => 'Rejected';

  @override
  String get inTransit => 'In Transit';

  @override
  String get accepted => 'Accepted';

  @override
  String get latest_updates_and_alerts => 'Latest updates and alerts';

  @override
  String get mark_all_read => 'Mark all read';

  @override
  String get clear_notifications => 'Clear notifications';

  @override
  String get failed_to_clear_notifications => 'Failed to clear notifications';

  @override
  String get failed_to_mark_all_as_read => 'Failed to mark all as read';

  @override
  String get no_new_notifications => 'No new notifications';

  @override
  String get bankAccountDetails => 'Bank Account Details';

  @override
  String get bankFullName => 'Account Holder Name';

  @override
  String get bankName => 'Bank Name';

  @override
  String get bankAccountNumber => 'Account Number';

  @override
  String get bankIbanNumber => 'IBAN Number';

  @override
  String get noBankDetails => 'No bank details added';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get viewAndManageOrders => 'View and manage assigned orders';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get vehicleDetails => 'Vehicle Details';

  @override
  String get vehicleName => 'Vehicle Name';

  @override
  String get capacity => 'Capacity';

  @override
  String get packages => 'Packages';

  @override
  String get productDetails => 'Product Details';

  @override
  String get videoDurationLimitNote =>
      'Note: Video duration should not exceed 10 seconds.';

  @override
  String get videoDurationLimitError =>
      'Video duration should not exceed 10 seconds.';

  @override
  String get missingMediaError => 'Please provide all required media.';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';
}
