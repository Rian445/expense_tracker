import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/earning_analytics_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../core/constants/app_theme.dart';
import '../models/earning.dart';
import 'add_earning_screen.dart';

class EarningScreen extends ConsumerWidget {
  const EarningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryTotals = ref.watch(earningSourceTotalsProvider);
    final groupedActivity = ref.watch(groupedEarningActivityProvider);
    final timeframe = ref.watch(earningAnalyticsTimeframeProvider);
    final currentEarning = ref.watch(filteredEarningTotalProvider);

    String activityTitle;
    switch (timeframe) {
      case EarningAnalyticsTimeframe.weekly: activityTitle = 'Daily Activity'; break;
      case EarningAnalyticsTimeframe.monthly: activityTitle = 'Month Summary'; break;
      case EarningAnalyticsTimeframe.yearly: activityTitle = 'Yearly Summary'; break;
    }

    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: Drawer(
        backgroundColor: isDarkMode ? const Color(0xFF0D1B10) : AppColors.background,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.teal.shade500],
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
                      child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Earning Tracker',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            _DrawerItem(icon: Icons.dashboard_outlined, label: 'Earning Dashboard', isSelected: true, onTap: () => Navigator.pop(context)),
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
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BalanceCard(currentEarning: currentEarning),
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
                return _ActivitySummaryTile(group: group, timeframe: timeframe, level: 0);
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
          MaterialPageRoute(builder: (context) => const AddEarningScreen()),
        ),
        label: const Text('Add Earning', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
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
    final activeColor = Colors.green.shade600;
    
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
  final double currentEarning;
  const _BalanceCard({required this.currentEarning});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeframe = ref.watch(earningAnalyticsTimeframeProvider);
    final allTimeTotal = ref.watch(allTimeEarningTotalProvider);
    final timeframeTrend = ref.watch(earningTimeframeTrendProvider);
    final currency = ref.watch(currencyProvider);

    String label;
    switch (timeframe) {
      case EarningAnalyticsTimeframe.weekly: label = 'Earnings this Week'; break;
      case EarningAnalyticsTimeframe.monthly: label = 'Total Month so far'; break;
      case EarningAnalyticsTimeframe.yearly: label = 'Earnings this Year'; break;
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        final currentIndex = timeframe.index;
        if (details.primaryVelocity! < -300) { 
          if (currentIndex < EarningAnalyticsTimeframe.values.length - 1) {
            ref.read(earningAnalyticsTimeframeProvider.notifier).set(EarningAnalyticsTimeframe.values[currentIndex + 1]);
          }
        } else if (details.primaryVelocity! > 300) { 
          if (currentIndex > 0) {
            ref.read(earningAnalyticsTimeframeProvider.notifier).set(EarningAnalyticsTimeframe.values[currentIndex - 1]);
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.teal.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade600.withValues(alpha: 0.3),
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
                if (timeframe == EarningAnalyticsTimeframe.yearly)
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
              '${currency.symbol}${currentEarning.toStringAsFixed(2)}',
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
                          getTitlesWidget: (value, meta) {
                            if (timeframe == EarningAnalyticsTimeframe.yearly && timeframeTrend.keys.length > 2) {
                              final keys = timeframeTrend.keys.toList();
                              if (value.toInt() >= 0 && value.toInt() < keys.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(keys[value.toInt()], style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
                                );
                              }
                            } else {
                              if (value.toInt() >= 0 && value.toInt() < timeframeTrend.entries.first.value.keys.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(timeframeTrend.entries.first.value.keys.elementAt(value.toInt()), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 24,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: timeframe == EarningAnalyticsTimeframe.yearly
                      ? timeframeTrend.entries.map((e) {
                          final idx = timeframeTrend.keys.toList().indexOf(e.key);
                          final totalForYear = e.value.values.fold(0.0, (s, amt) => s + amt);
                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: totalForYear,
                                color: Colors.white,
                                width: 24,
                                borderRadius: BorderRadius.circular(4),
                              )
                            ],
                          );
                        }).toList()
                      : timeframeTrend.entries.first.value.entries.map((e) {
                          final idx = timeframeTrend.entries.first.value.keys.toList().indexOf(e.key);
                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: e.value,
                                color: Colors.white.withValues(alpha: e.value > 0 ? 1 : 0.3),
                                width: timeframe == EarningAnalyticsTimeframe.weekly ? 16 : 8,
                                borderRadius: BorderRadius.circular(4),
                              )
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
    if (categoryData.isEmpty) {
      final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : AppColors.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 48, color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('No data for this period', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    final total = categoryData.values.fold(0.0, (sum, val) => sum + val);
    final sortedData = categoryData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final currency = ref.watch(currencyProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    sections: sortedData.map((e) {
                      final index = sortedData.indexOf(e);
                      final percentage = (e.value / total) * 100;
                      return PieChartSectionData(
                        color: Colors.primaries[index % Colors.primaries.length],
                        value: e.value,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: percentage > 10 ? (percentage > 30 ? 30 : 25) : 20,
                        titleStyle: TextStyle(
                          fontSize: percentage > 10 ? 12 : 10,
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
                        '${currency.symbol}${total.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: isDarkMode ? Colors.white : AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: sortedData.take(4).map((e) {
              final index = sortedData.indexOf(e);
              final color = Colors.primaries[index % Colors.primaries.length];
              final percentage = (e.value / total) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white70 : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${currency.symbol}${e.value.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 45,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: isDarkMode ? Colors.white54 : AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ActivitySummaryTile extends ConsumerStatefulWidget {
  final GroupedEarning group;
  final EarningAnalyticsTimeframe timeframe;
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

  IconData _getIcon() {
    if (widget.level > 0) return Icons.calendar_today_outlined;
    switch (widget.timeframe) {
      case EarningAnalyticsTimeframe.weekly: return Icons.today_outlined;
      case EarningAnalyticsTimeframe.monthly: return Icons.calendar_view_day_outlined;
      case EarningAnalyticsTimeframe.yearly: return Icons.calendar_month_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.group.children != null && widget.group.children!.isNotEmpty;
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final currency = ref.watch(currencyProvider);
    final activeColor = Colors.green.shade600;

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
                            activeColor,
                            activeColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.3),
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
                          color: activeColor.withValues(alpha: 0.3),
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
                            if (widget.level > 0)
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: 0.7, 
                                    backgroundColor: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                    valueColor: AlwaysStoppedAnimation(activeColor.withValues(alpha: 0.5)),
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
                        '+${currency.symbol}${widget.group.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: widget.level == 0 ? 17 : 14, 
                          color: activeColor,
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
                    ...widget.group.items.map((Earning item) => Consumer(
                      builder: (context, ref, child) {
                        final sources = ref.watch(earningSourceTotalsProvider).keys.toList();
                        final colorIndex = sources.indexOf(item.incomeSource);
                        final dotColor = colorIndex >= 0 
                            ? Colors.primaries[colorIndex % Colors.primaries.length]
                            : activeColor;

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
                                    Text(item.incomeSource, style: TextStyle(
                                      fontSize: 13, 
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                                    )),
                                    if (item.receiveMethod.isNotEmpty)
                                      Text(item.receiveMethod, style: TextStyle(
                                        fontSize: 11, 
                                        color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
                                      )),
                                  ],
                                ),
                              ),
                              Text(
                                '+${currency.symbol}${item.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800, 
                                  fontSize: 13,
                                  color: activeColor,
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
}
