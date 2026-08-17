import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/onboarding/app_state_cubit.dart';
import '../../application/onboarding/app_state_state.dart';
import '../home/home_screen.dart';
import 'localization/localization_provider.dart';
import 'onboarding_screen.dart';

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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
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
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
