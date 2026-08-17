class AppLocalizations {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'CropCare',
      'splash_subtitle': 'Smart Crop Health Companion',
      'onboarding_title_1': 'Spot the problem',
      'onboarding_desc_1':
          'Take photos of diseased leaves or stems to detect crop issues early.',
      'onboarding_title_2': 'Get understandable guidance',
      'onboarding_desc_2':
          'Receive clear, actionable treatment instructions in your preferred language.',
      'onboarding_title_3': 'Get expert help when AI isn\'t confident',
      'onboarding_desc_3':
          'Connect with agricultural experts whenever automated diagnosis needs verification.',
      'skip': 'Skip',
      'next': 'Next',
      'get_started': 'Get Started',
      'select_language_title': 'Select Your Language',
      'select_language_subtitle': 'Choose your preferred language for CropCare',
      'lang_english': 'English',
      'lang_sinhala': 'සිංහල (Sinhala)',
      'lang_tamil': 'தமிழ் (Tamil)',
      'confirm': 'Confirm',
      'home_title': 'CropCare Home',
      'home_welcome': 'Welcome to CropCare!',
      'change_language': 'Change Language',
    },
    'si': {
      'app_title': 'CropCare',
      'splash_subtitle': 'ස්මාර්ට් බෝග සෞඛ්‍ය සහකාර',
      'onboarding_title_1': 'ගැටලුව හඳුනාගන්න',
      'onboarding_desc_1':
          'බෝග වල රෝග කල්තියා හඳුනා ගැනීමට ඡායාරූප ලබා ගන්න.',
      'onboarding_title_2': 'පැහැදිලි උපදෙස් ලබාගන්න',
      'onboarding_desc_2':
          'ඔබගේ භාෂාවෙන් පැහැදිලි ප්‍රතිකාර උපදෙස් ලබා ගන්න.',
      'onboarding_title_3': 'විශේෂඥ සහාය ලබාගන්න',
      'onboarding_desc_3':
          'AI පද්ධතියට විශ්වාස නැති විට කෘෂිකාර්මික විශේෂඥයින්ගේ සහාය ලබා ගන්න.',
      'skip': 'මගහරින්න',
      'next': 'ඊළඟ',
      'get_started': 'ආරම්භ කරන්න',
      'select_language_title': 'ඔබේ භාෂාව තෝරන්න',
      'select_language_subtitle': 'CropCare සඳහා ඔබ කැමති භාෂාව තෝරන්න',
      'lang_english': 'English',
      'lang_sinhala': 'සිංහල',
      'lang_tamil': 'தமிழ்',
      'confirm': 'තහවුරු කරන්න',
      'home_title': 'CropCare මුල් පිටුව',
      'home_welcome': 'CropCare වෙත සාදරයෙන් පිළිගනිමු!',
      'change_language': 'භාෂාව වෙනස් කරන්න',
    },
    'ta': {
      'app_title': 'CropCare',
      'splash_subtitle': 'ஸ்மார்ட் பயிர் சுகாதார உதவியாளர்',
      'onboarding_title_1': 'பிரச்சனையைக் கண்டறியவும்',
      'onboarding_desc_1':
          'பயிர் நோய்களை முன்கூட்டியே கண்டறிய புகைப்படங்களை எடுக்கவும்.',
      'onboarding_title_2': 'தெளிவான வழிகாட்டுதலைப் பெறுக',
      'onboarding_desc_2':
          'உங்கள் மொழியில் தெளிவான சிகிச்சை வழிமுறைகளைப் பெறுங்கள்.',
      'onboarding_title_3': 'நிபுணர் உதவியைப் பெறுங்கள்',
      'onboarding_desc_3':
          'AI பலவீனமாக இருக்கும் போது விவசாய நிபுணர்களின் உதவியைப் பெறுங்கள்.',
      'skip': 'தவிர்',
      'next': 'அடுத்து',
      'get_started': 'தொடங்கவும்',
      'select_language_title': 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்',
      'select_language_subtitle':
          'CropCare க்கான உங்கள் விருப்பமான மொழியைத் தேர்ந்தெடுக்கவும்',
      'lang_english': 'English',
      'lang_sinhala': 'සිංහල',
      'lang_tamil': 'தமிழ்',
      'confirm': 'உறுதிப்படுத்து',
      'home_title': 'CropCare முகப்பு',
      'home_welcome': 'CropCare க்கு நல்வரவு!',
      'change_language': 'மொழியை மாற்றவும்',
    },
  };

  static String get(String key, String languageCode) {
    final map = _localizedValues[languageCode] ?? _localizedValues['en']!;
    return map[key] ?? _localizedValues['en']![key] ?? key;
  }
}
