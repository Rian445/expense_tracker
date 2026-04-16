import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/analytics_provider.dart';
import '../providers/theme_provider.dart';
import '../core/constants/app_theme.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import '../providers/expense_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final groupedActivity = ref.watch(groupedActivityProvider);
    final timeframe = ref.watch(analyticsTimeframeProvider);
    final currentSpending = ref.watch(filteredTotalProvider);

    String activityTitle;
    switch (timeframe) {
      case AnalyticsTimeframe.weekly: activityTitle = 'Daily Activity'; break;
      case AnalyticsTimeframe.monthly: activityTitle = 'Month Summary'; break;
      case AnalyticsTimeframe.yearly: activityTitle = 'Yearly Summary'; break;
    }

    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Expense Tracker',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            _DrawerItem(icon: Icons.dashboard_outlined, label: 'Dashboard', isSelected: true, onTap: () => Navigator.pop(context)),
            _DrawerItem(icon: Icons.history_outlined, label: 'Transaction History', onTap: () {}),
            _DrawerItem(icon: Icons.category_outlined, label: 'Categories', onTap: () {}),
            _DrawerItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () {}),
            const Divider(height: 32, indent: 20, endIndent: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Currency', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Consumer(
              builder: (context, ref, child) {
                final currentCurrency = ref.watch(currencyProvider);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: Currency.values.map((c) {
                    final isSelected = currentCurrency == c;
                    return GestureDetector(
                      onTap: () => ref.read(currencyProvider.notifier).set(c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          c.code,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Version 1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            elevation: 0,
            scrolledUnderElevation: 2,
            floating: true,
            pinned: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: Theme.of(context).textTheme.titleLarge?.color),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text('Overview', style: Theme.of(context).appBarTheme.titleTextStyle),
            centerTitle: true,
            shape: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1)),
            actions: [
              IconButton(
                icon: Icon(
                  ref.watch(themeModeProvider) == ThemeMode.dark 
                    ? Icons.light_mode_outlined 
                    : Icons.dark_mode_outlined,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
              ),
              IconButton(
                icon: Icon(Icons.share_outlined, color: Theme.of(context).textTheme.titleLarge?.color),
                onPressed: () => _showExportOptions(context, ref),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BalanceCard(currentSpending: currentSpending),
                  const SizedBox(height: 32),
                  const _SectionHeader(title: 'Analytics'),
                  const SizedBox(height: 16),
                  _AnalyticsCard(categoryData: categoryTotals),
                  const SizedBox(height: 32),
                  _SectionHeader(title: activityTitle),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final group = groupedActivity[index];
                return _ActivitySummaryTile(group: group, timeframe: timeframe);
              },
              childCount: groupedActivity.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
        ),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  void _showExportOptions(BuildContext context, WidgetRef ref) {
    final timeframe = ref.read(analyticsTimeframeProvider);
    final allExpenses = ref.read(expenseProvider);
    
    if (timeframe == AnalyticsTimeframe.yearly) {
      // Step 1: Select Year
      final years = allExpenses.map((e) => e.date.year).toSet().toList()..sort((a, b) => b.compareTo(a));
      
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select Year', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _StepTile(
                        label: 'All Years so far',
                        onTap: () {
                          Navigator.pop(context);
                          _showFormatOptions(context, allExpenses, 'All_Time');
                        },
                      ),
                      ...years.map((year) => _StepTile(
                        label: year.toString(),
                        onTap: () {
                          Navigator.pop(context);
                          final filtered = allExpenses.where((e) => e.date.year == year).toList();
                          _showFormatOptions(context, filtered, year.toString());
                        },
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    } else {
      // Direct to Format Selection for Weekly/Monthly
      final expenses = ref.read(filteredExpensesProvider);
      _showFormatOptions(context, expenses, timeframe.name);
    }
  }

  void _showFormatOptions(BuildContext context, List<Expense> expenses, String label) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Export - $label', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
              const SizedBox(height: 24),
              _ExportTile(
                icon: Icons.table_chart_outlined,
                label: 'Export to CSV',
                color: Colors.green,
                onTap: () async {
                  Navigator.pop(context);
                  _runExport(context, () => ExportService.exportCSV(expenses, label), 'CSV');
                },
              ),
              _ExportTile(
                icon: Icons.grid_on_outlined,
                label: 'Export to Excel',
                color: Colors.blue,
                onTap: () async {
                  Navigator.pop(context);
                  _runExport(context, () => ExportService.exportExcel(expenses, label), 'Excel');
                },
              ),
              _ExportTile(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Export to PDF',
                color: Colors.red,
                onTap: () async {
                  Navigator.pop(context);
                  _runExport(context, () => ExportService.exportPDF(expenses, label), 'PDF');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runExport(BuildContext context, Future Function() exportFn, String format) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 16),
            Text('Generating $format report...'),
          ],
        ),
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      await exportFn();
      if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}

class _StepTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        tileColor: AppColors.primary.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  final double currentSpending;
  const _BalanceCard({required this.currentSpending});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeframe = ref.watch(analyticsTimeframeProvider);
    final allTimeTotal = ref.watch(allTimeTotalProvider);
    final timeframeTrend = ref.watch(timeframeTrendProvider);
    final currency = ref.watch(currencyProvider);

    String label;
    switch (timeframe) {
      case AnalyticsTimeframe.weekly: label = 'Spending this Week'; break;
      case AnalyticsTimeframe.monthly: label = 'Total Month so far'; break;
      case AnalyticsTimeframe.yearly: label = 'Spending this Year'; break;
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        final currentIndex = timeframe.index;
        if (details.primaryVelocity! < -300) { // Swipe Left (Next)
          if (currentIndex < AnalyticsTimeframe.values.length - 1) {
            ref.read(analyticsTimeframeProvider.notifier).set(AnalyticsTimeframe.values[currentIndex + 1]);
          }
        } else if (details.primaryVelocity! > 300) { // Swipe Right (Prev)
          if (currentIndex > 0) {
            ref.read(analyticsTimeframeProvider.notifier).set(AnalyticsTimeframe.values[currentIndex - 1]);
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
                ),
                if (timeframe == AnalyticsTimeframe.yearly)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'All Time: ${currency.symbol}${allTimeTotal.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${currency.symbol}${currentSpending.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            if (timeframeTrend.isNotEmpty) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 60,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final labels = timeframeTrend.keys.toList();
                            if (val >= 0 && val < labels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(labels[val.toInt()], style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.bold)),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: timeframeTrend.entries.map((outerEntry) {
                      final outerIndex = timeframeTrend.keys.toList().indexOf(outerEntry.key);
                      final innerData = outerEntry.value;
                      final outerTotal = innerData.values.fold(0.0, (sum, val) => sum + val);
                      
                      // Find global max to highlight the peak spending point
                      final allItems = timeframeTrend.values.expand((m) => m.values).toList();
                      final globalMax = allItems.isEmpty ? 0.0 : allItems.reduce((a, b) => a > b ? a : b);
                      
                      return BarChartGroupData(
                        x: outerIndex,
                        barsSpace: timeframe == AnalyticsTimeframe.yearly ? 2 : (timeframe == AnalyticsTimeframe.weekly ? 0 : 4),
                        barRods: [
                          // Big Bar for the Group (Only for Month/Year)
                          if (timeframe != AnalyticsTimeframe.weekly)
                            BarChartRodData(
                              toY: outerTotal == 0 ? 5.0 : outerTotal,
                              color: Colors.white.withValues(alpha: 0.2),
                              width: timeframe == AnalyticsTimeframe.yearly ? 12 : 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          // Small Bars with Adjusted Width
                          ...innerData.entries.map((entry) {
                            final val = entry.value;
                            final isPeak = val > 0 && val == globalMax;
                            
                            return BarChartRodData(
                              toY: val == 0 ? 2.0 : val,
                              color: isPeak 
                                  ? Colors.amberAccent 
                                  : Colors.white.withValues(alpha: val == 0 ? 0.05 : 0.4),
                              // Much wider bars for Weekly view
                              width: timeframe == AnalyticsTimeframe.weekly 
                                  ? 18.0 
                                  : (timeframe == AnalyticsTimeframe.yearly ? 1.5 : 2.5),
                              borderRadius: BorderRadius.circular(timeframe == AnalyticsTimeframe.weekly ? 4 : 1),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ] else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends ConsumerWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTimeframe = ref.watch(analyticsTimeframeProvider);

    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            )),
            if (title != 'Analytics')
              const Text('See all', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        if (title == 'Analytics') ...[
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final tabWidth = width / 3;
              final activeIndex = AnalyticsTimeframe.values.indexOf(selectedTimeframe);

              return Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF334155) : AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Sliding Indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      left: activeIndex * tabWidth + 4,
                      top: 4,
                      bottom: 4,
                      width: tabWidth - 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                      ),
                    ),
                    // Tab Labels
                    Row(
                      children: AnalyticsTimeframe.values.map((timeframe) {
                        final isSelected = selectedTimeframe == timeframe;
                        String label;
                        switch (timeframe) {
                          case AnalyticsTimeframe.weekly: label = 'This Week'; break;
                          case AnalyticsTimeframe.monthly: label = 'This Month'; break;
                          case AnalyticsTimeframe.yearly: label = 'This Year'; break;
                        }

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => ref.read(analyticsTimeframeProvider.notifier).set(timeframe),
                            child: Container(
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : (isDarkMode ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                child: Text(label),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final Map<String, double> categoryData;
  const _AnalyticsCard({required this.categoryData});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: categoryData.isEmpty 
                ? Center(child: Text('No data recorded yet', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: categoryData.entries.map((e) {
                        final index = categoryData.keys.toList().indexOf(e.key);
                        return PieChartSectionData(
                          value: e.value,
                          title: '',
                          radius: 50,
                          color: Colors.primaries[index % Colors.primaries.length],
                        );
                      }).toList(),
                    ),
                  ),
            ),
            if (categoryData.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: categoryData.entries.map((e) {
                  final index = categoryData.keys.toList().indexOf(e.key);
                  return _CategoryIndicator(
                    color: Colors.primaries[index % Colors.primaries.length],
                    text: e.key,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryIndicator extends StatelessWidget {
  final Color color;
  final String text;

  const _CategoryIndicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

class _ActivitySummaryTile extends ConsumerStatefulWidget {
  final GroupedExpense group;
  final AnalyticsTimeframe timeframe;
  final int level;

  const _ActivitySummaryTile({
    required this.group,
    required this.timeframe,
    this.level = 0,
  });

  @override
  ConsumerState<_ActivitySummaryTile> createState() => _ActivitySummaryTileState();
}

class _ActivitySummaryTileState extends ConsumerState<_ActivitySummaryTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.group.children != null && widget.group.children!.isNotEmpty;

    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final currency = ref.watch(currencyProvider);

    return Container(
      margin: widget.level == 0 
          ? const EdgeInsets.symmetric(horizontal: 20, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: widget.level == 0 
            ? (isDarkMode ? const Color(0xFF1E293B) : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: widget.level == 0 
            ? Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)) 
            : null,
        boxShadow: (_isExpanded && widget.level == 0) ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ] : [],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (widget.level == 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(_getIcon(), color: Colors.white, size: 18),
                    )
                  else
                    // Step indicator for nested levels
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 12),
                      child: Container(
                        width: 2,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.group.label, style: TextStyle(
                          fontWeight: widget.level == 0 ? FontWeight.bold : FontWeight.w600, 
                          fontSize: widget.level == 0 ? 16 : 14,
                          color: isDarkMode ? Colors.white : AppColors.textPrimary,
                          letterSpacing: -0.2,
                        )),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('${widget.group.count} trans.', style: TextStyle(
                              color: isDarkMode ? Colors.white38 : AppColors.textSecondary, 
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            )),
                            const SizedBox(width: 8),
                            // Mini progress bar for context
                            if (widget.level > 0)
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: 0.7, // Placeholder or calculated share
                                    backgroundColor: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                    valueColor: AlwaysStoppedAnimation(AppColors.primary.withValues(alpha: 0.5)),
                                    minHeight: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${currency.symbol}${widget.group.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: widget.level == 0 ? 17 : 14, 
                          color: isDarkMode ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 14,
                        color: isDarkMode ? Colors.white24 : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  if (hasChildren)
                    ...widget.group.children!.map((child) => _ActivitySummaryTile(
                      group: child,
                      timeframe: widget.timeframe,
                      level: widget.level + 1,
                    ))
                  else
                    ...widget.group.items.map((Expense item) => Consumer(
                      builder: (context, ref, child) {
                        final categories = ref.watch(categoryTotalsProvider).keys.toList();
                        final colorIndex = categories.indexOf(item.category);
                        final dotColor = colorIndex >= 0 
                            ? Colors.primaries[colorIndex % Colors.primaries.length]
                            : AppColors.primary;

                        return Container(
                          margin: const EdgeInsets.only(left: 32, right: 16, bottom: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: dotColor.withValues(alpha: 0.4), blurRadius: 4)
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.category, style: TextStyle(
                                      fontSize: 13, 
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                                    )),
                                    if (item.subCategory != null)
                                      Text(item.subCategory!, style: TextStyle(
                                        fontSize: 11, 
                                        color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
                                      )),
                                  ],
                                ),
                              ),
                              Text(
                                '${currency.symbol}${item.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800, 
                                  fontSize: 13,
                                  color: isDarkMode ? const Color(0xFFFB7185) : AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.timeframe) {
      case AnalyticsTimeframe.weekly: return Icons.today_outlined;
      case AnalyticsTimeframe.monthly: return Icons.calendar_view_day_outlined;
      case AnalyticsTimeframe.yearly: return Icons.calendar_month_outlined;
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
        tileColor: Colors.black.withValues(alpha: 0.02),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

