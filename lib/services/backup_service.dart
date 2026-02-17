import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _databaseService = DatabaseService();
  static const int _backupVersion = 1;

  // ─── JSON Backup Export ───

  Future<String?> exportBackup() async {
    try {
      final data = await _databaseService.exportAllData();
      final backup = {
        'version': _backupVersion,
        'appVersion': '1.0.0',
        'createdAt': DateTime.now().toIso8601String(),
        'data': data,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/personal_manager_backup_$timestamp.json';

      final file = File(filePath);
      await file.writeAsString(jsonString);
      return filePath;
    } catch (e) {
      print('Backup export error: $e');
      return null;
    }
  }

  /// Save backup to a user-chosen directory via file_picker
  Future<String?> saveBackupToLocation() async {
    try {
      final data = await _databaseService.exportAllData();
      final backup = {
        'version': _backupVersion,
        'appVersion': '1.0.0',
        'createdAt': DateTime.now().toIso8601String(),
        'data': data,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose backup save location',
      );

      if (selectedDirectory == null) return null;

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath =
          '$selectedDirectory/personal_manager_backup_$timestamp.json';

      final file = File(filePath);
      await file.writeAsString(jsonString);
      return filePath;
    } catch (e) {
      print('Backup save-to-location error: $e');
      return null;
    }
  }

  Future<void> shareBackup(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Personal Manager Backup',
    );
  }

  // ─── JSON Backup Restore ───

  Future<bool> restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return false;

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup structure
      if (!_validateBackup(backup)) return false;

      final rawData = backup['data'] as Map<String, dynamic>;
      final data = <String, List<Map<String, dynamic>>>{};

      for (final entry in rawData.entries) {
        final rows = (entry.value as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        data[entry.key] = rows;
      }

      await _databaseService.importAllDataV2(data);
      return true;
    } catch (e) {
      print('Backup restore error: $e');
      return false;
    }
  }

  bool _validateBackup(Map<String, dynamic> backup) {
    if (!backup.containsKey('version') || !backup.containsKey('data')) {
      return false;
    }
    final version = backup['version'];
    if (version is! int || version < 1) return false;

    final data = backup['data'];
    if (data is! Map) return false;

    return true;
  }

  // ─── CSV Import ───

  Future<Map<String, dynamic>> importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return {'success': false, 'error': 'No file selected'};
      }

      final file = File(result.files.first.path!);
      final csvString = await file.readAsString();
      final rows = const CsvToListConverter(eol: '\n').convert(csvString);

      if (rows.isEmpty) {
        return {'success': false, 'error': 'CSV file is empty'};
      }

      // Get headers from first row
      final headers = rows.first.map((h) => h.toString().toLowerCase().trim()).toList();

      if (headers.length < 2) {
        return {'success': false, 'error': 'CSV must have at least 2 columns'};
      }

      final dataRows = rows.sublist(1);
      if (dataRows.isEmpty) {
        return {'success': false, 'error': 'CSV has no data rows'};
      }

      // Auto-detect type based on headers
      if (_hasColumns(headers, ['account_id', 'type', 'amount'])) {
        return await _importTransactionsCsv(headers, dataRows);
      } else if (_hasColumns(headers, ['name', 'type', 'balance'])) {
        return await _importAccountsCsv(headers, dataRows);
      } else if (_hasColumns(headers, ['amount'])) {
        // Generic: try as transactions with whatever columns are available
        return await _importGenericTransactionsCsv(headers, dataRows);
      }

      return {
        'success': false,
        'error': 'Unrecognized CSV format. Expected columns like: amount, date, category, description',
      };
    } catch (e) {
      print('CSV import error: $e');
      return {'success': false, 'error': 'Failed to parse CSV: $e'};
    }
  }

  bool _hasColumns(List<String> headers, List<String> required) {
    return required.every((col) => headers.contains(col));
  }

  Future<Map<String, dynamic>> _importTransactionsCsv(
    List<String> headers,
    List<List<dynamic>> dataRows,
  ) async {
    final db = await _databaseService.database;
    int imported = 0;
    int skipped = 0;
    const uuid = Uuid();

    for (final row in dataRows) {
      try {
        final map = _rowToMap(headers, row);
        final amount = double.tryParse(map['amount']?.toString() ?? '');
        if (amount == null) {
          skipped++;
          continue;
        }

        await db.insert('transactions', {
          'id': map['id'] ?? uuid.v4(),
          'user_id': map['user_id'] ?? '',
          'account_id': map['account_id'] ?? '',
          'type': map['type'] ?? 'expense',
          'amount': amount,
          'currency': map['currency'] ?? 'BDT',
          'category': map['category'],
          'description': map['description'],
          'date': map['date'] ?? DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
        });
        imported++;
      } catch (e) {
        skipped++;
      }
    }

    return {
      'success': true,
      'imported': imported,
      'skipped': skipped,
      'type': 'transactions',
    };
  }

  Future<Map<String, dynamic>> _importAccountsCsv(
    List<String> headers,
    List<List<dynamic>> dataRows,
  ) async {
    final db = await _databaseService.database;
    int imported = 0;
    int skipped = 0;
    const uuid = Uuid();

    for (final row in dataRows) {
      try {
        final map = _rowToMap(headers, row);
        final balance = double.tryParse(map['balance']?.toString() ?? '');
        if (balance == null || map['name'] == null) {
          skipped++;
          continue;
        }

        await db.insert('accounts', {
          'id': map['id'] ?? uuid.v4(),
          'user_id': map['user_id'] ?? '',
          'name': map['name'],
          'type': map['type'] ?? 'bank',
          'balance': balance,
          'currency': map['currency'] ?? 'BDT',
          'credit_limit': double.tryParse(map['credit_limit']?.toString() ?? ''),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
        });
        imported++;
      } catch (e) {
        skipped++;
      }
    }

    return {
      'success': true,
      'imported': imported,
      'skipped': skipped,
      'type': 'accounts',
    };
  }

  Future<Map<String, dynamic>> _importGenericTransactionsCsv(
    List<String> headers,
    List<List<dynamic>> dataRows,
  ) async {
    final db = await _databaseService.database;
    int imported = 0;
    int skipped = 0;
    const uuid = Uuid();

    // Map common column name variations
    final amountIdx = _findColumnIndex(headers, ['amount', 'value', 'sum', 'total']);
    if (amountIdx == -1) {
      return {'success': false, 'error': 'No amount column found'};
    }

    final dateIdx = _findColumnIndex(headers, ['date', 'datetime', 'time', 'timestamp']);
    final categoryIdx = _findColumnIndex(headers, ['category', 'type', 'group']);
    final descIdx = _findColumnIndex(headers, ['description', 'desc', 'note', 'notes', 'memo', 'name']);

    for (final row in dataRows) {
      try {
        final amount = double.tryParse(row[amountIdx].toString().replaceAll(RegExp(r'[^\d.\-]'), ''));
        if (amount == null) {
          skipped++;
          continue;
        }

        String? dateStr;
        if (dateIdx != -1 && dateIdx < row.length) {
          dateStr = _parseDate(row[dateIdx].toString());
        }

        await db.insert('transactions', {
          'id': uuid.v4(),
          'user_id': '',
          'account_id': '',
          'type': amount >= 0 ? 'income' : 'expense',
          'amount': amount.abs(),
          'currency': 'BDT',
          'category': categoryIdx != -1 && categoryIdx < row.length ? row[categoryIdx].toString() : null,
          'description': descIdx != -1 && descIdx < row.length ? row[descIdx].toString() : null,
          'date': dateStr ?? DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
        });
        imported++;
      } catch (e) {
        skipped++;
      }
    }

    return {
      'success': true,
      'imported': imported,
      'skipped': skipped,
      'type': 'transactions',
    };
  }

  int _findColumnIndex(List<String> headers, List<String> candidates) {
    for (final candidate in candidates) {
      final idx = headers.indexOf(candidate);
      if (idx != -1) return idx;
    }
    return -1;
  }

  Map<String, dynamic> _rowToMap(List<String> headers, List<dynamic> row) {
    final map = <String, dynamic>{};
    for (int i = 0; i < headers.length && i < row.length; i++) {
      map[headers[i]] = row[i]?.toString();
    }
    return map;
  }

  String? _parseDate(String input) {
    // Try common date formats
    final formats = [
      'yyyy-MM-dd',
      'yyyy-MM-dd HH:mm:ss',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'dd-MM-yyyy',
      'yyyy/MM/dd',
    ];

    for (final fmt in formats) {
      try {
        final date = DateFormat(fmt).parseStrict(input);
        return date.toIso8601String();
      } catch (_) {}
    }

    // Try ISO 8601
    final parsed = DateTime.tryParse(input);
    if (parsed != null) return parsed.toIso8601String();

    return null;
  }
}
