import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:another_telephony/telephony.dart';
import '../../models/expense.dart';
import '../../models/earning.dart';
import '../../providers/expense_provider.dart';
import '../../providers/earning_provider.dart';
import 'sms_parser.dart';
import 'duplicate_checker.dart';

/// Top-level callback required by the telephony package for background SMS.
@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  debugPrint("📩 Background SMS received: ${message.body}");
  
  // Isolate doesn't share memory with main app, so we must init Hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ExpenseAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(EarningAdapter());
  }
  
  if (!Hive.isBoxOpen('expensesBox')) {
    await Hive.openBox<Expense>('expensesBox');
  }
  if (!Hive.isBoxOpen('earningsBox')) {
    await Hive.openBox<Earning>('earningsBox');
  }
  if (!Hive.isBoxOpen('settingsBox')) {
    await Hive.openBox('settingsBox');
  }

  DateTime? receivedDate;
  if (message.date != null) {
    receivedDate = DateTime.fromMillisecondsSinceEpoch(message.date!);
    _updateLastSyncTime(message.date!);
  }
  await _processSms(
    message.body ?? '',
    ref: null,
    receivedDate: receivedDate,
    sender: message.address,
  );
}

void _updateLastSyncTime(int timestamp) {
  final box = Hive.box('settingsBox');
  final current = box.get('lastSmsSyncTime', defaultValue: 0) as int;
  if (timestamp > current) {
    box.put('lastSmsSyncTime', timestamp);
  }
}

Future<void> _processSms(String body, {WidgetRef? ref, DateTime? receivedDate, String? sender}) async {
  debugPrint("⚙️ Processing SMS from $sender: $body");
  
  try {
    final parsed = SmsParser.parse(body, sender: sender, receivedDate: receivedDate);
    if (parsed == null) {
      debugPrint("❌ SMS ignored: Not a recognized bank expense.");
      return;
    }

    debugPrint("✅ Parsed successfully: $parsed");

    if (parsed.type == TransactionType.expense) {
      final box = Hive.box<Expense>('expensesBox');
      final existing = box.values.toList();

      if (DuplicateChecker.isDuplicate(
        existing,
        parsed.amount,
        parsed.merchant,
        parsed.dateTime,
      )) {
        debugPrint("⚠️ Duplicate expense detected. Skipping.");
        return;
      }

      final expense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: parsed.category,
        subCategory: parsed.merchant,
        amount: parsed.amount,
        paymentMethod: parsed.bank,
        date: parsed.dateTime,
        isAuto: true,
        source: 'sms',
      );

      if (ref != null) {
        ref.read(expenseProvider.notifier).addExpense(expense);
        debugPrint("💾 Expense added via Riverpod!");
      } else {
        await box.add(expense);
        debugPrint("💾 Expense saved directly to Hive (Background)!");
      }
    } else {
      // Handle EARNING
      final box = Hive.box<Earning>('earningsBox');
      
      final earning = Earning(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        incomeSource: 'Bank Received',
        amount: parsed.amount,
        receiveMethod: parsed.bank,
        date: parsed.dateTime,
      );

      if (ref != null) {
        ref.read(earningProvider.notifier).addEarning(earning);
        debugPrint("💰 Earning added via Riverpod!");
      } else {
        await box.add(earning);
        debugPrint("💰 Earning saved directly to Hive (Background)!");
      }
    }
  } catch (e, stack) {
    debugPrint("🚨 Error processing SMS: $e\n$stack");
  }
}

/// Main SMS service — call [init] once from main.dart.
class SmsService {
  SmsService._();
  static final _telephony = Telephony.instance;

  /// Initialize and request permissions. Returns true if granted.
  static Future<bool> init(WidgetRef ref) async {
    final granted = await _telephony.requestSmsPermissions ?? false;
    if (!granted) return false;

    // Ensure boxes are open
    if (!Hive.isBoxOpen('settingsBox')) await Hive.openBox('settingsBox');
    if (!Hive.isBoxOpen('expensesBox')) await Hive.openBox<Expense>('expensesBox');
    if (!Hive.isBoxOpen('earningsBox')) await Hive.openBox<Earning>('earningsBox');

    // Sync missed messages first
    await syncInbox(ref);

    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        DateTime? receivedDate;
        if (message.date != null) {
          receivedDate = DateTime.fromMillisecondsSinceEpoch(message.date!);
          _updateLastSyncTime(message.date!);
        }
        _processSms(
          message.body ?? '',
          ref: ref,
          receivedDate: receivedDate,
          sender: message.address,
        );
      },
      onBackgroundMessage: backgroundMessageHandler,
    );
    return true;
  }

  /// Fetches inbox and processes any messages since the last sync.
  static Future<void> syncInbox(WidgetRef ref) async {
    debugPrint("🔄 Syncing SMS inbox for missed transactions...");
    final box = Hive.box('settingsBox');
    final lastSync = box.get('lastSmsSyncTime', defaultValue: 0) as int;
    
    // If it's the first run, only sync from the last 24 hours to avoid massive data dump
    final startTime = lastSync == 0 
        ? DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch 
        : lastSync;

    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThan(startTime.toString()),
    );

    debugPrint("📥 Found ${messages.length} potential new messages since last sync.");

    for (final message in messages) {
      if (message.date != null) {
        final receivedDate = DateTime.fromMillisecondsSinceEpoch(message.date!);
        await _processSms(
          message.body ?? '',
          ref: ref,
          receivedDate: receivedDate,
          sender: message.address,
        );
        _updateLastSyncTime(message.date!);
      }
    }
  }

  /// Call after user enables the toggle in settings.
  static Future<bool> enable(WidgetRef ref) => init(ref);

  /// Stop listening (called when user disables toggle).
  static void disable() {
    // telephony package doesn't expose a stop method,
    // so we guard via the smsAutoTrackingProvider boolean.
  }
}
