// lib/presentation/settings/accessibility_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/onboarding/app_state_cubit.dart';
import '../../application/settings/accessibility_cubit.dart';
import '../../application/settings/accessibility_state.dart';
import '../../data/local/tts/text_to_speech_service.dart';
import '../onboarding/localization/localization_provider.dart';

class AccessibilityScreen extends StatefulWidget {
  final TtsService? ttsService;

  const AccessibilityScreen({
    super.key,
    this.ttsService,
  });

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  late final TtsService _ttsService;

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? TextToSpeechService();
  }

  @override
  void dispose() {
    if (widget.ttsService == null) {
      _ttsService.dispose();
    }
    super.dispose();
  }

  Widget _buildSectionHeader(BuildContext context, String titleKey) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        context.tr(titleKey).toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLang = context.watch<AppStateCubit>().state.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('accessibility_title')),
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('accessibility_reset_button'),
            icon: const Icon(Icons.restart_alt),
            tooltip: context.tr('reset_defaults'),
            onPressed: () {
              context.read<AccessibilityCubit>().resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('reset_defaults')),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AccessibilityCubit, AccessibilityState>(
        builder: (context, state) {
          final cubit = context.read<AccessibilityCubit>();
          final textScale = state.textScaleFactor;
          final isHighContrast = state.isHighContrast;
          final autoRead = state.autoReadDiagnosis;
          final speechRate = state.speechRate;
          final haptic = state.hapticFeedbackEnabled;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ── 1. Live Preview Card ─────────────────────────────────────
              _buildSectionHeader(context, 'accessibility_preview_title'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: isHighContrast ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isHighContrast ? Colors.black : theme.colorScheme.outlineVariant,
                      width: isHighContrast ? 2 : 1,
                    ),
                  ),
                  color: isHighContrast
                      ? Colors.yellow.shade50
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.eco,
                              color: isHighContrast ? Colors.green.shade900 : Colors.green.shade700,
                              size: 24 * textScale,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.tr('accessibility_sample_disease'),
                                style: TextStyle(
                                  fontSize: 16 * textScale,
                                  fontWeight: FontWeight.bold,
                                  color: isHighContrast ? Colors.black : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isHighContrast ? Colors.black : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '94%',
                                style: TextStyle(
                                  fontSize: 12 * textScale,
                                  fontWeight: FontWeight.bold,
                                  color: isHighContrast ? Colors.yellow : Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.tr('accessibility_sample_advice'),
                          style: TextStyle(
                            fontSize: 14 * textScale,
                            height: 1.4,
                            color: isHighContrast ? Colors.black87 : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 2. Display & Text ────────────────────────────────────────
              _buildSectionHeader(context, 'section_display_text'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('text_size'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(textScale * 100).toInt()}%',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<double>(
                        key: const Key('accessibility_text_size_selector'),
                        segments: [
                          ButtonSegment(
                            value: 1.0,
                            label: Text(
                              '100%',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          ButtonSegment(
                            value: 1.15,
                            label: Text(
                              '115%',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          ButtonSegment(
                            value: 1.30,
                            label: Text(
                              '130%',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          ButtonSegment(
                            value: 1.45,
                            label: Text(
                              '145%',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                        selected: {textScale},
                        onSelectionChanged: (val) {
                          cubit.setTextScaleFactor(val.first);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SwitchListTile(
                  key: const Key('accessibility_high_contrast_switch'),
                  secondary: CircleAvatar(
                    backgroundColor: isHighContrast
                        ? Colors.black
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.contrast,
                      color: isHighContrast ? Colors.yellow : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    context.tr('high_contrast'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    context.tr('high_contrast_desc'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: isHighContrast,
                  onChanged: (val) {
                    cubit.setHighContrast(val);
                  },
                ),
              ),

              // ── 3. Voice & Audio (TTS) ───────────────────────────────────
              _buildSectionHeader(context, 'section_voice_audio'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SwitchListTile(
                  key: const Key('accessibility_auto_read_switch'),
                  secondary: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.record_voice_over,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    context.tr('auto_read_diagnosis'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    context.tr('auto_read_desc'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: autoRead,
                  onChanged: (val) {
                    cubit.setAutoReadDiagnosis(val);
                  },
                ),
              ),

              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('speech_rate'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            speechRate <= 0.4
                                ? context.tr('speech_rate_slow')
                                : speechRate <= 0.6
                                    ? context.tr('speech_rate_normal')
                                    : context.tr('speech_rate_fast'),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<double>(
                        key: const Key('accessibility_speech_rate_selector'),
                        segments: [
                          ButtonSegment(
                            value: 0.35,
                            label: Text(
                              context.tr('speech_rate_slow'),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          ButtonSegment(
                            value: 0.50,
                            label: Text(
                              context.tr('speech_rate_normal'),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          ButtonSegment(
                            value: 0.70,
                            label: Text(
                              context.tr('speech_rate_fast'),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                        selected: {speechRate},
                        onSelectionChanged: (val) {
                          cubit.setSpeechRate(val.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const Key('accessibility_test_voice_button'),
                          icon: const Icon(Icons.volume_up_outlined, size: 18),
                          label: Text(context.tr('test_voice_btn')),
                          onPressed: () {
                            _ttsService.speak(
                              text: context.tr('test_voice_sample'),
                              languageCode: currentLang,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 4. Tactile & Haptics ─────────────────────────────────────
              _buildSectionHeader(context, 'section_tactile'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SwitchListTile(
                  key: const Key('accessibility_haptic_switch'),
                  secondary: CircleAvatar(
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    child: Icon(
                      Icons.vibration,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                  title: Text(
                    context.tr('haptic_feedback'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    context.tr('haptic_feedback_desc'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: haptic,
                  onChanged: (val) {
                    cubit.setHapticFeedback(val);
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
