import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void toggleSection(String sectionKey) {
    if (state.expandedSection == sectionKey) {
      emit(state.copyWith(expandedSection: null));
    } else {
      emit(state.copyWith(expandedSection: sectionKey));
    }
  }
}
