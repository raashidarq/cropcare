// lib/presentation/settings/faq_screen.dart

import 'package:flutter/material.dart';

import '../onboarding/localization/localization_provider.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('faq_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Header Banner ────────────────────────────────────────────────
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withAlpha(40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.primary.withAlpha(50),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('faq_title'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('splash_subtitle'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Category 1: Scanning & Diagnosis ─────────────────────────────
          _buildCategoryHeader(
            context: context,
            title: context.tr('faq_category_scanning'),
            icon: Icons.camera_alt_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          _buildFaqItem(
            context: context,
            questionKey: 'faq_q1',
            answerKey: 'faq_a1',
            theme: theme,
          ),
          _buildFaqItem(
            context: context,
            questionKey: 'faq_q2',
            answerKey: 'faq_a2',
            theme: theme,
          ),
          _buildFaqItem(
            context: context,
            questionKey: 'faq_q3',
            answerKey: 'faq_a3',
            theme: theme,
          ),
          const SizedBox(height: 20),

          // ── Category 2: Account & Cloud Sync ──────────────────────────────
          _buildCategoryHeader(
            context: context,
            title: context.tr('faq_category_account_sync'),
            icon: Icons.cloud_sync_outlined,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          _buildFaqItem(
            context: context,
            questionKey: 'faq_q4',
            answerKey: 'faq_a4',
            theme: theme,
          ),
          _buildFaqItem(
            context: context,
            questionKey: 'faq_q5',
            answerKey: 'faq_a5',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildFaqItem({
    required BuildContext context,
    required String questionKey,
    required String answerKey,
    required ThemeData theme,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          context.tr(questionKey),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr(answerKey),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
