// lib/presentation/auth/widgets/auth_form_fields.dart
//
// The auth form controls, shared across sign-in, sign-up and password reset.
//
// These exist because the three auth screens each re-declared their own
// TextFormFields with slightly different decoration, validation messages and
// keyboard behaviour — and none of them declared autofill hints, so saved
// credentials were never offered and every sign-in meant retyping a password
// on a phone keyboard.
//
// Every field here:
//  * declares `autofillHints` (must sit inside an `AutofillGroup`),
//  * sets an appropriate `keyboardType` and `textInputAction`,
//  * validates with a localized message,
//  * and reserves a comfortable target — no dense inputs.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../onboarding/localization/localization_provider.dart';

/// Shared decoration so every auth input looks identical.
InputDecoration authFieldDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  IconData? prefixIcon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
    suffixIcon: suffix,
    border: const OutlineInputBorder(borderRadius: AppRadius.sm),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
  );
}

// =============================================================================
// Email
// =============================================================================

class AuthEmailField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  const AuthEmailField({
    super.key,
    required this.controller,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      // Email addresses are case-insensitive and auto-capitalisation on a
      // phone keyboard silently produces "Farmer@..." which then fails to
      // match on some backends.
      textCapitalization: TextCapitalization.none,
      autofillHints: const [AutofillHints.email],
      onFieldSubmitted: (_) => onSubmitted?.call(),
      decoration: authFieldDecoration(
        context,
        label: context.tr('email'),
        prefixIcon: Icons.email_outlined,
      ),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return context.tr('email_required');
        // Deliberately permissive: the authoritative check is the server's.
        // An over-strict client regex rejects valid addresses.
        if (!v.contains('@') || !v.contains('.') || v.length < 5) {
          return context.tr('email_invalid');
        }
        return null;
      },
    );
  }
}

// =============================================================================
// Password
// =============================================================================

class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool obscured;
  final VoidCallback onToggleObscured;

  /// Signals a *new* password so the platform offers to generate/save one
  /// rather than autofilling an existing credential.
  final bool isNewPassword;

  final String labelKey;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  /// Extra rule layered on top of the built-in ones (e.g. "must match").
  final String? Function(String value)? extraValidator;

  const AuthPasswordField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.obscured,
    required this.onToggleObscured,
    this.isNewPassword = false,
    this.labelKey = 'password',
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.extraValidator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscured,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: textInputAction,
      autofillHints: [
        isNewPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      onFieldSubmitted: (_) => onSubmitted?.call(),
      decoration: authFieldDecoration(
        context,
        label: context.tr(labelKey),
        prefixIcon: Icons.lock_outline_rounded,
        // A visibility toggle is not a nicety here: typing a password blind
        // on a phone keyboard, in a second script, is where sign-in attempts
        // are lost.
        suffix: IconButton(
          icon: Icon(
            obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          tooltip: context.tr(obscured ? 'show_password' : 'hide_password'),
          onPressed: onToggleObscured,
        ),
      ),
      validator: (value) {
        final v = value ?? '';
        if (v.isEmpty) return context.tr('password_required');
        if (isNewPassword && v.length < 8) return context.tr('password_too_short');
        return extraValidator?.call(v);
      },
    );
  }
}

// =============================================================================
// Phone
// =============================================================================

class AuthPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  const AuthPhoneField({
    super.key,
    required this.controller,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.telephoneNumber],
      onFieldSubmitted: (_) => onSubmitted?.call(),
      decoration: authFieldDecoration(
        context,
        label: context.tr('phone_number'),
        hint: context.tr('phone_number_hint'),
        prefixIcon: Icons.phone_outlined,
      ),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return context.tr('phone_required');
        final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 9) return context.tr('phone_invalid');
        return null;
      },
    );
  }
}

// =============================================================================
// Password strength
// =============================================================================

/// Live strength feedback while typing a new password.
///
/// Deliberately a coarse three-band signal rather than a score: a precise
/// percentage implies a rigour this heuristic does not have, and the useful
/// message is "this is too easy to guess", not "47%".
class PasswordStrengthMeter extends StatefulWidget {
  final TextEditingController controller;

  const PasswordStrengthMeter({super.key, required this.controller});

  @override
  State<PasswordStrengthMeter> createState() => _PasswordStrengthMeterState();
}

enum _Strength { weak, fair, strong }

class _PasswordStrengthMeterState extends State<PasswordStrengthMeter> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  _Strength _evaluate(String value) {
    var score = 0;
    if (value.length >= 8) score++;
    if (value.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;

    if (score <= 2) return _Strength.weak;
    if (score <= 3) return _Strength.fair;
    return _Strength.strong;
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;
    if (value.isEmpty) return const SizedBox.shrink();

    final strength = _evaluate(value);
    final (color, labelKey, filled) = switch (strength) {
      _Strength.weak => (AppColors.error, 'password_weak', 1),
      _Strength.fair => (AppColors.warning, 'password_fair', 2),
      _Strength.strong => (AppColors.success, 'password_strong', 3),
    };

    return Semantics(
      label: context.tr(labelKey),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i < filled ? color : AppColors.surfaceVariant,
                  borderRadius: AppRadius.full,
                ),
              ),
            ),
            if (i < 2) const SizedBox(width: AppSpacing.xs),
          ],
          const SizedBox(width: AppSpacing.smPlus),
          Text(
            context.tr(labelKey),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
