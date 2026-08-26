// lib/presentation/settings/terms_privacy_screen.dart
//
// Terms of Service and Privacy Policy.
//
// What was wrong:
//
//  * Each tab carried an icon *and* a label. That makes the tab bar 72dp tall
//    and, more importantly, squeezes the label — and the labels are long:
//    "Privacy Policy" is "පෞද්ගලිකත්ව ප්‍රතිපත්තිය" in Sinhala and
//    "தனியுரிமைக் கொள்கை" in Tamil. Two fixed-width tabs could not fit them,
//    so they clipped. The icons carried no information the words did not, so
//    they are gone and the tabs are scrollable.
//  * The screen was un-tokenised: raw `Card`, `colorScheme.*`, `withAlpha`,
//    and hardcoded radii. `withAlpha(50)` behind a coloured heading is exactly
//    the translucent-behind-text case the design rules forbid, because the
//    resulting contrast ratio is unpredictable outdoors.
//  * `initialTabIndex` worked from the auth screen but Settings always pushed
//    index 0, so "Privacy Policy" could not be opened directly from the one
//    place a user goes looking for it.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../onboarding/localization/localization_provider.dart';
import '../shared/widgets/app_components.dart';

class TermsPrivacyScreen extends StatelessWidget {
  final int initialTabIndex;

  const TermsPrivacyScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('terms_privacy_title')),
          elevation: 0,
          bottom: TabBar(
            // Scrollable so a long Sinhala or Tamil label can take the width
            // it needs instead of being squeezed into half the screen.
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: context.tr('terms_tab')),
              Tab(text: context.tr('privacy_tab')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LegalTab(
              icon: Icons.gavel_rounded,
              titleKey: 'terms_content_title',
              bodyKey: 'terms_content_body',
            ),
            _LegalTab(
              icon: Icons.shield_outlined,
              titleKey: 'privacy_content_title',
              bodyKey: 'privacy_content_body',
            ),
          ],
        ),
      ),
    );
  }
}

/// One legal document: a heading, then the text.
///
/// Both tabs were near-identical 50-line blocks differing only in an icon and
/// two keys.
class _LegalTab extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String bodyKey;

  const _LegalTab({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: AppSpacing.smPlus),
            Expanded(
              child: Text(
                context.tr(titleKey),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Text(
            context.tr(bodyKey),
            // Legal text is dense and read slowly; the extra line height is
            // the one place in the app it earns its space.
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
