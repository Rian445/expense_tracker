import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/expense.dart';
import 'models/earning.dart';
import 'models/loan.dart';
import 'screens/app_shell.dart';
import 'core/constants/app_theme.dart';
import 'providers/theme_provider.dart';

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // ── Secure Encryption Setup ───────────────────────────────────────────
  const secureStorage = FlutterSecureStorage();
  final encryptionKeyString = await secureStorage.read(key: 'db_key');
  final List<int> encryptionKey;
  
  if (encryptionKeyString == null) {
    final key = Hive.generateSecureKey();
    await secureStorage.write(key: 'db_key', value: base64UrlEncode(key));
    encryptionKey = key;
  } else {
    encryptionKey = base64Url.decode(encryptionKeyString);
  }
  
  final cipher = HiveAesCipher(encryptionKey);
  // ───────────────────────────────────────────────────────────────────────

  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(EarningAdapter());
  Hive.registerAdapter(LoanAdapter());
  
  await Hive.openBox<Expense>('expensesBox', encryptionCipher: cipher);
  await Hive.openBox<Earning>('earningsBox', encryptionCipher: cipher);
  await Hive.openBox<Loan>('loansBox', encryptionCipher: cipher);
  await Hive.openBox('settingsBox', encryptionCipher: cipher);
  await Hive.openBox('categoriesBox', encryptionCipher: cipher);
  await Hive.openBox('loanCategoriesBox', encryptionCipher: cipher);
  
  runApp(
    const ProviderScope(
      child: ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Expense Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}
