import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'application/onboarding/app_state_cubit.dart';
import 'application/onboarding/app_state_state.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/onboarding/localization/localization_provider.dart';
import 'presentation/onboarding/splash_screen.dart';

class CropCareApp extends StatelessWidget {
  final AppStateCubit appStateCubit;

  const CropCareApp({
    super.key,
    required this.appStateCubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: appStateCubit,
      child: BlocBuilder<AppStateCubit, AppStateState>(
        builder: (context, state) {
          final isCompleted = state is AppStateOnboardingComplete;

          return LocalizationProvider(
            languageCode: state.languageCode,
            child: MaterialApp(
              title: 'CropCare',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.green,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
              ),
              home: state is AppStateLoading
                  ? const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    )
                  : isCompleted
                      ? const HomeScreen()
                      : const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
