import 'package:drift/drift.dart';

import '../../domain/entities/app_state.dart';
import '../../domain/repositories/app_state_repository.dart';
import '../local/database/app_database.dart';

class AppStateRepositoryImpl implements AppStateRepository {
  final AppDatabase db;

  AppStateRepositoryImpl(this.db);

  @override
  Future<AppState> getAppState() async {
    final query = db.select(db.appStateTable)..where((tbl) => tbl.id.equals(1));
    final row = await query.getSingleOrNull();

    if (row == null) {
      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      await db.into(db.appStateTable).insert(
        AppStateTableCompanion.insert(
          id: const Value(1),
          onboardingCompleted: const Value(0),
          languageCode: const Value('en'),
          firstLaunchAt: Value(nowIso),
        ),
      );
      return AppState(
        onboardingCompleted: false,
        languageCode: 'en',
        firstLaunchAt: now,
      );
    }

    return AppState(
      onboardingCompleted: row.onboardingCompleted == 1,
      languageCode: row.languageCode,
      firstLaunchAt: row.firstLaunchAt != null
          ? DateTime.tryParse(row.firstLaunchAt!)
          : null,
    );
  }

  @override
  Future<void> completeOnboarding(String languageCode) async {
    final query = db.select(db.appStateTable)..where((tbl) => tbl.id.equals(1));
    final row = await query.getSingleOrNull();

    if (row == null) {
      final nowIso = DateTime.now().toIso8601String();
      await db.into(db.appStateTable).insert(
        AppStateTableCompanion.insert(
          id: const Value(1),
          onboardingCompleted: const Value(1),
          languageCode: Value(languageCode),
          firstLaunchAt: Value(nowIso),
        ),
      );
    } else {
      await (db.update(db.appStateTable)..where((tbl) => tbl.id.equals(1)))
          .write(
        AppStateTableCompanion(
          onboardingCompleted: const Value(1),
          languageCode: Value(languageCode),
        ),
      );
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    final query = db.select(db.appStateTable)..where((tbl) => tbl.id.equals(1));
    final row = await query.getSingleOrNull();

    if (row == null) {
      final nowIso = DateTime.now().toIso8601String();
      await db.into(db.appStateTable).insert(
        AppStateTableCompanion.insert(
          id: const Value(1),
          onboardingCompleted: const Value(0),
          languageCode: Value(languageCode),
          firstLaunchAt: Value(nowIso),
        ),
      );
    } else {
      await (db.update(db.appStateTable)..where((tbl) => tbl.id.equals(1)))
          .write(
        AppStateTableCompanion(
          languageCode: Value(languageCode),
        ),
      );
    }
  }
}
