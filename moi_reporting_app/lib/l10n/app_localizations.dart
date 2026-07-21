import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'MoI Reporting System',
      'language': 'English',
      'toggleLanguage': 'Switch Language',
      'arabic': 'العربية',
      'english': 'English',
      
      // Login Screen
      'welcomeBack': 'Welcome Back',
      'signInSub': 'Sign in to your MoI account',
      'citizen': 'Citizen',
      'officer': 'Officer',
      'nationalId': 'National ID Number',
      'password': 'Password',
      'login': 'Login',
      'noAccountRegister': "Don't have an account? Register here",
      'pleaseEnterNationalId': 'Please enter National ID',
      'pleaseEnterPassword': 'Please enter password',
      'loginFailed': 'Login failed: {error}',

      // Register Screen
      'register': 'Register',
      'createAccount': 'Create Account',
      'joinCommunity': 'Join the community reporting system',
      'email': 'Email',
      'phoneOptional': 'Phone Number (Optional)',
      'passwordTooShort': 'Password too short',
      'pleaseEnterEmail': 'Please enter email',
      'registrationSuccess': 'Registration successful! Please login.',
      'registrationFailed': 'Registration failed: {error}',

      // Main Navigation / Citizen Dashboard
      'home': 'Home',
      'report': 'Report',
      'history': 'History',
      'profile': 'Profile',
      'dashboard': 'Dashboard',
      'welcomeBackUser': 'Welcome back,',
      'quickStats': 'Quick Stats',
      'active': 'Active',
      'resolved': 'Resolved',
      'total': 'Total',
      'quickActions': 'Quick Actions',
      'fileNewReport': 'File a New Report',
      'viewGuidelines': 'View Guidelines',
      'guidelinesSoon': 'Guidelines coming soon!',
      'refresh': 'Refresh',

      // Profile Screen
      'citizenAccount': 'Citizen Account',
      'accountSettings': 'Account Settings',
      'helpSupport': 'Help & Support',
      'logout': 'Logout',
      'settingsSoon': 'Settings coming soon!',
      'helpSoon': 'Help & Support coming soon!',

      // Report Form Screen
      'newReport': 'New Report',
      'submitIncident': 'Submit an Incident',
      'enterDetailsSub': 'Enter details below to report an issue to the MoI.',
      'title': 'Title',
      'category': 'Category',
      'description': 'Description',
      'pleaseEnterTitle': 'Please enter a title',
      'titleMinChars': 'Title must be at least 3 characters',
      'pleaseEnterDesc': 'Please enter a description',
      'descMinChars': 'Description must be at least 10 characters',
      'recordDescription': 'Record Description',
      'stopRecording': 'Stop Recording',
      'transcribing': 'Transcribing voice...',
      'voiceTranscribedSuccess': 'Voice transcribed successfully',
      'useCurrentLocation': 'Use Current Location',
      'pressToFetchLocation': 'Press button to fetch location',
      'manualLocation': 'Manual Location',
      'enterCityOrAddress': 'Enter city or address',
      'addMoreFiles': 'Add More Files',
      'submitReport': 'Submit Report',
      'reportSubmittedSuccess': 'Report submitted successfully!',
      'maxFilesAllowed': 'Maximum 5 files allowed',
      'fileTooLarge': 'File is too large. Max size: 10MB',
      'fetchLocationFirst': 'Please fetch current location first',

      // Categories
      'cat_environmental': 'Environmental',
      'cat_infrastructure': 'Infrastructure',
      'cat_utilities': 'Utilities',
      'cat_crime': 'Crime',
      'cat_traffic': 'Traffic',
      'cat_public_nuisance': 'Public Nuisance',
      'cat_other': 'Other',

      // Report History Screen
      'myReports': 'My Reports',
      'errorLoadingReports': 'Error loading reports',
      'noReportsFound': 'No reports found.',

      // Officer Dashboard & Map
      'officerDashboard': 'Officer Dashboard',
      'greetingsOfficer': 'Greetings, Officer',
      'liveStatistics': 'Live Statistics',
      'submitted': 'Submitted',
      'execution': 'Execution',
      'nearbyReports': 'Nearby Reports',
      'noNearbyReports': 'No nearby reports found in your active service area.',
      'viewReportsMap': 'View Reports on Map',
      'incidentMap': 'Incident Map',
      'viewFullDetails': 'View Full Details',
      'locationServicesDisabled': 'Location services are disabled. Please enable them.',
      'locationPermissionDenied': 'Location permission is required',
      'locationPermissionPermanentlyDenied': 'Location permission is permanently denied. Please enable it in app settings.',
      'errorFetchingLocation': 'Error fetching location',
      'fetchingLocation': 'Fetching location...',
      'zone': 'Zone',
      'waitForLocation': 'Wait for location to be fetched...',

      // Officer Report Details Screen
      'reportDetailsTitle': 'Report Details',
      'reportNotFound': 'Report not found.',
      'location': 'Location',
      'locationUnknown': 'Location unknown',
      'couldNotOpenMaps': 'Could not open maps',
      'evidence': 'Evidence',
      'noEvidence': 'No evidence attached to this report.',
      'updateStatus': 'Update Status',
      'officerNotesHint': 'Write officer notes here...',
      'submitUpdate': 'Submit Update',
      'statusUpdatedSuccess': 'Status updated successfully!',
      'failedToLoadReport': 'Failed to load report',
      'updateFailed': 'Update failed',
      'attachment': 'Attachment',
      'of': 'of',
      'officerNotes': "Officer's Notes",
      'noOfficerNotesYet': 'No officer notes added yet.',
      'updated': 'Updated',

      // Statuses
      'status_submitted': 'Submitted',
      'status_inprogress': 'InProgress',
      'status_resolved': 'Resolved',
      'status_rejected': 'Rejected',
    },
    'ar': {
      'appTitle': 'نظام بلاغات وزارة الداخلية',
      'language': 'العربية',
      'toggleLanguage': 'تغيير اللغة',
      'arabic': 'العربية',
      'english': 'English',

      // Login Screen
      'welcomeBack': 'مرحباً بك مجدداً',
      'signInSub': 'تسجيل الدخول إلى حسابك في وزارة الداخلية',
      'citizen': 'مواطن',
      'officer': 'ضابط',
      'nationalId': 'رقم الهوية الوطنية',
      'password': 'كلمة المرور',
      'login': 'تسجيل الدخول',
      'noAccountRegister': 'ليس لديك حساب؟ سجل هنا',
      'pleaseEnterNationalId': 'الرجاء إدخال رقم الهوية الوطنية',
      'pleaseEnterPassword': 'الرجاء إدخال كلمة المرور',
      'loginFailed': 'فشل تسجيل الدخول: {error}',

      // Register Screen
      'register': 'إنشاء حساب',
      'createAccount': 'إنشاء حساب جديد',
      'joinCommunity': 'انضم إلى نظام بلاغات المجتمع',
      'email': 'البريد الإلكتروني',
      'phoneOptional': 'رقم الهاتف (اختياري)',
      'passwordTooShort': 'كلمة المرور قصيرة جداً',
      'pleaseEnterEmail': 'الرجاء إدخال البريد الإلكتروني',
      'registrationSuccess': 'تم التسجيل بنجاح! يرجى تسجيل الدخول.',
      'registrationFailed': 'فشل التسجيل: {error}',

      // Main Navigation / Citizen Dashboard
      'home': 'الرئيسية',
      'report': 'إبلاغ',
      'history': 'السجل',
      'profile': 'الملف الشخصي',
      'dashboard': 'لوحة التحكم',
      'welcomeBackUser': 'مرحباً بك،',
      'quickStats': 'إحصائيات سريعة',
      'active': 'نشط',
      'resolved': 'تم الحل',
      'total': 'الإجمالي',
      'quickActions': 'إجراءات سريعة',
      'fileNewReport': 'تقديم بلاغ جديد',
      'viewGuidelines': 'عرض الإرشادات',
      'guidelinesSoon': 'الإرشادات قريباً!',
      'refresh': 'تحديث',

      // Profile Screen
      'citizenAccount': 'حساب مواطن',
      'accountSettings': 'إعدادات الحساب',
      'helpSupport': 'الدعم والمساعدة',
      'logout': 'تسجيل الخروج',
      'settingsSoon': 'الإعدادات قريباً!',
      'helpSoon': 'المساعدة والدعم قريباً!',

      // Report Form Screen
      'newReport': 'بلاغ جديد',
      'submitIncident': 'تقديم بلاغ',
      'enterDetailsSub': 'أدخل التفاصيل أدناه للإبلاغ عن مشكلة لوزارة الداخلية.',
      'title': 'العنوان',
      'category': 'الفئة',
      'description': 'الوصف',
      'pleaseEnterTitle': 'الرجاء إدخال عنوان البلاغ',
      'titleMinChars': 'يجب أن يكون العنوان 3 أحرف على الأقل',
      'pleaseEnterDesc': 'الرجاء إدخال وصف البلاغ',
      'descMinChars': 'يجب أن يكون الوصف 10 أحرف على الأقل',
      'recordDescription': 'تسجيل الوصف صوتاً',
      'stopRecording': 'إيقاف التسجيل',
      'transcribing': 'جاري تحويل الصوت إلى نص...',
      'voiceTranscribedSuccess': 'تم تحويل الصوت إلى نص بنجاح',
      'useCurrentLocation': 'استخدام الموقع الحالي',
      'pressToFetchLocation': 'اضغط على الزر لجلب الموقع',
      'manualLocation': 'الموقع اليدوي',
      'enterCityOrAddress': 'أدخل المدينة أو العنوان',
      'addMoreFiles': 'إضافة المزيد من الملفات',
      'submitReport': 'إرسال البلاغ',
      'reportSubmittedSuccess': 'تم إرسال البلاغ بنجاح!',
      'maxFilesAllowed': 'الحد الأقصى 5 ملفات فقط',
      'fileTooLarge': 'الملف كبير جداً. الحد الأقصى: 10 ميجابايت',
      'fetchLocationFirst': 'يرجى جلب الموقع الحالي أولاً',

      // Categories
      'cat_environmental': 'بيئي',
      'cat_infrastructure': 'بنية تحتية',
      'cat_utilities': 'مرافق عامة',
      'cat_crime': 'جريمة',
      'cat_traffic': 'مرور',
      'cat_public_nuisance': 'إزعاج عام',
      'cat_other': 'أخرى',

      // Report History Screen
      'myReports': 'بلاغاتي',
      'errorLoadingReports': 'خطأ في تحميل البلاغات',
      'noReportsFound': 'لم يتم العثور على بلاغات.',

      // Officer Dashboard & Map
      'officerDashboard': 'لوحة تحكم الضابط',
      'greetingsOfficer': 'تحياتنا، سيادة الضابط',
      'liveStatistics': 'الإحصائيات المباشرة',
      'submitted': 'تم التقديم',
      'execution': 'قيد التنفيذ',
      'nearbyReports': 'البلاغات القريبة',
      'noNearbyReports': 'لا توجد بلاغات قريبة في منطقة خدمتك النشطة.',
      'viewReportsMap': 'عرض البلاغات على الخريطة',
      'incidentMap': 'خريطة الحوادث',
      'viewFullDetails': 'عرض التفاصيل الكاملة',
      'locationServicesDisabled': 'خدمات الموقع معطلة. يرجى تفعيلها.',
      'locationPermissionDenied': 'إذن الوصول للموقع مطلوب',
      'locationPermissionPermanentlyDenied': 'إذن الموقع معطل بشكل دائم. يرجى تفعيله من إعدادات التطبيق.',
      'errorFetchingLocation': 'خطأ في جلب الموقع',
      'fetchingLocation': 'جاري جلب الموقع...',
      'zone': 'المنطقة',
      'waitForLocation': 'انتظر لحين جلب الموقع...',

      // Officer Report Details Screen
      'reportDetailsTitle': 'تفاصيل البلاغ',
      'reportNotFound': 'لم يتم العثور على البلاغ.',
      'location': 'الموقع',
      'locationUnknown': 'الموقع غير معروف',
      'couldNotOpenMaps': 'تعذر فتح الخرائط',
      'evidence': 'الأدلة والمرفقات',
      'noEvidence': 'لا توجد أدلة مرفقة بهذا البلاغ.',
      'updateStatus': 'تحديث الحالة',
      'officerNotesHint': 'اكتب ملاحظات الضابط هنا...',
      'submitUpdate': 'إرسال التحديث',
      'statusUpdatedSuccess': 'تم تحديث الحالة بنجاح!',
      'failedToLoadReport': 'فشل في تحميل البلاغ',
      'updateFailed': 'فشل التحديث',
      'attachment': 'مرفق',
      'of': 'من',
      'officerNotes': 'ملاحظات الضابط',
      'noOfficerNotesYet': 'لم يقم الضابط بإضافة ملاحظات بعد.',
      'updated': 'تم التحديث',

      // Statuses
      'status_submitted': 'تم التقديم',
      'status_inprogress': 'قيد التنفيذ',
      'status_resolved': 'تم الحل',
      'status_rejected': 'مرفوض',
    },
  };

  String translate(String key, {Map<String, String>? params}) {
    String value = _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue);
      });
    }
    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
