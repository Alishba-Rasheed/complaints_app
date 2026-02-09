import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString('lib/l10n/app_${locale.languageCode}.arb');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Common strings
  String get appTitle => translate('appTitle');
  String get welcomeBack => translate('welcomeBack');
  String get signInToPortal => translate('signInToPortal');
  String get username => translate('username');
  String get password => translate('password');
  String get continueBtn => translate('continueBtn');
  String get dontHaveAccount => translate('dontHaveAccount');
  String get registerNow => translate('registerNow');
  String get selectPortal => translate('selectPortal');
  String get user => translate('user');
  String get admin => translate('admin');
  String get superAdmin => translate('superAdmin');
  String get loginFailed => translate('loginFailed');

  // Home screen
  String get complaintHub => translate('complaintHub');
  String get home => translate('home');
  String get complaints => translate('complaints');
  String get chat => translate('chat');
  String get profile => translate('profile');
  String get quickActions => translate('quickActions');
  String get fileComplaint => translate('fileComplaint');
  String get directReporting => translate('directReporting');
  String get chatWithAdmin => translate('chatWithAdmin');
  String get connectSupport => translate('connectSupport');
  String get officialAnnouncements => translate('officialAnnouncements');
  String get viewAll => translate('viewAll');
  String get noAnnouncements => translate('noAnnouncements');
  String get supportCenter => translate('supportCenter');
  String get active247 => translate('active247');
  String get faqHelp => translate('faqHelp');
  String get contactSupport => translate('contactSupport');
  String get supportLinkNotSet => translate('supportLinkNotSet');
  String get couldNotOpenLink => translate('couldNotOpenLink');
  String get invalidLinkFormat => translate('invalidLinkFormat');
  String get welcomeBackUser => translate('welcomeBackUser');
  String get guestUser => translate('guestUser');
  String get applied => translate('applied');
  String get apply => translate('apply');
  String get open => translate('open');

  // Registration
  String get createAccount => translate('createAccount');
  String get registerToPortal => translate('registerToPortal');
  String get fullName => translate('fullName');
  String get email => translate('email');
  String get confirmPassword => translate('confirmPassword');
  String get register => translate('register');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');
  String get loginNow => translate('loginNow');

  // Complaints
  String get myComplaints => translate('myComplaints');
  String get submitComplaint => translate('submitComplaint');
  String get complaintTitle => translate('complaintTitle');
  String get description => translate('description');
  String get category => translate('category');
  String get submit => translate('submit');
  String get pending => translate('pending');
  String get inProgress => translate('inProgress');
  String get resolved => translate('resolved');
  String get rejected => translate('rejected');

  // Super dashboard
  String get systemControl => translate('systemControl');
  String get systemLive => translate('systemLive');
  String get globalCommandCenter => translate('globalCommandCenter');
  String get orchestrating => translate('orchestrating');
  String get issues => translate('issues');
  String get scope => translate('scope');
  String get fixed => translate('fixed');
  String get globalActivity => translate('globalActivity');
  String get noActivityRecorded => translate('noActivityRecorded');

  // Navigation
  String get categories => translate('categories');
  String get admins => translate('admins');
  String get allActivity => translate('allActivity');
  String get announcements => translate('announcements');
  String get settings => translate('settings');

  // Common actions
  String get logout => translate('logout');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get noData => translate('noData');

  // Language
  String get language => translate('language');
  String get english => translate('english');
  String get urdu => translate('urdu');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ur'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}