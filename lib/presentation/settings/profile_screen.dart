// lib/presentation/settings/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';

import '../../application/auth/auth_cubit.dart';
import '../../application/sync/sync_cubit.dart';
import '../../application/auth/auth_state.dart';
import '../../domain/entities/local_user.dart';
import '../auth/auth_screen.dart';
import '../onboarding/localization/localization_provider.dart';

class ProfileScreen extends StatelessWidget {
  final LocalUser user;
  final AuthCubit? authCubit;

  const ProfileScreen({
    super.key,
    required this.user,
    this.authCubit,
  });

  void _showDeleteAccountDialog(BuildContext context, AuthCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(context.tr('delete_account_confirm_title')),
        content: Text(context.tr('delete_account_confirm_desc')),
        actions: [
          TextButton(
            key: const Key('delete_account_cancel_button'),
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            key: const Key('delete_account_confirm_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              cubit.deleteAccount();
            },
            child: Text(context.tr('delete_account_action')),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context, AuthCubit cubit, String? currentEmail) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: currentEmail ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(context.tr('change_email')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('change_email_input'),
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.tr('email'),
                  hintText: context.tr('enter_new_email'),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.tr('email_invalid');
                  }
                  final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim())) {
                    return context.tr('email_invalid');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            key: const Key('change_email_submit_button'),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final newEmail = controller.text.trim();
                Navigator.of(dialogCtx).pop();
                cubit.updateEmail(newEmail);
              }
            },
            child: Text(context.tr('save_changes')),
          ),
        ],
      ),
    );
  }

  void _showChangePhoneDialog(BuildContext context, AuthCubit cubit, String? currentPhone) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _ChangePhoneDialog(
        initialPhone: currentPhone ?? '',
        cubit: cubit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGuest = user.isGuest;
    final displayId = user.email ?? user.phoneNumber ?? 'Guest User';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile_title')),
        elevation: 0,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop(state.user);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final cubit = context.read<AuthCubit>();
          final activeUser = state is AuthSuccess ? state.user : user;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // ── Avatar & Name Card ─────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: isGuest
                              ? theme.colorScheme.surfaceContainerHighest
                              : theme.colorScheme.primaryContainer,
                          child: Icon(
                            isGuest ? Icons.person_outline : Icons.person,
                            size: 48,
                            color: isGuest
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          displayId,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isGuest
                                ? AppColors.warningContainer
                                : AppColors.successContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isGuest
                                  ? AppColors.warning
                                  : AppColors.success,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isGuest
                                ? context.tr('guest_badge')
                                : context.tr('profile_registered_user'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isGuest
                                  ? AppColors.onWarningContainer
                                  : AppColors.onSuccessContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Account Details Card ───────────────────────────────────
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('profile_account_info'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          _ProfileRow(
                            label: context.tr('profile_account_type'),
                            value: isGuest
                                ? context.tr('guest_badge')
                                : context.tr('profile_registered_user'),
                          ),
                          if (!isGuest || activeUser.email != null) ...[
                            const SizedBox(height: 12),
                            _ProfileRow(
                              label: context.tr('email'),
                              value: activeUser.email ?? '—',
                              editKey: 'edit_email_button',
                              onEdit: isGuest
                                  ? null
                                  : () => _showChangeEmailDialog(
                                        context,
                                        cubit,
                                        activeUser.email,
                                      ),
                            ),
                          ],
                          if (!isGuest || activeUser.phoneNumber != null) ...[
                            const SizedBox(height: 12),
                            _ProfileRow(
                              label: context.tr('phone_number'),
                              value: activeUser.phoneNumber ?? '—',
                              editKey: 'edit_phone_button',
                              onEdit: isGuest
                                  ? null
                                  : () => _showChangePhoneDialog(
                                        context,
                                        cubit,
                                        activeUser.phoneNumber,
                                      ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _ProfileRow(
                            label: context.tr('profile_user_id'),
                            value: activeUser.remoteUserId ?? activeUser.id,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Action: Upgrade or Sign Out ────────────────────────────
                  if (isGuest)
                    ElevatedButton.icon(
                      key: const Key('profile_link_account_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.link),
                      label: Text(
                        context.tr('link_account_btn'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final updated = await Navigator.push<LocalUser>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<AuthCubit>(),
                              child: AuthScreen(currentUser: user),
                            ),
                          ),
                        );
                        if (updated != null && context.mounted) {
                          Navigator.of(context).pop(updated);
                        }
                      },
                    )
                  else
                    OutlinedButton.icon(
                      key: const Key('profile_sign_out_button'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: Text(
                        context.tr('sign_out'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        // Auto-sync is meaningless without a session, and a
                        // stored "on" must not carry into the next guest
                        // session — clear it alongside the sign-out.
                        try {
                          context.read<SyncCubit>().disableAutoSyncOnSignOut();
                        } catch (_) {}
                        context.read<AuthCubit>().signOut();
                      },
                    ),

                  const SizedBox(height: 32),

                  // ── Danger Zone: Delete Account ───────────────────────────
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.delete_forever_outlined,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('delete_account'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('delete_account_desc'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              key: const Key('delete_account_button'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(color: theme.colorScheme.error),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text(context.tr('delete_account')),
                              onPressed: isLoading
                                  ? null
                                  : () => _showDeleteAccountDialog(
                                        context,
                                        context.read<AuthCubit>(),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.38),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onEdit;
  final String? editKey;

  const _ProfileRow({
    required this.label,
    required this.value,
    this.onEdit,
    this.editKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  key: editKey != null ? Key(editKey!) : null,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: label,
                  onPressed: onEdit,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChangePhoneDialog extends StatefulWidget {
  final String initialPhone;
  final AuthCubit cubit;

  const _ChangePhoneDialog({
    required this.initialPhone,
    required this.cubit,
  });

  @override
  State<_ChangePhoneDialog> createState() => _ChangePhoneDialogState();
}

class _ChangePhoneDialogState extends State<_ChangePhoneDialog> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.cubit.requestPhoneChangeOtp(_phoneController.text.trim());
      if (mounted) {
        setState(() {
          _isOtpSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length < 4) {
      setState(() {
        _error = context.tr('otp_wrong_code');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.cubit.verifyPhoneChangeOtp(
        _phoneController.text.trim(),
        _otpController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isOtpSent ? context.tr('verify_new_phone') : context.tr('change_phone')),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isOtpSent) ...[
              TextFormField(
                key: const Key('change_phone_input'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: context.tr('phone_number'),
                  hintText: context.tr('enter_new_phone'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.tr('phone_invalid');
                  }
                  if (val.trim().length < 8) {
                    return context.tr('phone_invalid');
                  }
                  return null;
                },
              ),
            ] else ...[
              Text(
                '${context.tr('otp_code_label')}: ${_phoneController.text.trim()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('change_phone_otp_input'),
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: context.tr('otp_code_label'),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        if (!_isOtpSent)
          ElevatedButton(
            key: const Key('change_phone_send_code_button'),
            onPressed: _isLoading ? null : _sendOtp,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr('send_code')),
          )
        else
          ElevatedButton(
            key: const Key('change_phone_verify_button'),
            onPressed: _isLoading ? null : _verifyOtp,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr('save_changes')),
          ),
      ],
    );
  }
}
