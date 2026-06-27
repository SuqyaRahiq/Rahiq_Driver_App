// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'رحيق السائق';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get password => 'كلمة المرور';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirmation => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get myAccount => 'حسابي';

  @override
  String get termsConditions => 'الشروط والأحكام';

  @override
  String get accountSection => 'الحساب';

  @override
  String get welcomeToTheDriverDashboard => 'مرحبًا بك في لوحة تحكم السائق';

  @override
  String get manageAccountSettings => 'إدارة إعدادات الحساب';

  @override
  String get appSettings => 'إعدادات التطبيق';

  @override
  String get buildNumber => 'رقم البناء';

  @override
  String get version => 'الإصدار';

  @override
  String get appInformation => 'معلومات التطبيق';

  @override
  String get appLanguage => 'لغة التطبيق';

  @override
  String get managePreferencesAndAppInfo => 'إدارة التفضيلات ومعلومات التطبيق';

  @override
  String get home => 'الرئيسية';

  @override
  String get orders => 'الطلبات';

  @override
  String get autodelivery => 'التوصيل التلقائي';

  @override
  String get dashboard => 'لوحة القيادة';

  @override
  String orderNumber(String id) {
    return 'طلب #$id';
  }

  @override
  String autoOrderNumber(String id) {
    return 'طلب تلقائي #$id';
  }

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get video => 'فيديو';

  @override
  String get mosqueFront => 'واجهة المسجد';

  @override
  String get mosqueInsideImage => 'صورة داخل المسجد';

  @override
  String get productInsideMosque => 'المنتج داخل المسجد';

  @override
  String get mosqueName => 'اسم المسجد';

  @override
  String get productPlaced => 'تم وضع المنتج';

  @override
  String get takeAVideo => 'التقط فيديو';

  @override
  String get takeAPhoto => 'التقط صورة';

  @override
  String get chooseFromGallery => 'اختر من المعرض';

  @override
  String error(String errorText) {
    return 'خطأ: $errorText';
  }

  @override
  String get english => 'English';

  @override
  String get arabic => 'عربي';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get lastName => 'الاسم الأخير';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get gender => 'الجنس';

  @override
  String get contactDetails => 'تفاصيل الاتصال';

  @override
  String get accountDetails => 'تفاصيل الحساب';

  @override
  String get status => 'الحالة';

  @override
  String get driverType => 'نوع السائق';

  @override
  String get vehicleId => 'رقم المركبة';

  @override
  String get accountHistory => 'سجل الحساب';

  @override
  String get memberSince => 'عضو منذ';

  @override
  String get lastUpdated => 'آخر تحديث';

  @override
  String get contactSupport => 'اتصل بالدعم';

  @override
  String get close => 'إغلاق';

  @override
  String get search => 'بحث';

  @override
  String get enterPhoneNumber => 'أدخل رقم الهاتف';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get normalOrders => 'الطلبات العادية';

  @override
  String get autoOrders => 'الطلبات التلقائية';

  @override
  String get uploadMediaToSupportDeliveryCompletion =>
      'قم بتحميل الوسائط لدعم إتمام عملية التسليم';

  @override
  String get viewAndManageAssignedOrders => 'عرض وإدارة طلباتك المعينة';

  @override
  String noOrders(String tabLabel) {
    return 'لا توجد $tabLabel';
  }

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get completeOrder => 'إكمال الطلب';

  @override
  String get completeSelectedOrders => 'إكمال الطلبات المحددة';

  @override
  String get customerDetails => 'تفاصيل العميل';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get addressLabel => 'العنوان';

  @override
  String get orderInfo => 'معلومات الطلب';

  @override
  String get paymentLabel => 'الدفع';

  @override
  String get totalLabel => 'المجموع';

  @override
  String get subOrdersLabel => 'الطلبات الفرعية';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get delivered => 'تم التوصيل';

  @override
  String get unknownCustomer => 'عميل غير معروف';

  @override
  String get batchDeliveries => 'تسليمات الدفعة';

  @override
  String notes(String notes) {
    return 'ملاحظات: $notes';
  }

  @override
  String assigned(String date) {
    return 'تم التعيين: $date';
  }

  @override
  String get product => 'المنتج';

  @override
  String qty(String qty) {
    return 'الكمية: $qty';
  }

  @override
  String subOrderNumber(String id) {
    return 'طلب فرعي #$id';
  }

  @override
  String get uploadingProof => 'جاري رفع الإثبات، يرجى الانتظار...';

  @override
  String get completingOrder => 'جاري إكمال الطلب...';

  @override
  String get submitDeliveryProof => 'إرسال إثبات التوصيل';

  @override
  String get imagesInstructions => 'الصور (يرجى التقاط ثلاث صور صحيحة)';

  @override
  String get proofsUploaded => 'تم رفع الإثباتات بنجاح!';

  @override
  String get completeOrders => 'إكمال الطلبات';

  @override
  String get selectSource => 'اختر المصدر';

  @override
  String get requiredField => 'مطلوب';

  @override
  String get yourPersonalInformation => 'معلوماتك الشخصية';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get accountBlocked => 'الحساب محظور';

  @override
  String get accountSuspendedMessage =>
      'تم تعليق حسابك مؤقتًا.\nيرجى الاتصال بفريق الدعم لحل هذه المشكلة واستعادة وصولك.';

  @override
  String get needHelp => 'هل تحتاج إلى مساعدة؟';

  @override
  String get contactOurTeam => 'اتصل بفريقنا';

  @override
  String get goBack => 'رجوع';

  @override
  String get contactSupportMessage =>
      'يرجى التواصل مع فريق الدعم:\n\n info@suqyarahiq.com';

  @override
  String get activeDriver => 'سائق نشط';

  @override
  String get getDirections => 'احصل على الاتجاهات';

  @override
  String get assignedStat => 'المُسندة';

  @override
  String get confirmedStat => 'المؤكدة';

  @override
  String get packagesStat => 'الطرود';

  @override
  String get todayDeliveriesStat => 'توصيلات اليوم';

  @override
  String get todayPackagesStat => 'طرود اليوم';

  @override
  String get typeLabel => 'النوع';

  @override
  String get locationLabel => 'الموقع';

  @override
  String get cityLabel => 'المدينة';

  @override
  String get zoneLabel => 'المنطقة';

  @override
  String get totalPackagesLabel => 'إجمالي عدد الطرود';

  @override
  String get typeCampaign => 'حملة';

  @override
  String get typeCategory => 'فئة';

  @override
  String get typeOrphanage => 'دار أيتام';

  @override
  String get typeLocation => 'موقع';

  @override
  String get saveImages => 'حفظ الصور';

  @override
  String get uploadBatchImages => 'رفع مجموعة صور';

  @override
  String get completed => 'مكتمل';

  @override
  String get cancelled => 'ملغى';

  @override
  String get rejected => 'مرفوض';

  @override
  String get inTransit => 'في الطريق';

  @override
  String get accepted => 'مقبول';

  @override
  String get latest_updates_and_alerts => 'أحدث التحديثات والتنبيهات';

  @override
  String get mark_all_read => 'تحديد الكل كمقروء';

  @override
  String get clear_notifications => 'مسح الإشعارات';

  @override
  String get failed_to_clear_notifications => 'فشل في مسح الإشعارات';

  @override
  String get failed_to_mark_all_as_read => 'فشل في تحديد الكل كمقروء';

  @override
  String get no_new_notifications => 'لا توجد إشعارات جديدة';
}
