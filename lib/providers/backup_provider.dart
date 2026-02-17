import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auto_backup_service.dart';

class BackupState {
  final AutoBackupConfig config;
  final bool isBackingUp;
  final String? lastError;

  BackupState({
    required this.config,
    this.isBackingUp = false,
    this.lastError,
  });

  BackupState copyWith({
    AutoBackupConfig? config,
    bool? isBackingUp,
    String? lastError,
  }) {
    return BackupState(
      config: config ?? this.config,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      lastError: lastError ?? this.lastError,
    );
  }
}

class BackupNotifier extends StateNotifier<BackupState> {
  final AutoBackupService _service = AutoBackupService();

  BackupNotifier() : super(BackupState(config: AutoBackupConfig())) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _service.getConfig();
    state = state.copyWith(config: config);
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    try {
      if (enabled) {
        await _service.enableAutoBackup(state.config.frequency);
      } else {
        await _service.disableAutoBackup();
      }
      final config = await _service.getConfig();
      state = state.copyWith(config: config, lastError: null);
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
    }
  }

  Future<void> setFrequency(BackupFrequency frequency) async {
    try {
      final config = state.config.copyWith(frequency: frequency);
      await _service.saveConfig(config);
      if (config.enabled) {
        await _service.enableAutoBackup(frequency);
      }
      state = state.copyWith(config: config, lastError: null);
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
    }
  }

  Future<void> refreshConfig() async {
    await _loadConfig();
  }
}

final backupProvider =
    StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  return BackupNotifier();
});
