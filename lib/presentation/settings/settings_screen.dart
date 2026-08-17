import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/onboarding/app_state_cubit.dart';
import '../../application/settings/settings_cubit.dart';
import '../../application/settings/settings_state.dart';
import '../onboarding/localization/localization_provider.dart';
import '../onboarding/widgets/change_language_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  void _showComingSoonDialog(BuildContext context, String titleKey) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr(titleKey)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.construction,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('coming_soon'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('coming_soon_desc'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLang = context.watch<AppStateCubit>().state.languageCode;

    String currentLangName = context.tr('lang_english');
    if (currentLang == 'si') {
      currentLangName = context.tr('lang_sinhala');
    } else if (currentLang == 'ta') {
      currentLangName = context.tr('lang_tamil');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings_title')),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              // Language section
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  key: const Key('settings_language_row'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.language, color: theme.colorScheme.primary),
                  ),
                  title: Text(
                    context.tr('section_language'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(currentLangName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ChangeLanguageDialog.show(context),
                ),
              ),

              // Accessibility section
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  key: const Key('settings_accessibility_row'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(Icons.accessibility_new,
                        color: theme.colorScheme.secondary),
                  ),
                  title: Text(
                    context.tr('section_accessibility'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(context.tr('coming_soon')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoonDialog(
                    context,
                    'section_accessibility',
                  ),
                ),
              ),

              // Notifications section
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  key: const Key('settings_notifications_row'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    child: Icon(Icons.notifications_none,
                        color: theme.colorScheme.tertiary),
                  ),
                  title: Text(
                    context.tr('section_notifications'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(context.tr('coming_soon')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoonDialog(
                    context,
                    'section_notifications',
                  ),
                ),
              ),

              // Offline Data section
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  key: const Key('settings_offline_data_row'),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.cloud_off,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  title: Text(
                    context.tr('section_offline_data'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(context.tr('coming_soon')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoonDialog(
                    context,
                    'section_offline_data',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
