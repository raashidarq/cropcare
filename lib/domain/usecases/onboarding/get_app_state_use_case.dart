import '../../entities/app_state.dart';
import '../../repositories/app_state_repository.dart';

class GetAppStateUseCase {
  final AppStateRepository repository;

  GetAppStateUseCase(this.repository);

  Future<AppState> call() {
    return repository.getAppState();
  }
}
