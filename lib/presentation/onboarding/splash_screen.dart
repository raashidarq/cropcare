import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/onboarding/app_state_cubit.dart';
import '../../application/onboarding/app_state_state.dart';
import '../home/home_screen.dart';
import 'localization/localization_provider.dart';
import 'language_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  final Duration delay;
  final VoidCallback? onNavigate;

  const SplashScreen({
    super.key,
    this.delay = const Duration(milliseconds: 1500),
    this.onNavigate,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, _onTimeout);
  }

  void _onTimeout() {
    if (!mounted) return;
    if (widget.onNavigate != null) {
      widget.onNavigate!();
      return;
    }

    final cubitState = context.read<AppStateCubit>().state;
    if (cubitState is AppStateOnboardingComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Language first: the introduction that follows is written in the
      // user's language, and choosing it is the one thing they can do
      // before understanding any of the copy.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 96,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('app_title'),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('splash_subtitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                // Solid, not alpha-blended: translucent text over a tinted
                // surface has an unpredictable contrast ratio in sunlight.
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
