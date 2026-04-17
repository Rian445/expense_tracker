import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum Currency {
  usd(symbol: '\$', code: 'USD'),
  bdt(symbol: '৳', code: 'BDT');

  final String symbol;
  final String code;
  const Currency({required this.symbol, required this.code});
}

final currencyProvider = NotifierProvider<CurrencyNotifier, Currency>(() {
  return CurrencyNotifier();
});

class CurrencyNotifier extends Notifier<Currency> {
  @override
  Currency build() {
    final box = Hive.box('settingsBox');
    final savedCode = box.get('currency', defaultValue: 'USD');
    return Currency.values.firstWhere((c) => c.code == savedCode, orElse: () => Currency.usd);
  }

  void set(Currency currency) {
    state = currency;
    Hive.box('settingsBox').put('currency', currency.code);
  }
}

// ─── SMS Auto-Tracking ────────────────────────────────────────────────────────

final smsAutoTrackingProvider =
    NotifierProvider<SmsAutoTrackingNotifier, bool>(SmsAutoTrackingNotifier.new);

class SmsAutoTrackingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return Hive.box('settingsBox').get('smsAutoTracking', defaultValue: false) as bool;
  }

  void toggle() {
    final newVal = !state;
    state = newVal;
    Hive.box('settingsBox').put('smsAutoTracking', newVal);
  }

  void set(bool value) {
    state = value;
    Hive.box('settingsBox').put('smsAutoTracking', value);
  }
}
