// lib/presentation/chat/chat_screen.dart
//
// "Ask about this result" — follow-up questions about one diagnosis.
//
// A full screen rather than an inline expander: the result screen is already
// long, and a conversation needs the height.
//
// Two things this screen is careful about:
//
//  * It carries the AI-disclaimer framing rather than dropping it. A chat
//    interface is the easiest place in the app to accidentally launder a shaky
//    closed-set guess into confident-sounding prose, so the caveat is pinned
//    at the top of the transcript where it cannot be scrolled away from
//    permanently.
//  * A question asked with no signal is kept and marked, never discarded. The
//    farmer can see it is still there and retry it without retyping.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/chat/chat_cubit.dart';
import '../../application/chat/chat_state.dart';
import '../../core/utils/app_haptics.dart';
import '../../data/local/speech/speech_recognition_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../onboarding/localization/localization_provider.dart';
import '../shared/widgets/app_components.dart';
import '../shared/widgets/app_state_views.dart';

class ChatScreen extends StatelessWidget {
  final ChatCubit cubit;

  /// Optional: when present, the composer offers a mic. Speaking a question is
  /// the natural home for voice in this app — it used to sit on the diagnosis
  /// screen attached to a free-text "observations" box that a farmer was asked
  /// to fill in before being told anything. Here there is an obvious reason to
  /// talk, and an obvious thing to say.
  final SpeechRecognitionService? speechService;

  const ChatScreen({super.key, required this.cubit, this.speechService});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit..loadHistory(),
      child: _ChatView(speechService: speechService),
    );
  }
}

class _ChatView extends StatefulWidget {
  final SpeechRecognitionService? speechService;

  const _ChatView({this.speechService});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Null until checked; false means the device cannot transcribe the active
  /// language, in which case no mic is offered at all.
  bool? _speechAvailable;
  String _textBeforeListening = '';
  String? _speechErrorKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_speechAvailable != null) return;
    _checkSpeech();
  }

  Future<void> _checkSpeech() async {
    final service = widget.speechService;
    if (service == null) {
      if (mounted) setState(() => _speechAvailable = false);
      return;
    }
    final languageCode = LocalizationProvider.of(context)?.languageCode ?? 'en';
    final available = await service.localeAvailable(languageCode);
    if (!mounted) return;
    setState(() => _speechAvailable = available);
  }

  Future<void> _toggleRecording() async {
    final service = widget.speechService;
    if (service == null) return;

    if (service.isListening.value) {
      await service.stopListening();
      return;
    }

    setState(() => _speechErrorKey = null);
    _textBeforeListening = _controller.text.trimRight();
    final languageCode = LocalizationProvider.of(context)?.languageCode ?? 'en';

    try {
      AppHaptics.recordingToggled(context);
      await service.startListening(
        languageCode: languageCode,
        onResult: (words) {
          if (words.isEmpty) return;
          final prefix =
              _textBeforeListening.isEmpty ? '' : '$_textBeforeListening ';
          _controller.text = '$prefix$words';
          _controller.selection = TextSelection.collapsed(
            offset: _controller.text.length,
          );
        },
      );
    } on SpeechUnavailable catch (e) {
      if (!mounted) return;
      setState(() => _speechErrorKey = _speechMessageKey(e.reason));
    }
  }

  static String _speechMessageKey(SpeechUnavailableReason reason) {
    switch (reason) {
      case SpeechUnavailableReason.permissionDenied:
        return 'mic_permission_denied';
      case SpeechUnavailableReason.permissionPermanentlyDenied:
        return 'mic_permission_blocked';
      case SpeechUnavailableReason.unavailableOnDevice:
        return 'mic_unavailable';
      case SpeechUnavailableReason.languageNotInstalled:
        return 'mic_language_missing';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<ChatCubit>().send(text);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('chat_with_result_title')),
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocConsumer<ChatCubit, ChatState>(
          listener: (context, state) {
            if (state is ChatLoaded && !state.isSending) _scrollToEnd();
          },
          builder: (context, state) {
            if (state is ChatLoading || state is ChatInitial) {
              return const AppLoadingView();
            }

            final loaded = state as ChatLoaded;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Pinned above the conversation, not buried in it.
                      AppBanner.aiDisclaimer(
                        message: context.tr('chat_disclaimer_msg'),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      if (loaded.messages.isEmpty)
                        _SuggestedQuestions(
                          onPick: (q) {
                            _controller.text = q;
                            _send();
                          },
                        ),

                      for (final message in loaded.messages) ...[
                        _MessageBubble(
                          message: message,
                          onRetry: message.status == ChatMessageStatus.failed
                              ? () => context.read<ChatCubit>().retry(message)
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.smPlus),
                      ],

                      if (loaded.isSending) const _TypingIndicator(),

                      if (loaded.failure != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _FailureBanner(reason: loaded.failure!),
                      ],
                    ],
                  ),
                ),
                if (_speechErrorKey != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: AppBanner.warning(
                      message: context.tr(_speechErrorKey!),
                      actionLabel: _speechErrorKey == 'mic_permission_blocked'
                          ? context.tr('open_app_settings')
                          : null,
                      onAction: _speechErrorKey == 'mic_permission_blocked'
                          ? () => widget.speechService?.openAppSettings()
                          : null,
                    ),
                  ),
                _Composer(
                  controller: _controller,
                  enabled: !loaded.isSending,
                  onSend: _send,
                  speechService:
                      _speechAvailable == true ? widget.speechService : null,
                  onToggleRecording: _toggleRecording,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// Message bubble
// =============================================================================

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;

  const _MessageBubble({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fromUser = message.isFromUser;
    final failed = message.status == ChatMessageStatus.failed;
    final pending = message.status == ChatMessageStatus.pending;

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Column(
          crossAxisAlignment:
              fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.smPlus),
              decoration: BoxDecoration(
                // Solid fills, never translucent: the contrast behind text has
                // to be predictable in direct sunlight.
                color: fromUser
                    ? AppColors.primaryContainer
                    : AppColors.surfaceVariant,
                borderRadius: AppRadius.md,
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fromUser
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurface,
                ),
              ),
            ),
            if (pending || failed) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    failed
                        ? Icons.error_outline_rounded
                        : Icons.schedule_rounded,
                    size: 14,
                    color: failed ? AppColors.error : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    failed
                        ? context.tr('chat_not_sent')
                        : context.tr('chat_sending'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          failed ? AppColors.error : AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    // The question is kept, so retrying never means retyping.
                    TextButton(
                      key: const Key('chat_retry_button'),
                      onPressed: onRetry,
                      child: Text(context.tr('retry_btn')),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Suggested questions
// =============================================================================

/// Openers for an empty conversation.
///
/// A blank chat box is a bad prompt for anyone, and worse for someone who does
/// not write fluently. These are the questions farmers actually have after a
/// diagnosis, and tapping one costs no typing at all.
class _SuggestedQuestions extends StatelessWidget {
  final ValueChanged<String> onPick;

  const _SuggestedQuestions({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const keys = [
      'chat_suggestion_spread',
      'chat_suggestion_edible',
      'chat_suggestion_already_sprayed',
      'chat_suggestion_prevent',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('chat_suggestions_title'),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final key in keys) ...[
          _SuggestionChip(label: context.tr(key), onTap: () => onPick(context.tr(key))),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.smPlus,
              vertical: AppSpacing.smPlus,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(label, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Waiting, failing, composing
// =============================================================================

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.smPlus),
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(context.tr('chat_thinking'), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  final ChatUnavailableReason reason;

  const _FailureBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    final key = switch (reason) {
      ChatUnavailableReason.offline => 'chat_offline_msg',
      ChatUnavailableReason.rateLimited => 'chat_rate_limited_msg',
      ChatUnavailableReason.serverError => 'chat_server_error_msg',
    };
    return AppBanner.warning(message: context.tr(key));
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  /// Non-null only when this device can transcribe the active language.
  final SpeechRecognitionService? speechService;
  final VoidCallback onToggleRecording;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.onToggleRecording,
    this.speechService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.smPlus),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('chat_input'),
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => enabled ? onSend() : null,
              decoration: InputDecoration(
                hintText: context.tr('chat_input_hint'),
                border: const OutlineInputBorder(borderRadius: AppRadius.md),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.smPlus,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
          if (speechService != null) ...[
            const SizedBox(width: AppSpacing.xs),
            ValueListenableBuilder<bool>(
              valueListenable: speechService!.isListening,
              builder: (context, listening, _) => SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                child: IconButton(
                  key: const Key('chat_mic_button'),
                  onPressed: enabled ? onToggleRecording : null,
                  tooltip: listening
                      ? context.tr('mic_stop')
                      : context.tr('speak_observations'),
                  icon: Icon(
                    listening ? Icons.stop_rounded : Icons.mic_rounded,
                    color:
                        listening ? AppColors.error : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            child: IconButton.filled(
              key: const Key('chat_send_button'),
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send_rounded),
              tooltip: context.tr('chat_send'),
            ),
          ),
        ],
      ),
    );
  }
}
