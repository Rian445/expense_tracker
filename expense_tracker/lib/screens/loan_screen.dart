import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/loan_analytics_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../core/constants/app_theme.dart';
import '../models/loan.dart';
import 'add_loan_screen.dart';
import '../services/export_service.dart';

class LoanScreen extends ConsumerWidget {
  const LoanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanCategoryTotals = ref.watch(loanCategoryTotalsProvider);
    final groupedActivity = ref.watch(groupedLoanActivityProvider);
    final timeframe = ref.watch(loanAnalyticsTimeframeProvider);
    final currentLoan = ref.watch(filteredLoanTotalProvider);

    String activityTitle;
    switch (timeframe) {
      case LoanAnalyticsTimeframe.weekly: activityTitle = 'Daily Activity'; break;
      case LoanAnalyticsTimeframe.monthly: activityTitle = 'Month Summary'; break;
      case LoanAnalyticsTimeframe.yearly: activityTitle = 'Yearly Summary'; break;
    }

    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: Drawer(
        backgroundColor: isDarkMode ? const Color(0xFF1B140D) : AppColors.background,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade800, Colors.amber.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
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
                      child: const Icon(Icons.handshake_outlined, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Loan Tracker',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            _DrawerItem(icon: Icons.dashboard_outlined, label: 'Loan Dashboard', isSelected: true, onTap: () => Navigator.pop(context)),
            const Divider(height: 32, indent: 20, endIndent: 20),
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
                   _BalanceCard(currentLoan: currentLoan),
                  const SizedBox(height: 24),
                  const _TimeframeSelector(),
                  const SizedBox(height: 32),
                  const _SectionHeader(title: 'Analytics'),
                  const SizedBox(height: 16),
                  _AnalyticsCard(categoryData: loanCategoryTotals),
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
                return _ActivitySummaryTile(group: group, timeframe: timeframe, level: 0);
              },
              childCount: groupedActivity.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddLoanScreen()),
        ),
        label: const Text('Add Loan', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  void _showExportOptions(BuildContext context, WidgetRef ref) {
    // Note: I will need to extend ExportService for Loans as well, but for now we follow general pattern
    final timeframe = ref.read(loanAnalyticsTimeframeProvider);
    final allLoans = ref.read(loanProvider);
    
    if (timeframe == LoanAnalyticsTimeframe.yearly) {
      final years = allLoans.map((e) => e.date.year).toSet().toList()..sort((a, b) => b.compareTo(a));
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
                          _showFormatOptions(context, allLoans, 'All_Time');
                        },
                      ),
                      ...years.map((year) => _StepTile(
                        label: year.toString(),
                        onTap: () {
                          Navigator.pop(context);
                          final filtered = allLoans.where((e) => e.date.year == year).toList();
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
      final loans = ref.read(filteredLoansProvider);
      _showFormatOptions(context, loans, timeframe.name);
    }
  }

  void _showFormatOptions(BuildContext context, List<Loan> loans, String label) {
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
                  _runExport(context, () => ExportService.exportLoansCSV(loans, label), 'CSV');
                },
              ),
              _ExportTile(
                icon: Icons.grid_on_outlined,
                label: 'Export to Excel',
                color: Colors.blue,
                onTap: () async {
                  Navigator.pop(context);
                  _runExport(context, () => ExportService.exportLoansExcel(loans, label), 'Excel');
                },
              ),
              _ExportTile(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Export to PDF',
                color: Colors.red,
                onTap: () async {
                  Navigator.pop(context);
                  _runExport(context, () => ExportService.exportLoansPDF(loans, label), 'PDF');
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

class _DrawerItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final activeColor = Colors.orange.shade800;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? activeColor.withValues(alpha: 0.1) : null,
        leading: Icon(
          icon, 
          color: isSelected ? activeColor : (isDarkMode ? Colors.white70 : AppColors.textSecondary),
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? activeColor 
                : (isDarkMode ? Colors.white : AppColors.textPrimary),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  final double currentLoan;
  const _BalanceCard({required this.currentLoan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeframe = ref.watch(loanAnalyticsTimeframeProvider);
    final allTimeTotal = ref.watch(allTimeLoanTotalProvider);
    final timeframeTrend = ref.watch(loanTimeframeTrendProvider);
    final currency = ref.watch(currencyProvider);

    String label;
    switch (timeframe) {
      case LoanAnalyticsTimeframe.weekly: label = 'Loans this Week'; break;
      case LoanAnalyticsTimeframe.monthly: label = 'Total Month so far'; break;
      case LoanAnalyticsTimeframe.yearly: label = 'Loans this Year'; break;
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        final currentIndex = timeframe.index;
        if (details.primaryVelocity! < -300) { 
          if (currentIndex < LoanAnalyticsTimeframe.values.length - 1) {
            ref.read(loanAnalyticsTimeframeProvider.notifier).set(LoanAnalyticsTimeframe.values[currentIndex + 1]);
          }
        } else if (details.primaryVelocity! > 300) { 
          if (currentIndex > 0) {
            ref.read(loanAnalyticsTimeframeProvider.notifier).set(LoanAnalyticsTimeframe.values[currentIndex - 1]);
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade800, Colors.amber.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade800.withValues(alpha: 0.3),
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
                if (timeframe == LoanAnalyticsTimeframe.yearly)
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
              '${currency.symbol}${currentLoan.toStringAsFixed(2)}',
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
                      
                      final allItems = timeframeTrend.values.expand((m) => m.values).toList();
                      final globalMax = allItems.isEmpty ? 0.0 : allItems.reduce((a, b) => a > b ? a : b);
                      
                      return BarChartGroupData(
                        x: outerIndex,
                        barsSpace: timeframe == LoanAnalyticsTimeframe.yearly ? 2 : (timeframe == LoanAnalyticsTimeframe.weekly ? 0 : 4),
                        barRods: [
                          if (timeframe != LoanAnalyticsTimeframe.weekly)
                            BarChartRodData(
                              toY: outerTotal == 0 ? 5.0 : outerTotal,
                              color: Colors.white.withValues(alpha: 0.2),
                              width: timeframe == LoanAnalyticsTimeframe.yearly ? 12 : 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ...innerData.entries.map((entry) {
                            final val = entry.value;
                            final isPeak = val > 0 && val == globalMax;
                            
                            return BarChartRodData(
                              toY: val == 0 ? 2.0 : val,
                              color: isPeak 
                                  ? Colors.amberAccent 
                                  : Colors.white.withValues(alpha: val == 0 ? 0.05 : 0.4),
                              width: timeframe == LoanAnalyticsTimeframe.weekly 
                                  ? 18.0 
                                  : (timeframe == LoanAnalyticsTimeframe.yearly ? 1.5 : 2.5),
                              borderRadius: BorderRadius.circular(timeframe == LoanAnalyticsTimeframe.weekly ? 4 : 1),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : AppColors.textPrimary,
      ),
    );
  }
}

class _AnalyticsCard extends ConsumerWidget {
  final Map<String, double> categoryData;
  const _AnalyticsCard({required this.categoryData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final total = categoryData.values.fold(0.0, (sum, val) => sum + val);
    
    final sortedData = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (total == 0) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: const Center(child: Text('No data yet')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 65,
                    startDegreeOffset: -90,
                    sections: sortedData.map((e) {
                      final index = categoryData.keys.toList().indexOf(e.key);
                      final percentage = (e.value / total) * 100;
                      return PieChartSectionData(
                        color: Colors.primaries[index % Colors.primaries.length],
                        value: e.value,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 25,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total', style: TextStyle(color: isDarkMode ? Colors.white54 : AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        total.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ...sortedData.take(4).map((e) {
            final index = categoryData.keys.toList().indexOf(e.key);
            final percentage = (e.value / total) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: Colors.primaries[index % Colors.primaries.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    e.value.toStringAsFixed(0),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActivitySummaryTile extends ConsumerStatefulWidget {
  final GroupedLoan group;
  final LoanAnalyticsTimeframe timeframe;
  final int level;

  const _ActivitySummaryTile({
    required this.group,
    required this.timeframe,
    required this.level,
  });

  @override
  ConsumerState<_ActivitySummaryTile> createState() => _ActivitySummaryTileState();
}

class _ActivitySummaryTileState extends ConsumerState<_ActivitySummaryTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final primaryColor = Colors.orange.shade800;
    
    final hasChildren = widget.group.children != null && widget.group.children!.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(
        left: 20, 
        right: 20, 
        bottom: widget.level == 0 ? 16 : 0,
      ),
      decoration: BoxDecoration(
        color: widget.level == 0 
            ? (isDarkMode ? const Color(0xFF1B140D) : Colors.white)
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
                            primaryColor,
                            primaryColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(_getIcon(), color: Colors.white, size: 18),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 12),
                      child: Container(
                        width: 2,
                        height: 30,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.3),
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
                            Text('${widget.group.count} loans', style: TextStyle(
                              color: isDarkMode ? Colors.white38 : AppColors.textSecondary, 
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            )),
                            const SizedBox(width: 8),
                            if (widget.level > 0)
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: 0.7,
                                    backgroundColor: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                    valueColor: AlwaysStoppedAnimation(primaryColor.withValues(alpha: 0.5)),
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
                    ...widget.group.items.map((loan) => _LoanActivityTile(loan: loan, indent: widget.level + 1)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.timeframe) {
      case LoanAnalyticsTimeframe.weekly: return Icons.today_outlined;
      case LoanAnalyticsTimeframe.monthly: return Icons.calendar_view_day_outlined;
      case LoanAnalyticsTimeframe.yearly: return Icons.calendar_month_outlined;
    }
  }
}

class _LoanActivityTile extends ConsumerWidget {
  final Loan loan;
  final int indent;

  const _LoanActivityTile({required this.loan, required this.indent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final primaryColor = Colors.orange.shade800;

    final loanCategories = ref.watch(loanCategoryTotalsProvider).keys.toList();
    final colorIndex = loanCategories.indexOf(loan.purpose);
    final dotColor = colorIndex >= 0 
        ? Colors.primaries[colorIndex % Colors.primaries.length]
        : primaryColor;

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
                Text(loan.purpose, style: TextStyle(
                  fontSize: 13, 
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                )),
                Text(
                  '${loan.loanFrom}${loan.duration.isNotEmpty ? ' • ${loan.duration}' : ''}', 
                  style: TextStyle(
                    fontSize: 11, 
                    color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${currency.symbol}${loan.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800, 
                  fontSize: 13,
                  color: isDarkMode ? primaryColor.withValues(alpha: 0.8) : primaryColor,
                ),
              ),
              Text(
                DateFormat('MMM dd').format(loan.date),
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white24 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _TimeframeSelector extends ConsumerWidget {
  const _TimeframeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(loanAnalyticsTimeframeProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: LoanAnalyticsTimeframe.values.map((t) {
          final isSelected = selected == t;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(loanAnalyticsTimeframeProvider.notifier).set(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange.shade800 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    t.name[0].toUpperCase() + t.name.substring(1),
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDarkMode ? Colors.white60 : AppColors.textSecondary),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
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
        tileColor: Colors.orange.shade800.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 16, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

