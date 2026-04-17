import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/loan.dart';

class LoanNotifier extends Notifier<List<Loan>> {
  @override
  List<Loan> build() {
    final box = Hive.box<Loan>('loansBox');
    return box.values.toList();
  }

  void addLoan(Loan loan) {
    final box = Hive.box<Loan>('loansBox');
    box.add(loan);
    state = [...state, loan];
  }
}

final loanProvider = NotifierProvider<LoanNotifier, List<Loan>>(() {
  return LoanNotifier();
});
