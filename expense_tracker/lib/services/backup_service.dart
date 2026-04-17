import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../models/expense.dart';
import '../models/earning.dart';
import '../models/loan.dart';

class BackupService {
  static Future<void> exportBackup(String password) async {
    try {
      final expensesBox = Hive.box<Expense>('expensesBox');
      final earningsBox = Hive.box<Earning>('earningsBox');
      final loansBox = Hive.box<Loan>('loansBox');
      final settingsBox = Hive.box('settingsBox');
      final categoriesBox = Hive.box('categoriesBox');

      final List<Map<String, dynamic>> expenses = expensesBox.values.map((e) => e.toMap()).toList();
      final List<Map<String, dynamic>> earnings = earningsBox.values.map((e) => e.toMap()).toList();
      final List<Map<String, dynamic>> loans = loansBox.values.map((e) => e.toMap()).toList();
      
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
        'version': 2,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expenses': expenses,
        'earnings': earnings,
        'loans': loans,
        'settings': settings,
        'categories': categories,
      };

      final jsonString = jsonEncode(backupData);
      
      // ── AES-256 Encryption with User Password ──────────────────────────────
      final keyHash = sha256.convert(utf8.encode(password)).bytes;
      final key = enc.Key(Uint8List.fromList(keyHash));
      final iv = enc.IV.fromLength(16);
      final encrypter = enc.Encrypter(enc.AES(key));
      
      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      final finalData = '${iv.base64}.${encrypted.base64}'; // Combine IV and data
      // ───────────────────────────────────────────────────────────────────────

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/expense_tracker_vault.etv');
      await file.writeAsString(finalData);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/octet-stream')],
        text: 'Expense Tracker Secure Vault - ${DateTime.now().toString().split('.')[0]}',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<File?> pickBackupFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result == null || result.files.single.path == null) return null;
    return File(result.files.single.path!);
  }

  static Future<bool> importBackup(File file, String password) async {
    try {
      final rawData = await file.readAsString();
      
      // ── AES-256 Decryption with User Password ──────────────────────────────
      final parts = rawData.split('.');
      if (parts.length != 2) throw Exception('Invalid vault file format');
      
      final keyHash = sha256.convert(utf8.encode(password)).bytes;
      final key = enc.Key(Uint8List.fromList(keyHash));
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      final encrypter = enc.Encrypter(enc.AES(key));
      
      final jsonString = encrypter.decrypt(encrypted, iv: iv);
      // ───────────────────────────────────────────────────────────────────────

      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      if (backupData['expenses'] == null) throw Exception('Invalid backup data');

      final expensesBox = Hive.box<Expense>('expensesBox');
      final settingsBox = Hive.box('settingsBox');
      final categoriesBox = Hive.box('categoriesBox');
      final earningsBox = Hive.box<Earning>('earningsBox');
      final loansBox = Hive.box<Loan>('loansBox');

      // Clear current boxes
      await expensesBox.clear();
      await earningsBox.clear();
      await loansBox.clear();
      await settingsBox.clear();
      await categoriesBox.clear();

      // Restore expenses
      final List<dynamic> expensesList = backupData['expenses'];
      for (var item in expensesList) {
        final expense = Expense.fromMap(Map<String, dynamic>.from(item));
        await expensesBox.add(expense);
      }

      // Restore earnings (if they exist in backup compatible with version 2)
      if (backupData['earnings'] != null) {
        final List<dynamic> earningsList = backupData['earnings'];
        for (var item in earningsList) {
          final earning = Earning.fromMap(Map<String, dynamic>.from(item));
          await earningsBox.add(earning);
        }
      }

      // Restore loans
      if (backupData['loans'] != null) {
        final List<dynamic> loansList = backupData['loans'];
        for (var item in loansList) {
          final loan = Loan.fromMap(Map<String, dynamic>.from(item));
          await loansBox.add(loan);
        }
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
