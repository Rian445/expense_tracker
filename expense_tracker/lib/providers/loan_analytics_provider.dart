import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'loan_provider.dart';
import '../models/loan.dart';

enum LoanAnalyticsTimeframe { weekly, monthly, yearly }

class LoanTimeframeNotifier extends Notifier<LoanAnalyticsTimeframe> {
  @override
  LoanAnalyticsTimeframe build() => LoanAnalyticsTimeframe.monthly;
  
  void set(LoanAnalyticsTimeframe value) => state = value;
}

final loanAnalyticsTimeframeProvider = NotifierProvider<LoanTimeframeNotifier, LoanAnalyticsTimeframe>(LoanTimeframeNotifier.new);

final filteredLoansProvider = Provider((ref) {
  final timeframe = ref.watch(loanAnalyticsTimeframeProvider);
  final loans = ref.watch(loanProvider);
  final now = DateTime.now();

  return loans.where((e) {
    if (timeframe == LoanAnalyticsTimeframe.weekly) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
    } else if (timeframe == LoanAnalyticsTimeframe.monthly) {
      return e.date.year == now.year && e.date.month == now.month;
    } else {
      return e.date.year == now.year;
    }
  }).toList();
});

final loanCategoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final loans = ref.watch(filteredLoansProvider);
  final Map<String, double> totals = {};
  for (var e in loans) {
    totals[e.purpose] = (totals[e.purpose] ?? 0) + e.amount;
  }
  return totals;
});

class GroupedLoan {
  final String label;
  final double amount;
  final int count;
  final List<Loan> items;
  final List<GroupedLoan>? children;

  GroupedLoan({
    required this.label,
    required this.amount,
    required this.count,
    required this.items,
    this.children,
  });
}

final groupedLoanActivityProvider = Provider<List<GroupedLoan>>((ref) {
  final timeframe = ref.watch(loanAnalyticsTimeframeProvider);
  final allLoans = ref.watch(loanProvider);
  
  if (allLoans.isEmpty) return [];

  List<GroupedLoan> buildGroups(List<Loan> loans, String format, {List<GroupedLoan> Function(List<Loan>)? childBuilder}) {
    final Map<String, List<Loan>> groups = {};
    for (var e in loans) {
      final label = DateFormat(format).format(e.date);
      groups[label] = (groups[label] ?? [])..add(e);
    }
    
    final sortedKeys = groups.keys.toList();
    
    return sortedKeys.map((label) {
      final groupItems = groups[label]!;
      final amount = groupItems.fold(0.0, (sum, e) => sum + e.amount);
      return GroupedLoan(
        label: label,
        amount: amount,
        count: groupItems.length,
        items: groupItems,
        children: childBuilder?.call(groupItems),
      );
    }).toList();
  }

  if (timeframe == LoanAnalyticsTimeframe.yearly) {
    return buildGroups(allLoans, 'yyyy', childBuilder: (yearItems) {
      return buildGroups(yearItems, 'MMMM', childBuilder: (monthItems) {
        return buildGroups(monthItems, 'MMM dd');
      });
    });
  } else if (timeframe == LoanAnalyticsTimeframe.monthly) {
    final now = DateTime.now();
    final monthLoans = allLoans.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    return buildGroups(monthLoans, 'MMMM yyyy', childBuilder: (monthItems) {
      return buildGroups(monthItems, 'MMM dd');
    });
  } else {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekLoans = allLoans.where((e) => e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))).toList();
    return buildGroups(weekLoans, 'EEEE');
  }
});

final filteredLoanTotalProvider = Provider<double>((ref) {
  final loans = ref.watch(filteredLoansProvider);
  return loans.fold(0.0, (sum, e) => sum + e.amount);
});

final allTimeLoanTotalProvider = Provider<double>((ref) {
  final loans = ref.watch(loanProvider);
  return loans.fold(0.0, (sum, e) => sum + e.amount);
});

final loanTimeframeTrendProvider = Provider<Map<String, Map<String, double>>>((ref) {
  final timeframe = ref.watch(loanAnalyticsTimeframeProvider);
  final loans = ref.watch(loanProvider);
  final now = DateTime.now();
  final Map<String, Map<String, double>> trend = {};

  if (timeframe == LoanAnalyticsTimeframe.weekly) {
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final Map<String, double> weekDays = {};
    for (var i = 0; i < 7; i++) {
       final day = startOfWeek.add(Duration(days: i));
       final label = DateFormat('E').format(day);
       weekDays[label] = 0.0;
    }
    for (var e in loans) {
      if (e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
        final label = DateFormat('E').format(e.date);
        if (weekDays.containsKey(label)) {
          weekDays[label] = (weekDays[label] ?? 0) + e.amount;
        }
      }
    }
    trend['Current Week'] = weekDays;
  } else if (timeframe == LoanAnalyticsTimeframe.monthly) {
    for (var w = 0; w < 5; w++) {
      final weekLabel = 'Week ${w + 1}';
      final Map<String, double> daysInWeek = {for(var d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) d: 0.0};
      trend[weekLabel] = daysInWeek;
    }
    for (var e in loans) {
      if (e.date.year == now.year && e.date.month == now.month) {
        final weekNum = ((e.date.day - 1) / 7).floor();
        if (weekNum < 5) {
          final weekLabel = 'Week ${weekNum + 1}';
          final dayLabel = DateFormat('E').format(e.date);
          trend[weekLabel]![dayLabel] = (trend[weekLabel]![dayLabel] ?? 0) + e.amount;
        }
      }
    }
  } else {
    final targetYears = [(now.year - 2).toString(), (now.year - 1).toString(), now.year.toString()];
    for (var year in targetYears) {
      trend[year] = {for (var m = 1; m <= 12; m++) DateFormat('MMM').format(DateTime(now.year, m)): 0.0};
    }
    for (var e in loans) {
      final yearStr = e.date.year.toString();
      if (trend.containsKey(yearStr)) {
        final monthLabel = DateFormat('MMM').format(e.date);
        trend[yearStr]![monthLabel] = (trend[yearStr]![monthLabel] ?? 0) + e.amount;
      }
    }
  }
  return trend;
});
