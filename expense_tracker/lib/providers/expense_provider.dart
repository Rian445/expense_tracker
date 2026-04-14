import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';

class ExpenseNotifier extends Notifier<List<Expense>> {
  @override
  List<Expense> build() {
    final box = Hive.box<Expense>('expensesBox');
    return box.values.toList();
  }

  void addExpense(Expense expense) {
    final box = Hive.box<Expense>('expensesBox');
    box.add(expense);
    state = [...state, expense];
  }
}

final expenseProvider = NotifierProvider<ExpenseNotifier, List<Expense>>(() {
  return ExpenseNotifier();
});
