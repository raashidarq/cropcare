// lib/presentation/auth/auth_screen.dart
//
// Sign in / create account, and the guest→registered upgrade.
//
// Structure notes (why this looks the way it does):
//
//  * ONE intent visible at a time. The previous version stacked a TabBar
//    (Sign In / Create Account) on top of a segmented toggle (Email / Phone),
//    so before typing anything the user had to place themselves in a 2×2
//    matrix. Intent is now a single footer link — the pattern used by most
//    modern sign-in screens — leaving one primary action on screen.
//  * NO fixed-height form area. The old `SizedBox(height: 440)` around the
//    TabBarView clipped its contents at larger accessibility text scales and
//    in Sinhala/Tamil, whose strings run longer than English. The form now
//    sizes to its content inside a scroll view.
//  * Autofill is wired. Every field declares `autofillHints` inside an
//    `AutofillGroup`, so password managers and platform autofill work and a
//    saved credential is offered rather than retyped — which matters most on
//    exactly the low-end devices this app targets.
//  * Focus chains. Each field declares `textInputAction` and moves focus on
//    submit, so the keyboard never has to be dismissed mid-form.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInput;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/auth/auth_cubit.dart';
import '../../application/auth/auth_state.dart';
import '../../application/sync/sync_cubit.dart';
import '../../config/feature_flags.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/local_user.dart';
import '../onboarding/localization/localization_provider.dart';
import '../settings/terms_privacy_screen.dart';
import '../shared/widgets/app_components.dart';
import 'forgot_password_screen.dart';
import 'otp_entry_screen.dart';
import 'widgets/auth_form_fields.dart';

enum AuthMethod { email, phone }

enum AuthIntent { signIn, createAccount }

class AuthScreen extends StatefulWidget {
  final LocalUser currentUser;
  final bool? phoneAuthEnabled;

  const AuthScreen({
    super.key,
    required this.currentUser,
    this.phoneAuthEnabled,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMethod _method = AuthMethod.email;
  AuthIntent _intent = AuthIntent.signIn;

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isPhoneEnabled => widget.phoneAuthEnabled ?? kPhoneAuthEnabled;
  bool get _isSignUp => _intent == AuthIntent.createAccount;
  bool get _isPhone => _method == AuthMethod.phone && _isPhoneEnabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _switchIntent() {
    setState(() {
      _intent = _isSignUp ? AuthIntent.signIn : AuthIntent.createAccount;
      // Passwords do not carry across a mode switch: a sign-in password
      // typed into a "confirm new password" field is a silent trap.
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Tells the platform the credential was used successfully, which is what
    // prompts "save this password?".
    TextInput.finishAutofillContext();

    final cubit = context.read<AuthCubit>();
    if (_isPhone) {
      cubit.requestPhoneOtp(_phoneController.text.trim());
    } else if (_isSignUp) {
      cubit.registerAndUpgrade(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      cubit.signInAndUpgrade(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('auth_title'))),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: _onStateChanged,
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(isSignUp: _isSignUp),
                      const SizedBox(height: AppSpacing.lg),

                      if (widget.currentUser.isGuest) ...[
                        _GuestUpgradeNotice(),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      if (state is AuthRateLimited) ...[
                        AppBanner(
                          icon: Icons.timer_outlined,
                          message: state.message,
                          foreground: AppColors.onWarningContainer,
                          background: AppColors.warningContainer,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      if (_isPhoneEnabled) ...[
                        AppSegmentedToggle<AuthMethod>(
                          key: const Key('auth_method_selector'),
                          selected: _method,
                          onChanged: (m) => setState(() => _method = m),
                          segments: [
                            AppSegment(
                              key: const Key('auth_method_email'),
                              value: AuthMethod.email,
                              label: context.tr('auth_method_email'),
                              icon: Icons.email_outlined,
                            ),
                            AppSegment(
                              key: const Key('auth_method_phone'),
                              value: AuthMethod.phone,
                              label: context.tr('auth_method_phone'),
                              icon: Icons.phone_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      ..._buildFields(context, isLoading),

                      const SizedBox(height: AppSpacing.lg),
                      _SubmitButton(
                        isLoading: isLoading,
                        isPhone: _isPhone,
                        isSignUp: _isSignUp,
                        onPressed: () => _submit(context),
                      ),

                      if (_isSignUp) ...[
                        const SizedBox(height: AppSpacing.smPlus),
                        const _ConsentDisclaimer(),
                      ],

                      const SizedBox(height: AppSpacing.lg),
                      _IntentSwitch(
                        isSignUp: _isSignUp,
                        onSwitch: _switchIntent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFields(BuildContext context, bool isLoading) {
    if (_isPhone) {
      return [
        AuthPhoneField(
          key: const Key('signin_phone_field'),
          controller: _phoneController,
          onSubmitted: () => _submit(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr('phone_otp_explainer'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ];
    }

    return [
      AuthEmailField(
        key: const Key('signin_email_field'),
        controller: _emailController,
        onSubmitted: () => _passwordFocus.requestFocus(),
      ),
      const SizedBox(height: AppSpacing.md),
      AuthPasswordField(
        key: const Key('signin_password_field'),
        controller: _passwordController,
        focusNode: _passwordFocus,
        obscured: _obscurePassword,
        onToggleObscured: () =>
            setState(() => _obscurePassword = !_obscurePassword),
        isNewPassword: _isSignUp,
        textInputAction:
            _isSignUp ? TextInputAction.next : TextInputAction.done,
        onSubmitted: () => _isSignUp
            ? _confirmPasswordFocus.requestFocus()
            : _submit(context),
      ),
      if (_isSignUp) ...[
        const SizedBox(height: AppSpacing.sm),
        // Live feedback beats a validator message after the fact: the user
        // can see the rule being satisfied as they type.
        PasswordStrengthMeter(controller: _passwordController),
        const SizedBox(height: AppSpacing.md),
        AuthPasswordField(
          key: const Key('signup_confirm_password_field'),
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          obscured: _obscureConfirmPassword,
          onToggleObscured: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
          labelKey: 'confirm_password',
          isNewPassword: true,
          textInputAction: TextInputAction.done,
          onSubmitted: () => _submit(context),
          extraValidator: (value) => value != _passwordController.text
              ? context.tr('passwords_do_not_match')
              : null,
        ),
      ],
      if (!_isSignUp) ...[
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            key: const Key('signin_forgot_password_button'),
            onPressed: isLoading
                ? null
                : () {
                    final cubit = context.read<AuthCubit>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: cubit,
                          child: const ForgotPasswordScreen(),
                        ),
                      ),
                    );
                  },
            child: Text(context.tr('forgot_password')),
          ),
        ),
      ],
    ];
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state is AuthSuccess) {
      // Newly authenticated: push whatever the guest accumulated offline.
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
    } else if (state is AuthOtpRequested) {
      final navigator = Navigator.of(context);
      final cubit = context.read<AuthCubit>();
      final syncCubit = context.read<SyncCubit?>();
      navigator.push<LocalUser>(
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              if (syncCubit != null) BlocProvider.value(value: syncCubit),
            ],
            child: OtpEntryScreen(
              identifier: state.phoneNumber,
              identifierType: OtpIdentifierType.phone,
            ),
          ),
        ),
      ).then((user) {
        if (user != null && mounted) navigator.pop(user);
      });
    } else if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// =============================================================================
// Pieces
// =============================================================================

class _Header extends StatelessWidget {
  final bool isSignUp;

  const _Header({required this.isSignUp});

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
            Icons.eco_rounded,
            color: AppColors.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          // Matches the submit button's label, so the screen states one
          // intent in one voice.
          isSignUp ? context.tr('create_account') : context.tr('sign_in'),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isSignUp
              ? context.tr('create_account_subtitle')
              : context.tr('sign_in_subtitle'),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Explains what linking an account actually buys the farmer. The old copy
/// was a single generic line; the point that matters is that nothing already
/// on the phone is lost, which is the thing a cautious user worries about.
class _GuestUpgradeNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBanner(
      icon: Icons.cloud_sync_outlined,
      title: context.tr('link_account_benefit_title'),
      message: context.tr('link_guest_account'),
      foreground: AppColors.onPrimaryContainer,
      background: AppColors.primaryContainer,
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isPhone;
  final bool isSignUp;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isLoading,
    required this.isPhone,
    required this.isSignUp,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = isPhone
        ? context.tr('send_otp')
        : (isSignUp ? context.tr('create_account') : context.tr('sign_in'));

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        key: Key(
          isPhone ? 'signin_phone_submit_button' : 'signin_submit_button',
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            // Spinner replaces the label in place, so the button does not
            // resize and the tap target stays put.
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _IntentSwitch extends StatelessWidget {
  final bool isSignUp;
  final VoidCallback onSwitch;

  const _IntentSwitch({required this.isSignUp, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            isSignUp
                ? context.tr('already_have_account')
                : context.tr('new_to_cropcare'),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.end,
          ),
        ),
        TextButton(
          key: const Key('auth_switch_intent_button'),
          onPressed: onSwitch,
          child: Text(
            isSignUp ? context.tr('sign_in') : context.tr('create_account'),
          ),
        ),
      ],
    );
  }
}

class _ConsentDisclaimer extends StatelessWidget {
  const _ConsentDisclaimer();

  void _open(BuildContext context, int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TermsPrivacyScreen(initialTabIndex: tabIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${context.tr('consent_agreement_prefix')} ',
          style: theme.textTheme.bodySmall,
        ),
        // Kept as tappable text rather than buttons so the sentence still
        // reads as a sentence; each still clears the 48dp target via padding.
        InkWell(
          key: const Key('consent_terms_link'),
          onTap: () => _open(context, 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.smPlus),
            child: Text(context.tr('terms_of_service'), style: linkStyle),
          ),
        ),
        Text(
          ' ${context.tr('and_connector')} ',
          style: theme.textTheme.bodySmall,
        ),
        InkWell(
          key: const Key('consent_privacy_link'),
          onTap: () => _open(context, 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.smPlus),
            child: Text(context.tr('privacy_policy'), style: linkStyle),
          ),
        ),
      ],
    );
  }
}
