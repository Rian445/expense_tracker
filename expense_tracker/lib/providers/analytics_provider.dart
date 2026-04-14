import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'expense_provider.dart';

final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(expenseProvider);
  final Map<String, double> totals = {};
  for (var e in expenses) {
    totals[e.category] = (totals[e.category] ?? 0) + e.amount;
  }
  return totals;
});

final subcategoryTotalsProvider = Provider.family<Map<String, double>, String>((ref, category) {
  final expenses = ref.watch(expenseProvider);
  final Map<String, double> totals = {};
  for (var e in expenses.where((e) => e.category == category && e.subCategory != null)) {
    totals[e.subCategory!] = (totals[e.subCategory!] ?? 0) + e.amount;
  }
  return totals;
});

final dailyTotalsProvider = Provider<Map<DateTime, double>>((ref) {
  final expenses = ref.watch(expenseProvider);
  final Map<DateTime, double> totals = {};
  for (var e in expenses) {
    final date = DateTime(e.date.year, e.date.month, e.date.day);
    totals[date] = (totals[date] ?? 0) + e.amount;
  }
  return totals;
});

final monthlyTotalsProvider = Provider<Map<int, double>>((ref) {
  final expenses = ref.watch(expenseProvider);
  final Map<int, double> totals = {};
  for (var e in expenses) {
    final monthKey = e.date.year * 100 + e.date.month;
    totals[monthKey] = (totals[monthKey] ?? 0) + e.amount;
  }
  return totals;
});
