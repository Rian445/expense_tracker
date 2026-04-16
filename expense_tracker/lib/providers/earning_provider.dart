import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/earning.dart';

class EarningNotifier extends Notifier<List<Earning>> {
  @override
  List<Earning> build() {
    final box = Hive.box<Earning>('earningsBox');
    return box.values.toList();
  }

  void addEarning(Earning earning) {
    final box = Hive.box<Earning>('earningsBox');
    box.add(earning);
    state = [...state, earning];
  }
}

final earningProvider = NotifierProvider<EarningNotifier, List<Earning>>(() {
  return EarningNotifier();
});
