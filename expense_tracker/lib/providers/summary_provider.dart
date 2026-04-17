import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'expense_provider.dart';
import 'earning_provider.dart';
import 'loan_provider.dart';

class FinancialSummary {
  final double totalEarnings;
  final double totalExpenses;
  final double totalLoans;
  final double netBalance;
  final double savingsRate; // (Earnings - Expenses) / Earnings * 100
  final bool isInDebt;

  FinancialSummary({
    required this.totalEarnings,
    required this.totalExpenses,
    required this.totalLoans,
    required this.netBalance,
    required this.savingsRate,
    required this.isInDebt,
  });
}

final summaryProvider = Provider<FinancialSummary>((ref) {
  final expenses = ref.watch(expenseProvider);
  final earnings = ref.watch(earningProvider);
  final loans = ref.watch(loanProvider);

  final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);
  final totalEarnings = earnings.fold(0.0, (sum, e) => sum + e.amount);
  final totalLoans = loans.fold(0.0, (sum, l) => sum + l.amount);

  final netBalance = totalEarnings - totalExpenses;
  final isInDebt = netBalance < 0;
  
  double savingsRate = 0;
  if (totalEarnings > 0) {
    savingsRate = ((totalEarnings - totalExpenses) / totalEarnings) * 100;
  }

  return FinancialSummary(
    totalEarnings: totalEarnings,
    totalExpenses: totalExpenses,
    totalLoans: totalLoans,
    netBalance: netBalance,
    savingsRate: savingsRate,
    isInDebt: isInDebt,
  );
});
