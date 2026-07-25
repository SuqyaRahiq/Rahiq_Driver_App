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
  String get pastOrders => 'الطلبات السابقة';

  @override
  String get supplier => 'المُوَرِّد';

  @override
  String get selectDeliveredLocationOptional =>
      'اختر الموقع الذي تم التوصيل إليه (اختياري)';

  @override
  String get logoutConfirmation => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get myAccount => 'حسابي';

  @override
  String get termsConditions => 'الشروط والأحكام';

  @override
  String get failed_to_load_locations => 'تعذر تحميل المواقع';

  @override
  String get select_delivered_location =>
      'اختر الموقع الذي تم التوصيل إليه (اختياري)';

  @override
  String get no_locations_available => 'لا توجد مواقع متاحة';

  @override
  String get no_reason_selected => 'لم يتم اختيار سبب';

  @override
  String get select_delivery_location => 'اختر الموقع الذي تم التوصيل إليه';

  @override
  String get accountSection => 'الحساب';

  @override
  String get welcomeToTheDriverDashboard => 'مرحبًا بك في لوحة تحكم السائق';

  @override
  String get delivery_location => 'موقع التوصيل';

  @override
  String get manageAccountSettings => 'إدارة إعدادات الحساب';

  @override
  String get reason_for_not_delivered => 'سبب عدم التوصيل';

  @override
  String get not_delivered => 'لم يتم التوصيل';

  @override
  String get appSettings => 'إعدادات التطبيق';

  @override
  String get delivered_to_target_location => 'تم التوصيل إلى الموقع المحدد';

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
  String get orphanageFront => 'واجهة دار الأيتام';

  @override
  String get graveyardFront => 'واجهة المقبرة';

  @override
  String get mosqueInsideImage => 'صورة داخل المسجد';

  @override
  String get orphanageInsideImage => 'صورة داخل دار الأيتام';

  @override
  String get graveyardInsideImage => 'صورة داخل المقبرة';

  @override
  String get productInsideMosque => 'المنتج داخل المسجد';

  @override
  String get productInsideOrphanage => 'المنتج داخل دار الأيتام';

  @override
  String get productInsideGraveyard => 'المنتج داخل المقبرة';

  @override
  String get batch_Number => 'رقم الدفعة';

  @override
  String get uploadingVideo => 'جاري رفع الفيديو';

  @override
  String get uploadingImages => 'جاري رفع الصور';

  @override
  String get almostThere => 'أوشكنا على الانتهاء';

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
  String get fullName => 'الاسم الكامل';

  @override
  String get username => 'اسم المستخدم';

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
  String get pleaseEnterYourPhoneNumber => 'الرجاء إدخال رقم الهاتف';

  @override
  String get enterUsername => 'أدخل اسم المستخدم';

  @override
  String get pleaseEnterYourUsername => 'الرجاء إدخال اسم المستخدم';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get pleaseEnterYourPassword => 'الرجاء إدخال كلمة المرور';

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

  @override
  String get bankAccountDetails => 'تفاصيل الحساب البنكي';

  @override
  String get bankFullName => 'اسم صاحب الحساب';

  @override
  String get bankName => 'اسم البنك';

  @override
  String get bankAccountNumber => 'رقم الحساب';

  @override
  String get bankIbanNumber => 'رقم الآيبان';

  @override
  String get noBankDetails => 'لم يتم إضافة تفاصيل بنكية';

  @override
  String get orderDetails => 'تفاصيل الطلب';

  @override
  String get viewAndManageOrders => 'عرض وإدارة الطلبات';

  @override
  String get vehicle => 'المركبة';

  @override
  String get vehicleDetails => 'تفاصيل المركبة';

  @override
  String get vehicleName => 'اسم المركبة';

  @override
  String get capacity => 'السعة';

  @override
  String get packages => 'الطرود';

  @override
  String get productDetails => 'تفاصيل المنتج';

  @override
  String get mediaLimitNote =>
      'ملاحظة: يجب ألا يتجاوز حجم الصورة/الفيديو 10 ميغابايت. يجب ألا تتجاوز مدة الفيديو 10 ثوانٍ.';

  @override
  String get videoDurationLimitError => 'يجب ألا تتجاوز مدة الفيديو 10 ثوانٍ.';

  @override
  String get videoSizeLimitError => 'يجب ألا يتجاوز حجم الفيديو 6 ميغابايت.';

  @override
  String get imageSizeLimitError => 'يجب ألا يتجاوز حجم الصورة 2 ميغابايت.';

  @override
  String get missingMediaError => 'يرجى توفير جميع الوسائط المطلوبة.';

  @override
  String get save => 'حفظ';

  @override
  String get edit => 'تعديل';

  @override
  String get add => 'إضافة';

  @override
  String get welcome => 'أهلًا بك';

  @override
  String get choose_specific_orphanage => 'اختر دار أيتام محدد';

  @override
  String get select_an_orphanage_to_deliver_water_to =>
      'اختر دار أيتام لتوصيل الماء إليه';

  @override
  String get list_of_orphanages => 'قائمة دور الأيتام';

  @override
  String get choose_specific_meqat_mosque => 'اختر ميقات محدد';

  @override
  String get select_a_mosque_to_deliver_water_to =>
      'اختر مسجد لتوصيل الماء إليه';

  @override
  String get list_of_meqat_mosques => 'قائمة المواقيت';

  @override
  String get contact_customer => 'تواصل مع العميل';

  @override
  String get continue_text => 'متابعة';

  @override
  String get order_photos_and_video => 'صور وفيديو الطلب';

  @override
  String get mosque_photos => 'صور المسجد';

  @override
  String get orphanage_photos => 'صور دار الأيتام';

  @override
  String get graveyard_photos => 'صور المقبرة';

  @override
  String get choose_specific_mosque => 'اختر مسجد محدد';

  @override
  String get list_of_mosques => 'قائمة المساجد';

  @override
  String get products => 'المنتجات';

  @override
  String get selected => 'محدد';

  @override
  String get ordersSelected => 'الطلبات المحددة';

  @override
  String get search_orphanages => 'ابحث عن دار أيتام';

  @override
  String get search_meqat_mosques => 'ابحث عن ميقات';

  @override
  String get search_mosques => 'ابحث عن مسجد';

  @override
  String get privacy_policy => 'سياسة الخصوصية';

  @override
  String get choose_from_map => 'اختر من الخريطة';

  @override
  String get select_city => 'اختر المدينة';

  @override
  String get select_category => 'اختر الفئة';

  @override
  String get mosque => 'مسجد';

  @override
  String get meqat_mosque => 'ميقات';

  @override
  String get orphanage => 'دار أيتام';

  @override
  String get reasonForChangingLocation => 'سبب تغيير الموقع...';

  @override
  String get selectLocation => 'اختر الموقع';

  @override
  String get selectNewLocation => 'اختر موقع جديد';

  @override
  String get date => 'تاريخ';

  @override
  String get quantity => 'الكمية';

  @override
  String get notes_text => 'ملاحظات';

  @override
  String get select_all => 'اختر الكل';

  @override
  String get customer_name => 'اسم العميل';

  @override
  String get showMenu => 'عرض القائمة';

  @override
  String get customer_note => 'ملاحظة العميل';

  @override
  String get customer_service_notes => 'ملاحظات خدمة العملاء';

  @override
  String whatsappDriverMessage(String orderNumber) {
    return 'عزيزي العميل، هذا هو مندوب التوصيل الخاص بك من تطبيق رحيق بخصوص طلبك رقم #$orderNumber.';
  }
}
