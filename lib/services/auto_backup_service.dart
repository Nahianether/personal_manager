import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'backup_service.dart';

enum BackupFrequency { daily, weekly }

class AutoBackupConfig {
  final bool enabled;
  final BackupFrequency frequency;
  final DateTime? lastBackupTime;
  final String? lastBackupPath;

  AutoBackupConfig({
    this.enabled = false,
    this.frequency = BackupFrequency.daily,
    this.lastBackupTime,
    this.lastBackupPath,
  });

  AutoBackupConfig copyWith({
    bool? enabled,
    BackupFrequency? frequency,
    DateTime? lastBackupTime,
    String? lastBackupPath,
  }) {
    return AutoBackupConfig(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      lastBackupPath: lastBackupPath ?? this.lastBackupPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'frequency': frequency.name,
        'lastBackupTime': lastBackupTime?.toIso8601String(),
        'lastBackupPath': lastBackupPath,
      };

  factory AutoBackupConfig.fromJson(Map<String, dynamic> json) {
    return AutoBackupConfig(
      enabled: json['enabled'] ?? false,
      frequency: BackupFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => BackupFrequency.daily,
      ),
      lastBackupTime: json['lastBackupTime'] != null
          ? DateTime.tryParse(json['lastBackupTime'])
          : null,
      lastBackupPath: json['lastBackupPath'],
    );
  }
}

class AutoBackupService {
  static final AutoBackupService _instance = AutoBackupService._internal();
  factory AutoBackupService() => _instance;
  AutoBackupService._internal();

  static const String _configKey = 'auto_backup_config';
  static const String _uniqueTaskName = 'com.personalmanager.autobackup';

  Future<AutoBackupConfig> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_configKey);
    if (jsonStr == null) return AutoBackupConfig();
    try {
      return AutoBackupConfig.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return AutoBackupConfig();
    }
  }

  Future<void> saveConfig(AutoBackupConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
  }

  Future<void> enableAutoBackup(BackupFrequency frequency) async {
    // Cancel any existing task first
    await Workmanager().cancelByUniqueName(_uniqueTaskName);

    final freq = frequency == BackupFrequency.daily
        ? const Duration(hours: 24)
        : const Duration(days: 7);

    await Workmanager().registerPeriodicTask(
      _uniqueTaskName,
      'auto_backup',
      frequency: freq,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
      ),
    );

    final config = await getConfig();
    await saveConfig(config.copyWith(enabled: true, frequency: frequency));
  }

  Future<void> disableAutoBackup() async {
    await Workmanager().cancelByUniqueName(_uniqueTaskName);
    final config = await getConfig();
    await saveConfig(config.copyWith(enabled: false));
  }

  /// Called by the workmanager callback dispatcher in an isolate.
  static Future<bool> performAutoBackup() async {
    try {
      final backupService = BackupService();
      final filePath = await backupService.exportBackup();
      if (filePath != null) {
        // Update config with last backup info
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString(_configKey);
        AutoBackupConfig config;
        if (jsonStr != null) {
          try {
            config = AutoBackupConfig.fromJson(jsonDecode(jsonStr));
          } catch (_) {
            config = AutoBackupConfig();
          }
        } else {
          config = AutoBackupConfig();
        }
        final updated = config.copyWith(
          lastBackupTime: DateTime.now(),
          lastBackupPath: filePath,
        );
        await prefs.setString(_configKey, jsonEncode(updated.toJson()));
        return true;
      }
      return false;
    } catch (e) {
      print('Auto-backup failed: $e');
      return false;
    }
  }
}

/// Top-level callback for workmanager. Must be a top-level or static function.
@pragma('vm:entry-point')
void autoBackupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return await AutoBackupService.performAutoBackup();
  });
}
