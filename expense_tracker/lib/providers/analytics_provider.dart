import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'expense_provider.dart';
import '../models/expense.dart';

enum AnalyticsTimeframe { weekly, monthly, yearly }

class TimeframeNotifier extends Notifier<AnalyticsTimeframe> {
  @override
  AnalyticsTimeframe build() => AnalyticsTimeframe.monthly;
  
  void set(AnalyticsTimeframe value) => state = value;
}

final analyticsTimeframeProvider = NotifierProvider<TimeframeNotifier, AnalyticsTimeframe>(TimeframeNotifier.new);

final filteredExpensesProvider = Provider((ref) {
  final timeframe = ref.watch(analyticsTimeframeProvider);
  final expenses = ref.watch(expenseProvider);
  final now = DateTime.now();

  return expenses.where((e) {
    if (timeframe == AnalyticsTimeframe.weekly) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
    } else if (timeframe == AnalyticsTimeframe.monthly) {
      return e.date.year == now.year && e.date.month == now.month;
    } else {
      return e.date.year == now.year;
    }
  }).toList();
});

final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
  final Map<String, double> totals = {};
  for (var e in expenses) {
    totals[e.category] = (totals[e.category] ?? 0) + e.amount;
  }
  return totals;
});

class GroupedExpense {
  final String label;
  final double amount;
  final int count;
  final List<Expense> items;
  final List<GroupedExpense>? children;

  GroupedExpense({
    required this.label,
    required this.amount,
    required this.count,
    required this.items,
    this.children,
  });
}

final groupedActivityProvider = Provider<List<GroupedExpense>>((ref) {
  final timeframe = ref.watch(analyticsTimeframeProvider);
  final allExpenses = ref.watch(expenseProvider);
  
  if (allExpenses.isEmpty) return [];

  // Helper to group by a specific date format
  List<GroupedExpense> buildGroups(List<Expense> expenses, String format, {List<GroupedExpense> Function(List<Expense>)? childBuilder}) {
    final Map<String, List<Expense>> groups = {};
    for (var e in expenses) {
      final label = DateFormat(format).format(e.date);
      groups[label] = (groups[label] ?? [])..add(e);
    }
    
    // Sort groups logically (e.g., chronologically if possible)
    final sortedKeys = groups.keys.toList();
    
    return sortedKeys.map((label) {
      final groupItems = groups[label]!;
      final amount = groupItems.fold(0.0, (sum, e) => sum + e.amount);
      return GroupedExpense(
        label: label,
        amount: amount,
        count: groupItems.length,
        items: groupItems,
        children: childBuilder?.call(groupItems),
      );
    }).toList();
  }

  if (timeframe == AnalyticsTimeframe.yearly) {
    // Level 1: Year
    return buildGroups(allExpenses, 'yyyy', childBuilder: (yearItems) {
      // Level 2: Month
      return buildGroups(yearItems, 'MMMM', childBuilder: (monthItems) {
        // Level 3: Date
        return buildGroups(monthItems, 'MMM dd');
      });
    });
  } else if (timeframe == AnalyticsTimeframe.monthly) {
    // Start with current month's expenses
    final now = DateTime.now();
    final monthExpenses = allExpenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    // Level 1: Month
    return buildGroups(monthExpenses, 'MMMM yyyy', childBuilder: (monthItems) {
      // Level 2: Date
      return buildGroups(monthItems, 'MMM dd');
    });
  } else {
    // Weekly
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekExpenses = allExpenses.where((e) => e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))).toList();
    return buildGroups(weekExpenses, 'EEEE');
  }
});

final filteredTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
  return expenses.fold(0.0, (sum, e) => sum + e.amount);
});

final allTimeTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseProvider);
  return expenses.fold(0.0, (sum, e) => sum + e.amount);
});

final timeframeTrendProvider = Provider<Map<String, Map<String, double>>>((ref) {
  final timeframe = ref.watch(analyticsTimeframeProvider);
  final expenses = ref.watch(expenseProvider);
  final now = DateTime.now();
  final Map<String, Map<String, double>> trend = {};

  if (timeframe == AnalyticsTimeframe.weekly) {
    // 7 Day graph (Only small bars, or one big bar for the week)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final Map<String, double> weekDays = {};
    for (var i = 0; i < 7; i++) {
       final day = startOfWeek.add(Duration(days: i));
       final label = DateFormat('E').format(day);
       weekDays[label] = 0.0;
    }
    for (var e in expenses) {
      if (e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
        final label = DateFormat('E').format(e.date);
        if (weekDays.containsKey(label)) {
          weekDays[label] = (weekDays[label] ?? 0) + e.amount;
        }
      }
    }
    trend['Current Week'] = weekDays;
  } else if (timeframe == AnalyticsTimeframe.monthly) {
    // 4-5 Weeks (Big bars) with 7 Days (Small bars)
    for (var w = 0; w < 5; w++) {
      final weekLabel = 'Week ${w + 1}';
      final Map<String, double> daysInWeek = {for(var d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) d: 0.0};
      trend[weekLabel] = daysInWeek;
    }
    for (var e in expenses) {
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
    // Yearly (3 years with 12 months)
    final targetYears = [(now.year - 2).toString(), (now.year - 1).toString(), now.year.toString()];
    for (var year in targetYears) {
      trend[year] = {for (var m = 1; m <= 12; m++) DateFormat('MMM').format(DateTime(now.year, m)): 0.0};
    }
    for (var e in expenses) {
      final yearStr = e.date.year.toString();
      if (trend.containsKey(yearStr)) {
        final monthLabel = DateFormat('MMM').format(e.date);
        trend[yearStr]![monthLabel] = (trend[yearStr]![monthLabel] ?? 0) + e.amount;
      }
    }
  }
  return trend;
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
