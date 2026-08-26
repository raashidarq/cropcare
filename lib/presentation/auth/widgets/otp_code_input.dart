// lib/presentation/auth/widgets/otp_code_input.dart
//
// Six-box one-time-code entry.
//
// Implemented as ONE hidden TextField behind six painted boxes, rather than
// six separate TextFields. Six real fields is the more obvious approach and
// the one that goes wrong: pasting a code fills only the focused box,
// backspace behaviour has to be hand-managed per field, platform SMS autofill
// delivers the whole code to a single field and so fills only one box, and
// screen readers announce six unlabelled inputs.
//
// With a single field:
//  * `autofillHints: [AutofillHints.oneTimeCode]` lets Android/iOS fill the
//    code straight from the SMS — the farmer never leaves the app to read it.
//  * Paste works, because the paste target is one field.
//  * Backspace is just backspace.
//  * The boxes are pure presentation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class OtpCodeInput extends StatefulWidget {
  final TextEditingController controller;
  final int length;

  /// Fired once the final digit is entered. Auto-submitting removes a step
  /// that has no purpose — the code is either complete or it is not.
  final ValueChanged<String>? onCompleted;

  final bool hasError;
  final bool enabled;

  const OtpCodeInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
    this.hasError = false,
    this.enabled = true,
  });

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  final FocusNode _focusNode = FocusNode();
  bool _completedFired = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    // Open the keyboard on arrival: there is nothing else to do on this
    // screen, so making the user tap first is pure friction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    final value = widget.controller.text;
    if (value.length == widget.length && !_completedFired) {
      _completedFired = true;
      _focusNode.unfocus();
      widget.onCompleted?.call(value);
    } else if (value.length < widget.length) {
      // Allows re-firing after a correction.
      _completedFired = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;

    return Semantics(
      label: MaterialLocalizations.of(context).signedInLabel,
      textField: true,
      child: Stack(
        children: [
          // The real input, invisible but focusable and fully functional.
          Opacity(
            opacity: 0,
            child: TextField(
              key: const Key('otp_code_field'),
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              showCursor: false,
              style: const TextStyle(height: 1),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // The boxes the user actually sees. Tapping anywhere focuses the
          // hidden field.
          GestureDetector(
            onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, (index) {
                final filled = index < value.length;
                final isNext = index == value.length && _focusNode.hasFocus;
                return _OtpBox(
                  character: filled ? value[index] : '',
                  isActive: isNext,
                  hasError: widget.hasError,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final String character;
  final bool isActive;
  final bool hasError;

  const _OtpBox({
    required this.character,
    required this.isActive,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color borderColor;
    if (hasError) {
      borderColor = AppColors.error;
    } else if (isActive) {
      borderColor = AppColors.primary;
    } else if (character.isNotEmpty) {
      borderColor = AppColors.outline;
    } else {
      borderColor = AppColors.outlineVariant;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasError ? AppColors.errorContainer : AppColors.surface,
        borderRadius: AppRadius.sm,
        border: Border.all(
          color: borderColor,
          width: isActive || hasError ? 2 : 1,
        ),
      ),
      child: Text(
        character,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: hasError ? AppColors.error : AppColors.onSurface,
        ),
      ),
    );
  }
}

/// Resend control with its cooldown. Separated so the countdown does not
/// rebuild the code boxes on every tick.
class OtpResendButton extends StatelessWidget {
  final int remainingSeconds;
  final VoidCallback onResend;
  final String Function(int seconds) countdownLabel;
  final String resendLabel;

  const OtpResendButton({
    super.key,
    required this.remainingSeconds,
    required this.onResend,
    required this.countdownLabel,
    required this.resendLabel,
  });

  @override
  Widget build(BuildContext context) {
    final canResend = remainingSeconds <= 0;
    return TextButton.icon(
      key: const Key('otp_resend_button'),
      onPressed: canResend ? onResend : null,
      icon: Icon(
        canResend ? Icons.refresh_rounded : Icons.timer_outlined,
        size: 18,
      ),
      label: Text(
        canResend ? resendLabel : countdownLabel(remainingSeconds),
      ),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, AppSpacing.minTouchTarget),
      ),
    );
  }
}
