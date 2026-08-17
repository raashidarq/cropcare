import 'package:flutter/material.dart';

import '../../domain/entities/crop.dart';
import '../../domain/entities/local_user.dart';
import '../../domain/repositories/crop_repository.dart';
import '../../domain/usecases/crop/get_supported_crops_use_case.dart';
import '../crop/crop_selection_screen.dart';
import '../onboarding/localization/localization_provider.dart';
import '../onboarding/widgets/change_language_dialog.dart';
import '../settings/settings_screen.dart';

class _FallbackCropRepository implements CropRepository {
  @override
  Future<List<Crop>> getSupportedCrops() async => [
        const Crop(
          id: 'tomato',
          nameEn: 'Tomato',
          nameSi: 'තක්කාලි',
          nameTa: 'தக்காளி',
        ),
        const Crop(
          id: 'chili',
          nameEn: 'Chili',
          nameSi: 'මිරිස්',
          nameTa: 'மிளகாய்',
        ),
      ];
}

class HomeScreen extends StatefulWidget {
  final LocalUser? user;
  final GetSupportedCropsUseCase? getSupportedCropsUseCase;

  const HomeScreen({
    super.key,
    this.user,
    this.getSupportedCropsUseCase,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LocalUser _user;
  late final GetSupportedCropsUseCase _getSupportedCropsUseCase;

  @override
  void initState() {
    super.initState();
    _user = widget.user ??
        LocalUser(
          id: 'guest-default',
          isGuest: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    _getSupportedCropsUseCase = widget.getSupportedCropsUseCase ??
        GetSupportedCropsUseCase(_FallbackCropRepository());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('home_title')),
        actions: [
          IconButton(
            key: const Key('home_settings_icon'),
            icon: const Icon(Icons.settings),
            tooltip: context.tr('settings_title'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('home_change_language_icon'),
            icon: const Icon(Icons.language),
            tooltip: context.tr('change_language'),
            onPressed: () => ChangeLanguageDialog.show(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home_work_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('home_welcome'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Guest User ID: ${_user.id.length >= 8 ? _user.id.substring(0, 8) : _user.id}...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                key: const Key('home_start_scan_button'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  context.tr('start_scan'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CropSelectionScreen(
                        getSupportedCropsUseCase: _getSupportedCropsUseCase,
                        user: _user,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('home_change_language_button'),
                icon: const Icon(Icons.translate),
                label: Text(context.tr('change_language')),
                onPressed: () => ChangeLanguageDialog.show(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
