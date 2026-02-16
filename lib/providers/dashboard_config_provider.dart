import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_config.dart';

class DashboardConfigState {
  final DashboardConfig config;
  final bool isLoaded;

  DashboardConfigState({
    required this.config,
    this.isLoaded = false,
  });

  DashboardConfigState copyWith({
    DashboardConfig? config,
    bool? isLoaded,
  }) {
    return DashboardConfigState(
      config: config ?? this.config,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class DashboardConfigNotifier extends StateNotifier<DashboardConfigState> {
  DashboardConfigNotifier()
      : super(DashboardConfigState(config: DashboardConfig.defaultConfig())) {
    _loadConfig();
  }

  static const String _configKey = 'dashboard_config';

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_configKey);

    if (jsonString != null) {
      try {
        final config = DashboardConfig.fromJsonString(jsonString);
        state = DashboardConfigState(config: config, isLoaded: true);
      } catch (_) {
        state = DashboardConfigState(
          config: DashboardConfig.defaultConfig(),
          isLoaded: true,
        );
      }
    } else {
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> updateConfig(DashboardConfig config) async {
    state = state.copyWith(config: config);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, config.toJsonString());
  }

  Future<void> toggleSectionVisibility(DashboardSection section) async {
    final updatedSections = state.config.sections.map((s) {
      if (s.section == section) {
        return s.copyWith(isVisible: !s.isVisible);
      }
      return s;
    }).toList();
    await updateConfig(state.config.copyWith(sections: updatedSections));
  }

  Future<void> reorderSections(int oldIndex, int newIndex) async {
    final sections =
        List<DashboardSectionConfig>.from(state.config.sections);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);
    await updateConfig(state.config.copyWith(sections: sections));
  }

  Future<void> resetToDefaults() async {
    await updateConfig(DashboardConfig.defaultConfig());
  }
}

final dashboardConfigProvider =
    StateNotifierProvider<DashboardConfigNotifier, DashboardConfigState>((ref) {
  return DashboardConfigNotifier();
});
