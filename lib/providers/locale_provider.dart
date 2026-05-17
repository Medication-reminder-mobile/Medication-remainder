import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider();

  static const Map<String, String> _languageCodes = {
    'English': 'en',
    'Amharic': 'am',
    'Arabic': 'ar',
    'French': 'fr',
    'Spanish': 'es',
    'Portuguese': 'pt',
    'Swahili': 'sw',
  };

  static const Map<String, String> _voiceLocales = {
    'English': 'en-US',
    'Amharic': 'en-US',
    'Arabic': 'ar-SA',
    'French': 'fr-FR',
    'Spanish': 'es-ES',
    'Portuguese': 'pt-PT',
    'Swahili': 'en-US',
  };

  static const Map<String, Map<String, String>> _greetings = {
    'English': {
      'morning': 'Good morning',
      'afternoon': 'Good afternoon',
      'evening': 'Good evening',
      'generic': 'Hello',
    },
    'Amharic': {
      'morning': 'እንደምን አደርክ',
      'afternoon': 'ከቀን በኋላ ሰላም',
      'evening': 'እንደምን ማታ',
      'generic': 'ሰላም',
    },
    'Arabic': {
      'morning': 'صباح الخير',
      'afternoon': 'مساء الخير',
      'evening': 'مساء الخير',
      'generic': 'مرحبا',
    },
    'French': {
      'morning': 'Bonjour',
      'afternoon': 'Bon après-midi',
      'evening': 'Bonsoir',
      'generic': 'Salut',
    },
    'Spanish': {
      'morning': 'Buenos días',
      'afternoon': 'Buenas tardes',
      'evening': 'Buenas noches',
      'generic': 'Hola',
    },
    'Portuguese': {
      'morning': 'Bom dia',
      'afternoon': 'Boa tarde',
      'evening': 'Boa noite',
      'generic': 'Olá',
    },
    'Swahili': {
      'morning': 'Habari za asubuhi',
      'afternoon': 'Habari za mchana',
      'evening': 'Habari za jioni',
      'generic': 'Hujambo',
    },
  };

  String _currentLanguage = 'English';

  String get currentLanguage => _currentLanguage;
  Locale get locale => Locale(_languageCodes[_currentLanguage] ?? 'en');
  String get voiceLocale => _voiceLocales[_currentLanguage] ?? 'en-US';

  void setLanguage(String language) {
    if (!_languageCodes.containsKey(language)) return;
    _currentLanguage = language;
    notifyListeners();
  }

  String greeting(String name) {
    final hour = DateTime.now().hour;
    final period = hour >= 17
        ? 'evening'
        : hour >= 12
        ? 'afternoon'
        : hour >= 5
        ? 'morning'
        : 'generic';
    final localeMap = _greetings[_currentLanguage] ?? _greetings['English']!;
    final greeting = localeMap[period] ?? localeMap['generic']!;
    return '$greeting, $name';
  }
}
