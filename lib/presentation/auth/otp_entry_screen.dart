// lib/presentation/auth/otp_entry_screen.dart
//
// Screen for entering OTP verification code for phone/email authentication.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/auth/auth_cubit.dart';
import '../../application/auth/auth_state.dart';
import '../../application/sync/sync_cubit.dart';
import '../onboarding/localization/localization_provider.dart';

enum OtpIdentifierType {
  phone,
  email,
}

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
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  Timer? _countdownTimer;
  int _remainingSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _remainingSeconds = 60;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _handleVerify(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      final code = _otpController.text.trim();
      if (widget.identifierType == OtpIdentifierType.phone) {
        context.read<AuthCubit>().verifyPhoneOtp(widget.identifier, code);
      }
    }
  }

  void _handleResend(BuildContext context) {
    if (_remainingSeconds <= 0) {
      _startCountdown();
      if (widget.identifierType == OtpIdentifierType.phone) {
        context.read<AuthCubit>().requestPhoneOtp(widget.identifier);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('otp_entry_title')),
        elevation: 0,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
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
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(state.user);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is AuthOtpRequested) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verification code sent to ${state.phoneNumber}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Enter the 6-digit code sent to:',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.identifier,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Rate Limit Banner ───────────────────────────────
                    if (state is AuthRateLimited) ...[
                      Container(
                        key: const Key('otp_rate_limited_banner'),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                color: Colors.orange.shade900, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Expired OTP Banner ──────────────────────────────
                    if (state is AuthOtpExpired) ...[
                      Container(
                        key: const Key('otp_expired_banner'),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade900, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.message.isNotEmpty
                                    ? state.message
                                    : context.tr('otp_expired'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── 6-Digit Code Input ──────────────────────────────
                    TextFormField(
                      key: const Key('otp_code_field'),
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8.0,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        labelText: context.tr('otp_code_label'),
                        hintText: '000000',
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length != 6) {
                          return context.tr('otp_wrong_code');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Submit Button ───────────────────────────────────
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        key: const Key('otp_submit_button'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : () => _handleVerify(context),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : Text(
                                context.tr('otp_submit'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Resend Code Button ──────────────────────────────
                    Center(
                      child: TextButton(
                        key: const Key('otp_resend_button'),
                        onPressed: (_remainingSeconds > 0 || isLoading)
                            ? null
                            : () => _handleResend(context),
                        child: Text(
                          _remainingSeconds > 0
                              ? context.tr('otp_resend_in').replaceAll('{n}', '$_remainingSeconds')
                              : context.tr('otp_resend'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _remainingSeconds > 0
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
