import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'earning_provider.dart';
import '../models/earning.dart';

enum EarningAnalyticsTimeframe { weekly, monthly, yearly }

class EarningTimeframeNotifier extends Notifier<EarningAnalyticsTimeframe> {
  @override
  EarningAnalyticsTimeframe build() => EarningAnalyticsTimeframe.monthly;
  
  void set(EarningAnalyticsTimeframe value) => state = value;
}

final earningAnalyticsTimeframeProvider = NotifierProvider<EarningTimeframeNotifier, EarningAnalyticsTimeframe>(EarningTimeframeNotifier.new);

final filteredEarningsProvider = Provider((ref) {
  final timeframe = ref.watch(earningAnalyticsTimeframeProvider);
  final earnings = ref.watch(earningProvider);
  final now = DateTime.now();

  return earnings.where((e) {
    if (timeframe == EarningAnalyticsTimeframe.weekly) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
    } else if (timeframe == EarningAnalyticsTimeframe.monthly) {
      return e.date.year == now.year && e.date.month == now.month;
    } else {
      return e.date.year == now.year;
    }
  }).toList();
});

final earningSourceTotalsProvider = Provider<Map<String, double>>((ref) {
  final earnings = ref.watch(filteredEarningsProvider);
  final Map<String, double> totals = {};
  for (var e in earnings) {
    totals[e.incomeSource] = (totals[e.incomeSource] ?? 0) + e.amount;
  }
  return totals;
});

class GroupedEarning {
  final String label;
  final double amount;
  final int count;
  final List<Earning> items;
  final List<GroupedEarning>? children;

  GroupedEarning({
    required this.label,
    required this.amount,
    required this.count,
    required this.items,
    this.children,
  });
}

final groupedEarningActivityProvider = Provider<List<GroupedEarning>>((ref) {
  final timeframe = ref.watch(earningAnalyticsTimeframeProvider);
  final allEarnings = ref.watch(earningProvider);
  
  if (allEarnings.isEmpty) return [];

  // Helper to group by a specific date format
  List<GroupedEarning> buildGroups(List<Earning> earnings, String format, {List<GroupedEarning> Function(List<Earning>)? childBuilder}) {
    final Map<String, List<Earning>> groups = {};
    for (var e in earnings) {
      final label = DateFormat(format).format(e.date);
      groups[label] = (groups[label] ?? [])..add(e);
    }
    
    // Sort groups logically (e.g., chronologically if possible)
    final sortedKeys = groups.keys.toList();
    
    return sortedKeys.map((label) {
      final groupItems = groups[label]!;
      final amount = groupItems.fold(0.0, (sum, e) => sum + e.amount);
      return GroupedEarning(
        label: label,
        amount: amount,
        count: groupItems.length,
        items: groupItems,
        children: childBuilder?.call(groupItems),
      );
    }).toList();
  }

  if (timeframe == EarningAnalyticsTimeframe.yearly) {
    return buildGroups(allEarnings, 'yyyy', childBuilder: (yearItems) {
      return buildGroups(yearItems, 'MMMM', childBuilder: (monthItems) {
        return buildGroups(monthItems, 'MMM dd');
      });
    });
  } else if (timeframe == EarningAnalyticsTimeframe.monthly) {
    final now = DateTime.now();
    final monthEarnings = allEarnings.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    return buildGroups(monthEarnings, 'MMMM yyyy', childBuilder: (monthItems) {
      return buildGroups(monthItems, 'MMM dd');
    });
  } else {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekEarnings = allEarnings.where((e) => e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))).toList();
    return buildGroups(weekEarnings, 'EEEE');
  }
});

final filteredEarningTotalProvider = Provider<double>((ref) {
  final earnings = ref.watch(filteredEarningsProvider);
  return earnings.fold(0.0, (sum, e) => sum + e.amount);
});

final allTimeEarningTotalProvider = Provider<double>((ref) {
  final earnings = ref.watch(earningProvider);
  return earnings.fold(0.0, (sum, e) => sum + e.amount);
});

final earningTimeframeTrendProvider = Provider<Map<String, Map<String, double>>>((ref) {
  final timeframe = ref.watch(earningAnalyticsTimeframeProvider);
  final earnings = ref.watch(earningProvider);
  final now = DateTime.now();
  final Map<String, Map<String, double>> trend = {};

  if (timeframe == EarningAnalyticsTimeframe.weekly) {
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final Map<String, double> weekDays = {};
    for (var i = 0; i < 7; i++) {
       final day = startOfWeek.add(Duration(days: i));
       final label = DateFormat('E').format(day);
       weekDays[label] = 0.0;
    }
    for (var e in earnings) {
      if (e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
        final label = DateFormat('E').format(e.date);
        if (weekDays.containsKey(label)) {
          weekDays[label] = (weekDays[label] ?? 0) + e.amount;
        }
      }
    }
    trend['Current Week'] = weekDays;
  } else if (timeframe == EarningAnalyticsTimeframe.monthly) {
    for (var w = 0; w < 5; w++) {
      final weekLabel = 'Week ${w + 1}';
      final Map<String, double> daysInWeek = {for(var d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) d: 0.0};
      trend[weekLabel] = daysInWeek;
    }
    for (var e in earnings) {
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
    for (var e in earnings) {
      final yearStr = e.date.year.toString();
      if (trend.containsKey(yearStr)) {
        final monthLabel = DateFormat('MMM').format(e.date);
        trend[yearStr]![monthLabel] = (trend[yearStr]![monthLabel] ?? 0) + e.amount;
      }
    }
  }
  return trend;
});
