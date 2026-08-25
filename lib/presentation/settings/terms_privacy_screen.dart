// lib/presentation/settings/terms_privacy_screen.dart

import 'package:flutter/material.dart';

import '../onboarding/localization/localization_provider.dart';

class TermsPrivacyScreen extends StatelessWidget {
  final int initialTabIndex;

  const TermsPrivacyScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('terms_privacy_title')),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.description_outlined),
                text: context.tr('terms_tab'),
              ),
              Tab(
                icon: const Icon(Icons.privacy_tip_outlined),
                text: context.tr('privacy_tab'),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTermsTab(context, theme),
            _buildPrivacyTab(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsTab(BuildContext context, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer.withAlpha(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.primary.withAlpha(60),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.gavel,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('terms_content_title'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr('terms_content_body'),
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyTab(BuildContext context, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.secondaryContainer.withAlpha(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.secondary.withAlpha(60),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: theme.colorScheme.secondary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('privacy_content_title'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr('privacy_content_body'),
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
