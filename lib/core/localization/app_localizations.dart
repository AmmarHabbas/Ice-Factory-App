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
      'recent_exports': 'Recent Exports',
      'new_trip': 'New Trip',
      'pick_date': 'Pick Date',
      'no_delivery_trips_found':
          'No delivery trips found for {date}. Tap "+ New Trip" to schedule one.',
      'driver_label': 'Driver: {driverName}',
      'stops_summary': 'Stops: {completed} / {total} completed',
      'destination_location': 'DESTINATION / LOCATION',
      'destination_hint': 'e.g. Al Safa Supermarket / King Fahd Rd',
      'driver_truck_fleet': 'DRIVER / TRUCK FLEET',
      'driver_name_or_truck': 'Driver name or Truck #',
      'time_label': 'TIME',
      'date_label': 'DATE',
      'ice_load_kg': 'ICE LOAD (KG)',
      'initial_status': 'INITIAL STATUS',
      'create_trip': 'Create Trip',
      'trip_details': 'Trip Details',
      'trip_id': 'ID: {id}',
      'status_label': 'STATUS',
      'save_changes': 'Save Changes',
      'valid_ice_quantity': 'Please enter a valid ice quantity in kg',
      'edit_inventory_entry': 'Edit Inventory Entry',
      'delete_inventory_entry': 'Delete Inventory Entry?',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'ice_inventory': 'Ice Inventory',
      'error_loading_inventory': 'Error loading inventory',
      'add_ice': 'Add Ice',
      'yesterday': 'Yesterday',
      'today': 'Today',
      'choose_date': 'Choose Date',
      'add_inventory': 'Add Inventory',
      'update_total_available_ice_for': 'Update total available ice for {date}',
      'enter_amount_placeholder': 'Enter amount (e.g. 100)',
      'kg': 'kg',
      'available_ice_stock': 'Available Ice Stock',
      'total_added': 'Total Added',
      'total_sold': 'Total Sold',
      'inventory_status': 'Inventory Status',
      'sold': 'Sold',
      'recent_adjustments': 'Recent Adjustments',
      'no_adjustments_logged': 'No adjustments logged for this date.',
      'manage_inventory_entry': 'Manage inventory entry',
      'added_ice_to_date': 'Added {amount} kg ice to {date}',
      'failed_add_ice': 'Failed to add ice',
      'add': 'Add',
      'remove': 'Remove',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'range': 'Range',
      'performance_metrics': 'Performance Metrics',
      'top_customers_chart': 'Top Customers Chart',
      'ranked_by_orders': 'Ranked by Orders',
      'customers_ranked_desc':
          'Customers ranked descending by total completed and recorded invoices.',
      'no_customer_orders_recorded': 'No customer orders recorded yet.',
      'orders': 'orders',
      'error_loading_stats': 'Error loading stats: {error}',
      'today_daily': 'Today (Daily)',
      'this_week_sat_fri': 'This Week (Sat-Fri)',
      'this_month': 'This Month',
      'this_year': 'This Year',
      'error_loading_reports': 'Error loading reports: {error}',
      'revenue_by_customer': 'Revenue by Customer',
      'no_bills_recorded_for_period': 'No bills recorded for selected period.',
      'custom_bill_expenses': 'Custom Bill Expenses',
      'no_custom_bills_recorded_for_period':
          'No custom bills recorded for selected period.',
      'worker_salary_costs': 'Worker Salary Costs',
      'net_profit_after_staff': 'Net Profit (After Staff)',
      'salary_paid': 'Salary Paid',
      'loan_advances': 'Loan Advances',
      'salary_disbursements_and_loans':
          'Salary disbursements & loan advances in period',
      'no_worker_payments': 'No worker payments in selected period.',
      'search_by_name_or_role': 'Search by name or role...',
      'active_shown': '{count} Active Shown',
      'loans': 'Loans',
      'factory_workforce': 'Factory Workforce',
      'no_workers_found': 'No workers found',
      'payment_recorded_for': 'Payment recorded for {name}',
      'remove_worker_confirmation': 'Are you sure you want to remove {name}?',
      'amount_syp': 'Amount (SYP)',
      'onboarding_checklist': 'Onboarding Checklist',
      'three_of_four_required': '3 of 4 Required',
      'fill_identity_credentials':
          'Fill identity credentials, role, shift, and salary.',
      'worker_identity': 'Worker Identity',
      'legal_factory_identification_data':
          'Legal & factory identification data',
      'primary_role': 'Primary Role',
      'factory_operational_station': 'Factory operational station',
      'required': 'Required',
      'assigned_shift': 'Assigned Shift',
      'production_line_schedule_blocks': 'Production line schedule blocks',
      'compensation': 'Compensation',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'contact_phone': 'Contact Phone',
      'morning_shift_title': 'Morning Shift',
      'afternoon_shift_title': 'Afternoon Shift',
      'night_shift_title': 'Night Shift',
      'registration_successful': 'Registration Successful',
      'worker_profile_initialized': 'Worker profile initialized.',
      'registering_worker': 'Registering Worker...',
      'worker_saved': 'Worker Saved',
      'save_and_register_worker': 'Save & Register Worker',
      'no_loans': 'No outstanding loans',
      'zero_dues': 'Zero Dues',
      'salary': 'Salary',
      'loan_advance': 'Loan Advance',
      'loan_repayment': 'Loan Repayment',
      'all_around_worker': 'All Around Worker',
      'factory_worker': 'Factory Worker',
      'morning_shift': 'Morning Shift',
      'afternoon_shift': 'Afternoon Shift',
      'night_shift': 'Night Shift',
      'workers': 'Workers',
      'add_worker': 'Add Worker',
      'pay': 'Pay',
      'remove_worker': 'Remove Worker',
      'no_customer_selected': 'No Customer Selected',
      'commercial_district': 'Commercial District',
      'owner_prefix': 'Owner:',
      'outstanding_label': 'OUTSTANDING',
      'total_volume_label': 'TOTAL VOLUME',
      'zero_orders': '0 Orders',
      'order_singular': 'Order',
      'order_plural': 'Orders',
      'kg_total': 'kg total',
      'last_delivery_label': 'LAST DELIVERY',
      'route_active': 'Route 1 (Active)',
      'create_new_invoice': 'Create New Invoice',
      'customer_tab_history': 'History',
      'customer_tab_payments': 'Payments',
      'customer_tab_notes': 'Notes',
      'no_invoice_history_found': 'No invoice history found for this customer.',
      'view_bill': 'View Bill',
      'payment_summary': 'Payment Summary',
      'payment_on': 'Payment on {id}',
      'customer_notes_information': 'Customer Notes & Information',
      'delivery_guidelines': 'Delivery Guidelines:',
      'delivery_guidelines_text':
          'Standard commercial ice delivery. Morning preferred between 08:00 AM and 11:00 AM.',
      '1_kg_ice_bag': '1 kg Ice Bag',
      '5_kgs_ice_bundle': '5 kgs Ice Bundle',
      '5kgs_ice_bag': '5 kgs Ice Bag',
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
      'recent_exports': 'الملفات المصدرة مؤخراً',
      'new_trip': 'رحلة جديدة',
      'pick_date': 'اختر تاريخ',
      'no_delivery_trips_found':
          'لا توجد رحلات توصيل لـ {date}. اضغط "+ رحلة جديدة" لجدولة واحدة.',
      'driver_label': 'السائق: {driverName}',
      'stops_summary': 'المحطات: {completed} / {total} مكتملة',
      'destination_location': 'الوجهة / الموقع',
      'destination_hint': 'مثال: سوبر ماركت الصفاء / شارع الملك فهد',
      'driver_truck_fleet': 'السائق / أسطول الشاحنات',
      'driver_name_or_truck': 'اسم السائق أو رقم الشاحنة',
      'time_label': 'الوقت',
      'date_label': 'التاريخ',
      'ice_load_kg': 'حمولة الثلج (كجم)',
      'initial_status': 'الحالة الأولية',
      'create_trip': 'إنشاء رحلة',
      'trip_details': 'تفاصيل الرحلة',
      'trip_id': 'المعرف: {id}',
      'status_label': 'الحالة',
      'save_changes': 'حفظ التغييرات',
      'valid_ice_quantity': 'أدخل كمية ثلج صحيحة بالكيلوغرام',
      'edit_inventory_entry': 'تعديل إدخال المخزون',
      'delete_inventory_entry': 'حذف إدخال المخزون؟',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'delete': 'حذف',
      'ice_inventory': 'مخزون الثلج',
      'error_loading_inventory': 'خطأ في تحميل المخزون',
      'add_ice': 'إضافة ثلج',
      'yesterday': 'أمس',
      'today': 'اليوم',
      'choose_date': 'اختر تاريخ',
      'add_inventory': 'إضافة مخزون',
      'update_total_available_ice_for': 'تحديث إجمالي الثلج المتاح لـ {date}',
      'enter_amount_placeholder': 'أدخل الكمية (مثال: 100)',
      'kg': 'كجم',
      'available_ice_stock': 'المخزون المتاح',
      'total_added': 'إجمالي المضاف',
      'total_sold': 'إجمالي المبيع',
      'inventory_status': 'حالة المخزون',
      'sold': 'مباع',
      'recent_adjustments': 'التعديلات الأخيرة',
      'no_adjustments_logged': 'لا توجد تعديلات مسجلة لهذا التاريخ.',
      'manage_inventory_entry': 'إدارة إدخال المخزون',
      'added_ice_to_date': 'تمت إضافة {amount} كجم ثلج إلى {date}',
      'failed_add_ice': 'فشلت إضافة الثلج',
      'add': 'إضافة',
      'remove': 'إزالة',
      'weekly': 'أسبوعي',
      'monthly': 'شهري',
      'yearly': 'سنوي',
      'range': 'النطاق',
      'performance_metrics': 'مؤشرات الأداء',
      'top_customers_chart': 'رسم بياني لأهم العملاء',
      'ranked_by_orders': 'مرتبة حسب الطلبات',
      'customers_ranked_desc':
          'يتم ترتيب العملاء تنازلياً حسب إجمالي الفواتير المكتملة والمسجلة.',
      'no_customer_orders_recorded': 'لا توجد طلبات عملاء مسجلة بعد.',
      'orders': 'طلبات',
      'error_loading_stats': 'خطأ في تحميل الإحصائيات: {error}',
      'today_daily': 'اليوم (يومي)',
      'this_week_sat_fri': 'هذا الأسبوع (سبت-الجمعة)',
      'this_month': 'هذا الشهر',
      'this_year': 'هذا العام',
      'error_loading_reports': 'خطأ في تحميل التقارير: {error}',
      'revenue_by_customer': 'الإيراد حسب العميل',
      'no_bills_recorded_for_period': 'لا توجد فواتير في الفترة المحددة.',
      'custom_bill_expenses': 'مصاريف الفواتير المخصصة',
      'no_custom_bills_recorded_for_period':
          'لا توجد فواتير مخصصة في الفترة المحددة.',
      'worker_salary_costs': 'تكاليف رواتب العمال',
      'net_profit_after_staff': 'صافي الربح (بعد الموظفين)',
      'salary_paid': 'الراتب المدفوع',
      'loan_advances': 'السلف',
      'salary_disbursements_and_loans': 'دفعات الرواتب والسلف خلال الفترة',
      'no_worker_payments': 'لا توجد دفعات للعمال في الفترة المحددة.',
      'search_by_name_or_role': 'ابحث بالاسم أو الدور...',
      'active_shown': '{count} عامل ظاهر',
      'loans': 'السلف',
      'factory_workforce': 'قوة العمل بالمصنع',
      'no_workers_found': 'لا يوجد عمال',
      'payment_recorded_for': 'تم تسجيل الدفعة لـ {name}',
      'remove_worker_confirmation': 'هل أنت متأكد من حذف {name}؟',
      'amount_syp': 'المبلغ (الليرة السورية)',
      'onboarding_checklist': 'قائمة الإعداد',
      'three_of_four_required': '3 من 4 مطلوب',
      'fill_identity_credentials':
          'املأ بيانات الهوية، الدور، الوردية، والراتب.',
      'worker_identity': 'هوية العامل',
      'legal_factory_identification_data':
          'بيانات الهوية القانونية ومصنع الثلج',
      'primary_role': 'الدور الأساسي',
      'factory_operational_station': 'مركز التشغيل بالمصنع',
      'required': 'مطلوب',
      'assigned_shift': 'الوردية المعينة',
      'production_line_schedule_blocks': 'فترات جدول خط الإنتاج',
      'compensation': 'التعويض',
      'first_name': 'الاسم الأول',
      'last_name': 'اسم العائلة',
      'contact_phone': 'رقم الهاتف',
      'morning_shift_title': 'ورديّة الصباح',
      'afternoon_shift_title': 'ورديّة المساء',
      'night_shift_title': 'ورديّة الليل',
      'registration_successful': 'تم التسجيل بنجاح',
      'worker_profile_initialized': 'تم تهيئة ملف العامل.',
      'registering_worker': 'جارٍ تسجيل العامل...',
      'worker_saved': 'تم حفظ العامل',
      'save_and_register_worker': 'حفظ وتسجيل العامل',
      'salary': 'الراتب',
      'loan_advance': 'سلفة',
      'loan_repayment': 'سداد سلفة',
      'all_around_worker': 'عامل عام',
      'factory_worker': 'عامل مصنع',
      'morning_shift': 'ورديّة الصباح',
      'afternoon_shift': 'ورديّة المساء',
      'night_shift': 'ورديّة الليل',
      'workers': 'العمال',
      'add_worker': 'إضافة عامل',
      'pay': 'دفع',
      'remove_worker': 'إزالة العامل',
      'no_customer_selected': 'لم يتم اختيار عميل',
      'commercial_district': 'المنطقة التجارية',
      'owner_prefix': 'المالك:',
      'outstanding_label': 'الرصيد المستحق',
      'total_volume_label': 'إجمالي الحجم',
      'zero_orders': '0 طلبات',
      'order_singular': 'طلب',
      'order_plural': 'طلبات',
      'kg_total': 'كجم إجمالي',
      'last_delivery_label': 'آخر توصيل',
      'route_active': 'المسار 1 (نشط)',
      'create_new_invoice': 'إنشاء فاتورة جديدة',
      'customer_tab_history': 'السجل',
      'customer_tab_payments': 'المدفوعات',
      'customer_tab_notes': 'ملاحظات',
      'no_invoice_history_found': 'لا توجد سجلات فواتير لهذا العميل.',
      'view_bill': 'عرض الفاتورة',
      'payment_summary': 'ملخص الدفع',
      'payment_on': 'الدفع في {id}',
      'customer_notes_information': 'ملاحظات العميل والمعلومات',
      'delivery_guidelines': 'إرشادات التوصيل:',
      'delivery_guidelines_text':
          'توصيل تجاري قياسي للثلج. يفضل الصباح بين الساعة 08:00 صباحاً و11:00 صباحاً.',
      '1_kg_ice_bag': 'كيس ثلج 1 كجم',
      '5_kgs_ice_bundle': 'باقة ثلج 5 كجم',
      '5kgs_ice_bag': 'كيس ثلج 5 كجم',
    },
  };

  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/translations/${locale.languageCode}.json',
      );
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      // Fallback to static maps
      _localizedStrings =
          _localizedValues[locale.languageCode] ?? _localizedValues['en']!;
    }
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  bool get isRTL => locale.languageCode == 'ar';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
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

class EnglishLocalizationsOverride extends StatelessWidget {
  final Widget child;

  const EnglishLocalizationsOverride({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: const Locale('en'),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );
  }
}
