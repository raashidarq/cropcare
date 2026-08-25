// lib/presentation/auth/auth_screen.dart
//
// Screen allowing guest users to sign in or create an account to upgrade their guest profile.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/auth/auth_cubit.dart';
import '../../application/auth/auth_state.dart';
import '../../application/sync/sync_cubit.dart';
import '../../domain/entities/local_user.dart';
import '../onboarding/localization/localization_provider.dart';

class AuthScreen extends StatefulWidget {
  final LocalUser currentUser;

  const AuthScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  bool _obscureSignInPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureSignUpConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  void _handleSignIn(BuildContext context) {
    if (_signInFormKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signInAndUpgrade(
            email: _signInEmailController.text.trim(),
            password: _signInPasswordController.text,
          );
    }
  }

  void _handleSignUp(BuildContext context) {
    if (_signUpFormKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().registerAndUpgrade(
            email: _signUpEmailController.text.trim(),
            password: _signUpPasswordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('auth_title')),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.tr('sign_in')),
            Tab(text: context.tr('create_account')),
          ],
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // Auto-sync offline guest data to newly authenticated cloud account
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
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Guest Upgrade Info Card ───────────────────────────────
                  if (widget.currentUser.isGuest) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sync_outlined,
                              color: theme.colorScheme.primary, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.tr('link_guest_account'),
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Rate Limit Alert Banner ──────────────────────────────
                  if (state is AuthRateLimited) ...[
                    Container(
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

                  // ── Tab Views ────────────────────────────────────────────
                  SizedBox(
                    height: 380,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Sign In
                        _buildSignInForm(context, isLoading),
                        // Tab 2: Create Account / Upgrade
                        _buildSignUpForm(context, isLoading),
                      ],
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

  Widget _buildSignInForm(BuildContext context, bool isLoading) {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('signin_email_field'),
            controller: _signInEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: context.tr('email'),
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) {
              if (val == null || !_isValidEmail(val)) {
                return context.tr('email_invalid');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('signin_password_field'),
            controller: _signInPasswordController,
            obscureText: _obscureSignInPassword,
            decoration: InputDecoration(
              labelText: context.tr('password'),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureSignInPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () => setState(
                    () => _obscureSignInPassword = !_obscureSignInPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) {
              if (val == null || val.length < 6) {
                return context.tr('password_short');
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              key: const Key('signin_submit_button'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isLoading ? null : () => _handleSignIn(context),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      context.tr('sign_in'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(BuildContext context, bool isLoading) {
    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('signup_email_field'),
            controller: _signUpEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: context.tr('email'),
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) {
              if (val == null || !_isValidEmail(val)) {
                return context.tr('email_invalid');
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('signup_password_field'),
            controller: _signUpPasswordController,
            obscureText: _obscureSignUpPassword,
            decoration: InputDecoration(
              labelText: context.tr('password'),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureSignUpPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () => setState(
                    () => _obscureSignUpPassword = !_obscureSignUpPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) {
              if (val == null || val.length < 6) {
                return context.tr('password_short');
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('signup_confirm_password_field'),
            controller: _signUpConfirmPasswordController,
            obscureText: _obscureSignUpConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureSignUpConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () => setState(() =>
                    _obscureSignUpConfirmPassword =
                        !_obscureSignUpConfirmPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) {
              if (val != _signUpPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              key: const Key('signup_submit_button'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isLoading ? null : () => _handleSignUp(context),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      context.tr('create_account'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
