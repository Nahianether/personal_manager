import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class ExcelService {
  static final ExcelService _instance = ExcelService._internal();
  factory ExcelService() => _instance;
  ExcelService._internal();

  final DatabaseService _databaseService = DatabaseService();

  Future<bool> exportToExcel() async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return false;
        }
      }

      // Get all data from database
      final data = await _databaseService.exportAllData();

      // Create Excel workbook
      final excel = Excel.createExcel();

      // Remove default sheet
      excel.delete('Sheet1');

      // Create sheets for each data type
      for (final entry in data.entries) {
        final sheetName = entry.key;
        final rows = entry.value;

        if (rows.isEmpty) continue;

        final sheet = excel[sheetName];

        // Add headers
        final headers = rows.first.keys.toList();
        for (int i = 0; i < headers.length; i++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
          cell.value = TextCellValue(headers[i]);
          cell.cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.blue,
            fontColorHex: ExcelColor.white,
          );
        }

        // Add data rows
        for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
          final row = rows[rowIndex];
          for (int colIndex = 0; colIndex < headers.length; colIndex++) {
            final header = headers[colIndex];
            final value = row[header];
            final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: colIndex,
              rowIndex: rowIndex + 1,
            ));
            
            if (value != null) {
              cell.value = TextCellValue(value.toString());
            }
          }
        }

        // Auto-fit columns
        for (int i = 0; i < headers.length; i++) {
          sheet.setColumnWidth(i, 20.0);
        }
      }

      // Save to Downloads folder
      final directory = await _getDownloadsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'personal_manager_export_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        return true;
      }
      return false;
    } catch (e) {
      // Log error for debugging
      // print('Export error: $e');
      return false;
    }
  }

  Future<bool> importFromExcel() async {
    try {
      // Pick Excel file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final file = File(result.files.first.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final importData = <String, List<Map<String, dynamic>>>{};

      // Process each sheet
      for (final sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName];
        if (sheet == null || sheet.rows.isEmpty) continue;

        final rows = <Map<String, dynamic>>[];
        
        // Get headers from first row
        final headerRow = sheet.rows.first;
        final headers = <String>[];
        for (final cell in headerRow) {
          if (cell?.value != null) {
            headers.add(cell!.value.toString());
          }
        }

        if (headers.isEmpty) continue;

        // Process data rows
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          final rowData = <String, dynamic>{};

          for (int j = 0; j < headers.length && j < row.length; j++) {
            final header = headers[j];
            final cell = row[j];
            
            if (cell?.value != null) {
              final value = cell!.value.toString();
              // Try to convert numeric values
              if (value.isNotEmpty) {
                final numValue = double.tryParse(value);
                if (numValue != null) {
                  rowData[header] = numValue;
                } else {
                  rowData[header] = value;
                }
              }
            }
          }

          if (rowData.isNotEmpty) {
            // Validate required fields for loans
            if (sheetName == 'Loans') {
              if (rowData['amount'] == null || rowData['person_name'] == null || rowData['id'] == null) {
                continue; // Skip rows with missing required fields
              }
            }
            rows.add(rowData);
          }
        }

        if (rows.isNotEmpty) {
          importData[sheetName] = rows;
        }
      }

      // Validate and import data
      if (_validateImportData(importData)) {
        await _databaseService.importAllData(importData);
        return true;
      }

      return false;
    } catch (e) {
      // Log error for debugging
      // print('Import error: $e');
      return false;
    }
  }

  bool _validateImportData(Map<String, List<Map<String, dynamic>>> data) {
    // Validate that essential tables have required columns
    final requiredColumns = {
      'Accounts': ['id', 'name', 'type', 'balance'],
      'Transactions': ['id', 'account_id', 'type', 'amount'],
      'Loans': ['id', 'person_name', 'amount'],
      'Liabilities': ['id', 'name', 'type', 'amount'],
      'Categories': ['id', 'name', 'type'],
    };

    for (final entry in requiredColumns.entries) {
      final tableName = entry.key;
      final required = entry.value;
      
      if (data.containsKey(tableName) && data[tableName]!.isNotEmpty) {
        final firstRow = data[tableName]!.first;
        for (final column in required) {
          if (!firstRow.containsKey(column)) {
            // Log error for debugging
            // print('Missing required column $column in $tableName');
            return false;
          }
        }
      }
    }

    return true;
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // For Android, use external storage Downloads folder
      return Directory('/storage/emulated/0/Download');
    } else {
      // For iOS and other platforms, use documents directory
      return await getApplicationDocumentsDirectory();
    }
  }
}