import 'package:flutter/material.dart';

import '../onboarding/localization/localization_provider.dart';
import '../onboarding/widgets/change_language_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('home_title')),
        actions: [
          IconButton(
            key: const Key('home_change_language_icon'),
            icon: const Icon(Icons.language),
            tooltip: context.tr('change_language'),
            onPressed: () => ChangeLanguageDialog.show(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('home_welcome'),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('home_change_language_button'),
              icon: const Icon(Icons.translate),
              label: Text(context.tr('change_language')),
              onPressed: () => ChangeLanguageDialog.show(context),
            ),
          ],
        ),
      ),
    );
  }
}
