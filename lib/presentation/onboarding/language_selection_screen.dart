import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_text_styles.dart';

import '../../application/onboarding/app_state_cubit.dart';
import '../home/home_screen.dart';
import 'localization/localization_provider.dart';
import 'onboarding_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'en';

  /// Completes onboarding and enters the app. [openAuth] routes straight to
  /// account creation; otherwise the user lands on Home as a guest.
  Future<void> _finish(BuildContext context, {required bool openAuth}) async {
    final navigator = Navigator.of(context);
    await context.read<AppStateCubit>().completeOnboarding(_selectedLanguage);
    if (!context.mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(openAccountOnLaunch: openAuth),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final languages = [
      {'code': 'en', 'key': 'lang_english', 'widgetKey': const Key('lang_en')},
      {'code': 'si', 'key': 'lang_sinhala', 'widgetKey': const Key('lang_si')},
      {'code': 'ta', 'key': 'lang_tamil', 'widgetKey': const Key('lang_ta')},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('select_language_title')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('select_language_subtitle'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final code = lang['code'] as String;
                    final isSelected = _selectedLanguage == code;

                    return Card(
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        key: lang['widgetKey'] as Key,
                        // Each language is rendered in its OWN script's
                        // face, not the currently-active one. At this point
                        // in onboarding the user has not chosen a language
                        // yet, so the only reliable way to recognise "your
                        // language" is to see it written the way you write
                        // it — "සිංහල" in Sinhala, "தமிழ்" in Tamil.
                        title: Text(
                          context.tr(lang['key'] as String),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: AppTextStyles.fontFamilyFor(code),
                            fontFamilyFallback:
                                AppTextStyles.fontFamilyFallbackFor(code),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              )
                            : const Icon(Icons.circle_outlined),
                        onTap: () {
                          setState(() {
                            _selectedLanguage = code;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                key: const Key('confirm_language'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  // Apply the language now so the introduction that follows
                  // is already translated, but do NOT mark onboarding
                  // complete — that happens at the end of the flow.
                  await context
                      .read<AppStateCubit>()
                      .setLanguage(_selectedLanguage);
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => OnboardingScreen(
                        onCreateAccount: () => _finish(
                          context,
                          openAuth: true,
                        ),
                        onContinueAsGuest: () => _finish(
                          context,
                          openAuth: false,
                        ),
                      ),
                    ),
                  );
                },
                child: Text(context.tr('confirm')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
