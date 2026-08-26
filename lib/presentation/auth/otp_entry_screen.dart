// lib/presentation/auth/otp_entry_screen.dart
//
// One-time-code verification.
//
// The code entry itself lives in `widgets/otp_code_input.dart` — see the note
// there on why it is one hidden field behind six painted boxes rather than six
// real fields. The short version: it is what makes SMS autofill and paste
// work, and those are the difference between typing a code and not having to.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/auth/auth_cubit.dart';
import '../../application/auth/auth_state.dart';
import '../../application/sync/sync_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../onboarding/localization/localization_provider.dart';
import '../shared/widgets/app_components.dart';
import 'widgets/otp_code_input.dart';

enum OtpIdentifierType { phone, email }

class OtpEntryScreen extends StatefulWidget {
  final String identifier;
  final OtpIdentifierType identifierType;

  const OtpEntryScreen({
    super.key,
    required this.identifier,
    this.identifierType = OtpIdentifierType.phone,
  });

  @override
  State<OtpEntryScreen> createState() => _OtpEntryScreenState();
}

class _OtpEntryScreenState extends State<OtpEntryScreen> {
  static const int _codeLength = 6;
  static const int _resendCooldownSeconds = 60;

  final _otpController = TextEditingController();

  Timer? _countdownTimer;
  int _remainingSeconds = _resendCooldownSeconds;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _remainingSeconds = _resendCooldownSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _verify(BuildContext context) {
    final code = _otpController.text.trim();
    if (code.length != _codeLength) return;
    if (widget.identifierType == OtpIdentifierType.phone) {
      context.read<AuthCubit>().verifyPhoneOtp(widget.identifier, code);
    }
  }

  void _resend(BuildContext context) {
    if (_remainingSeconds > 0) return;
    // Clear the old code: leaving a stale, now-invalid code in the boxes
    // while a new one arrives is the fastest way to a confusing failure.
    _otpController.clear();
    _startCountdown();
    if (widget.identifierType == OtpIdentifierType.phone) {
      context.read<AuthCubit>().requestPhoneOtp(widget.identifier);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('otp_entry_title'))),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: _onStateChanged,
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final hasError = state is AuthOtpExpired || state is AuthError;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Recipient(identifier: widget.identifier),
                  const SizedBox(height: AppSpacing.lg),

                  if (state is AuthRateLimited) ...[
                    AppBanner(
                      key: const Key('otp_rate_limited_banner'),
                      icon: Icons.timer_outlined,
                      message: state.message,
                      foreground: AppColors.onWarningContainer,
                      background: AppColors.warningContainer,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  if (state is AuthOtpExpired) ...[
                    AppBanner(
                      key: const Key('otp_expired_banner'),
                      icon: Icons.error_outline_rounded,
                      message: state.message.isNotEmpty
                          ? state.message
                          : context.tr('otp_expired'),
                      foreground: AppColors.onErrorContainer,
                      background: AppColors.errorContainer,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  OtpCodeInput(
                    controller: _otpController,
                    length: _codeLength,
                    hasError: hasError,
                    enabled: !isLoading,
                    // Auto-submit on the sixth digit: there is nothing else
                    // to decide, so a confirm tap is a step with no content.
                    onCompleted: (_) => _verify(context),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Center(
                    child: OtpResendButton(
                      remainingSeconds: _remainingSeconds,
                      onResend: () => _resend(context),
                      resendLabel: context.tr('otp_resend'),
                      countdownLabel: (s) =>
                          context.tr('otp_resend_in').replaceAll('{n}', '$s'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Kept as an explicit action as well as auto-submit: a code
                  // pasted or autofilled without a final keystroke should
                  // still have something to press.
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('otp_submit_button'),
                      onPressed: isLoading ? null : () => _verify(context),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : Text(context.tr('otp_submit')),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Center(
                    child: TextButton.icon(
                      key: const Key('otp_change_number_button'),
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(context.tr('otp_change_number')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state is AuthSuccess) {
      final token = state.user.sessionToken;
      if (token != null && token.isNotEmpty) {
        try {
          context.read<SyncCubit?>()?.syncNow(token: token);
        } catch (_) {}
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(state.user);
    } else if (state is AuthError) {
      // A wrong code should leave the boxes empty and focused, not make the
      // user select-all and delete six digits by hand.
      _otpController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (state is AuthOtpExpired) {
      _otpController.clear();
    } else if (state is AuthOtpRequested) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('otp_sent_to').replaceAll('{identifier}', state.phoneNumber),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _Recipient extends StatelessWidget {
  final String identifier;

  const _Recipient({required this.identifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: AppRadius.md,
          ),
          child: const Icon(
            Icons.sms_outlined,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.tr('otp_enter_code_title'),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('otp_sent_prefix'),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        // The number gets its own line and weight: it is the one thing on
        // this screen the user needs to check before waiting for an SMS.
        Text(identifier, style: theme.textTheme.titleMedium),
      ],
    );
  }
}
