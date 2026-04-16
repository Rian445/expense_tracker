import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/expense.dart';

class BackupService {
  static Future<void> exportBackup() async {
    try {
      final expensesBox = Hive.box<Expense>('expensesBox');
      final settingsBox = Hive.box('settings');
      final categoriesBox = Hive.box('categoriesBox');

      final List<Map<String, dynamic>> expenses = expensesBox.values.map((e) => e.toMap()).toList();
      
      final Map<String, dynamic> settings = {};
      for (var key in settingsBox.keys) {
        settings[key.toString()] = settingsBox.get(key);
      }
      
      final Map<String, dynamic> categories = {};
      for (var key in categoriesBox.keys) {
        final value = categoriesBox.get(key);
        if (value != null) {
          categories[key.toString()] = value;
        }
      }

      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expenses': expenses,
        'settings': settings,
        'categories': categories,
      };

      final jsonString = jsonEncode(backupData);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/expense_tracker_backup.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        text: 'Expense Tracker Backup - ${DateTime.now().toString().split('.')[0]}',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> importBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return false;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      if (backupData['expenses'] == null) throw Exception('Invalid backup file');

      final expensesBox = Hive.box<Expense>('expensesBox');
      final settingsBox = Hive.box('settings');
      final categoriesBox = Hive.box('categoriesBox');

      // Clear current boxes
      await expensesBox.clear();
      await settingsBox.clear();
      await categoriesBox.clear();

      // Restore expenses
      final List<dynamic> expensesList = backupData['expenses'];
      for (var item in expensesList) {
        final expense = Expense.fromMap(Map<String, dynamic>.from(item));
        await expensesBox.add(expense);
      }

      // Restore settings
      if (backupData['settings'] != null) {
        final Map<String, dynamic> settingsMap = Map<String, dynamic>.from(backupData['settings']);
        for (var entry in settingsMap.entries) {
          await settingsBox.put(entry.key, entry.value);
        }
      }

      // Restore categories
      if (backupData['categories'] != null) {
        final Map<String, dynamic> categoriesMap = Map<String, dynamic>.from(backupData['categories']);
        for (var entry in categoriesMap.entries) {
          await categoriesBox.put(entry.key, entry.value);
        }
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }
}
