// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تطبيق التوصيل';

  @override
  String get deliveryLogin => 'تسجيل دخول التوصيل';

  @override
  String get loginSubtitle => 'سجل الدخول للوصول إلى مهام التوصيل الخاصة بك';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get enterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get pleaseEnterEmail => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get pleaseEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get validEmailError => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get map => 'الخريطة';

  @override
  String get orders => 'الطلبات';

  @override
  String get history => 'التاريخ';

  @override
  String get deliveryOverview => 'نظرة عامة على التوصيل';

  @override
  String get total => 'المجموع';

  @override
  String get active => 'نشط';

  @override
  String get navigatingToCustomer => 'التوجه إلى العميل';

  @override
  String get eta => 'الوقت المتوقع';

  @override
  String get distance => 'المسافة';

  @override
  String get elapsed => 'المنقضي';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get complete => 'مكتمل';

  @override
  String get startDelivery => 'بدء التوصيل';

  @override
  String get markDelivered => 'تحديد كمسلم';

  @override
  String get customer => 'العميل';

  @override
  String get phone => 'الهاتف';

  @override
  String get deliveryAddress => 'عنوان التوصيل';

  @override
  String get amount => 'المبلغ';

  @override
  String get items => 'العناصر';

  @override
  String get orderNotes => 'ملاحظات الطلب';

  @override
  String get assigned => 'مُكلف';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String get delivered => 'مُسلم';

  @override
  String get cancelled => 'ملغى';

  @override
  String get pending => 'في الانتظار';

  @override
  String get ready => 'جاهز';

  @override
  String get waiting => 'انتظار';

  @override
  String get noActiveDeliveries => 'لا توجد توصيلات نشطة';

  @override
  String get checkOrdersTab => 'تحقق من تبويب الطلبات للحصول على مهام جديدة';

  @override
  String get orderDetails => 'تفاصيل الطلب';

  @override
  String get orderSummary => 'ملخص الطلب';

  @override
  String get contactInformation => 'معلومات الاتصال';

  @override
  String get orderInformation => 'معلومات الطلب';

  @override
  String get customerSignature => 'توقيع العميل';

  @override
  String get completeDelivery => 'إنهاء التوصيل';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get cashPayment => 'دفع نقدي';

  @override
  String get partialPayment => 'دفع جزئي';

  @override
  String get addToAccount => 'إضافة إلى الحساب';

  @override
  String get deliveryNotes => 'ملاحظات التوصيل';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get refresh => 'تحديث';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جاري التحميل';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجح';

  @override
  String get noOrdersAvailable => 'لا توجد توصيلات نشطة';

  @override
  String get noOrdersSubtitle =>
      'ليس لديك أي توصيلات مُكلفة في الوقت الحالي.\nتحقق مرة أخرى لاحقاً للحصول على مهام جديدة.';

  @override
  String get refreshOrders => 'تحديث الطلبات';

  @override
  String get batchDelivery => 'توصيل مجمع';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get multiSelect => 'تحديد متعدد';

  @override
  String get exitSelection => 'إنهاء التحديد';

  @override
  String startBatch(int count) {
    return 'بدء $count';
  }
}
