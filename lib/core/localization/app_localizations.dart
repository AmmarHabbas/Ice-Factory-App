import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  // Static maps as fallback to ensure the app compiles and runs even if asset loading fails
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Ice Flow',
      'dashboard': 'Dashboard',
      'bills': 'Bills',
      'schedule': 'Schedule',
      'customers': 'Customers',
      'reports': 'Reports',
      'statistics': 'Statistics',
      'settings': 'Settings',
      'help': 'Help',
      'logout': 'Logout',
      'greeting': 'Good Morning, Ahmad',
      'overview_subtitle': "Here is today's overview.",
      'revenue': "Today's Revenue",
      'ice_sold': 'Ice Sold Today',
      'trips': "Today's Trips",
      'outstanding_balance': 'Outstanding Balance',
      'inventory_tracking': 'Inventory Tracking',
      'loaded': 'Loaded',
      'sold': 'Sold',
      'remaining': 'Remaining',
      'sales_7_days': 'Sales Last 7 Days',
      'recent_activity': 'Recent Activity',
      'view_all': 'View All',
      'completed': 'Completed',
      'pending': 'Pending',
      'in_progress': 'In Progress',
      'unpaid': 'Unpaid',
      'paid': 'Paid',
      'partial': 'Partial',
      'create_invoice': 'Create Invoice',
      'select_customer': 'Select Customer',
      'search_customer': 'Search customer name or ID...',
      'ice_products': 'Ice Products',
      'payment_details': 'Payment Details',
      'subtotal': 'Subtotal',
      'tax': 'Tax (5%)',
      'total': 'Total',
      'notes': 'Notes (Optional)',
      'generate_invoice_qr': 'Generate Invoice & QR',
      'date_range': 'Date Range',
      'start_date': 'START DATE',
      'end_date': 'END DATE',
      'format': 'Format',
      'generate_report': 'Generate Report',
      'recent_exports': 'Recent Exports'
    },
    'ar': {
      'app_title': 'أيس فلو',
      'dashboard': 'لوحة التحكم',
      'bills': 'الفواتير',
      'schedule': 'الجدول اليومي',
      'customers': 'الزبائن',
      'reports': 'التقارير',
      'statistics': 'الإحصائيات',
      'settings': 'الإعدادات',
      'help': 'المساعدة',
      'logout': 'تسجيل الخروج',
      'greeting': 'صباح الخير، أحمد',
      'overview_subtitle': 'إليك نظرة عامة على اليوم.',
      'revenue': 'إيرادات اليوم',
      'ice_sold': 'مبيعات الثلج اليوم',
      'trips': 'رحلات اليوم',
      'outstanding_balance': 'الرصيد المستحق',
      'inventory_tracking': 'تتبع المخزون',
      'loaded': 'المحمل',
      'sold': 'المباع',
      'remaining': 'المتبقي',
      'sales_7_days': 'المبيعات في آخر ٧ أيام',
      'recent_activity': 'النشاط الأخير',
      'view_all': 'عرض الكل',
      'completed': 'مكتمل',
      'pending': 'معلق',
      'in_progress': 'قيد التنفيذ',
      'unpaid': 'غير مدفوع',
      'paid': 'مدفوع',
      'partial': 'جزئي',
      'create_invoice': 'إنشاء فاتورة',
      'select_customer': 'اختر زبوناً',
      'search_customer': 'ابحث عن اسم الزبون أو رقم المعرف...',
      'ice_products': 'منتجات الثلج',
      'payment_details': 'تفاصيل الدفع',
      'subtotal': 'المجموع الفرعي',
      'tax': 'الضريبة (٥٪)',
      'total': 'المجموع الكلي',
      'notes': 'ملاحظات (اختياري)',
      'generate_invoice_qr': 'توليد الفاتورة والرمز QR',
      'date_range': 'النطاق الزمني',
      'start_date': 'تاريخ البدء',
      'end_date': 'تاريخ الانتهاء',
      'format': 'الصيغة',
      'generate_report': 'توليد التقرير',
      'recent_exports': 'الملفات المصدرة مؤخراً'
    }
  };

  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString('assets/translations/${locale.languageCode}.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      // Fallback to static maps
      _localizedStrings = _localizedValues[locale.languageCode] ?? _localizedValues['en']!;
    }
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  bool get isRTL => locale.languageCode == 'ar';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

// Global Extension to make translations easier in UI
extension TranslationExtension on BuildContext {
  String translate(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }
  
  bool get isRTL => AppLocalizations.of(this)?.isRTL ?? false;
}
