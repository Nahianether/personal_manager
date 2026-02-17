import 'package:flutter_test/flutter_test.dart';
import 'package:personal_manager/services/auto_backup_service.dart';

void main() {
  group('AutoBackupConfig', () {
    test('should create with default values', () {
      final config = AutoBackupConfig();

      expect(config.enabled, false);
      expect(config.frequency, BackupFrequency.daily);
      expect(config.lastBackupTime, isNull);
      expect(config.lastBackupPath, isNull);
    });

    test('should create with custom values', () {
      final now = DateTime(2026, 1, 15);
      final config = AutoBackupConfig(
        enabled: true,
        frequency: BackupFrequency.weekly,
        lastBackupTime: now,
        lastBackupPath: '/path/to/backup.json',
      );

      expect(config.enabled, true);
      expect(config.frequency, BackupFrequency.weekly);
      expect(config.lastBackupTime, now);
      expect(config.lastBackupPath, '/path/to/backup.json');
    });

    test('should serialize to JSON', () {
      final config = AutoBackupConfig(
        enabled: true,
        frequency: BackupFrequency.weekly,
        lastBackupTime: DateTime(2026, 1, 15),
        lastBackupPath: '/backup.json',
      );

      final json = config.toJson();
      expect(json['enabled'], true);
      expect(json['frequency'], 'weekly');
      expect(json['lastBackupTime'], isNotNull);
      expect(json['lastBackupPath'], '/backup.json');
    });

    test('should deserialize from JSON', () {
      final json = {
        'enabled': true,
        'frequency': 'weekly',
        'lastBackupTime': '2026-01-15T00:00:00.000',
        'lastBackupPath': '/backup.json',
      };

      final config = AutoBackupConfig.fromJson(json);
      expect(config.enabled, true);
      expect(config.frequency, BackupFrequency.weekly);
      expect(config.lastBackupTime, DateTime(2026, 1, 15));
      expect(config.lastBackupPath, '/backup.json');
    });

    test('should handle null values in JSON', () {
      final json = {
        'enabled': false,
        'frequency': 'daily',
      };

      final config = AutoBackupConfig.fromJson(json);
      expect(config.enabled, false);
      expect(config.frequency, BackupFrequency.daily);
      expect(config.lastBackupTime, isNull);
      expect(config.lastBackupPath, isNull);
    });

    test('should roundtrip JSON correctly', () {
      final original = AutoBackupConfig(
        enabled: true,
        frequency: BackupFrequency.daily,
        lastBackupTime: DateTime(2026, 2, 10, 14, 30),
        lastBackupPath: '/documents/backup_2026.json',
      );

      final json = original.toJson();
      final restored = AutoBackupConfig.fromJson(json);

      expect(restored.enabled, original.enabled);
      expect(restored.frequency, original.frequency);
      expect(restored.lastBackupPath, original.lastBackupPath);
    });

    test('should copyWith correctly', () {
      final config = AutoBackupConfig(
        enabled: false,
        frequency: BackupFrequency.daily,
      );

      final updated = config.copyWith(
        enabled: true,
        frequency: BackupFrequency.weekly,
      );

      expect(updated.enabled, true);
      expect(updated.frequency, BackupFrequency.weekly);
    });

    test('should preserve unmodified fields in copyWith', () {
      final config = AutoBackupConfig(
        enabled: true,
        frequency: BackupFrequency.weekly,
        lastBackupPath: '/path.json',
      );

      final updated = config.copyWith(enabled: false);

      expect(updated.enabled, false);
      expect(updated.frequency, BackupFrequency.weekly);
      expect(updated.lastBackupPath, '/path.json');
    });
  });

  group('BackupFrequency', () {
    test('should have 2 frequencies', () {
      expect(BackupFrequency.values.length, 2);
    });

    test('should contain daily and weekly', () {
      expect(BackupFrequency.values, contains(BackupFrequency.daily));
      expect(BackupFrequency.values, contains(BackupFrequency.weekly));
    });
  });
}
