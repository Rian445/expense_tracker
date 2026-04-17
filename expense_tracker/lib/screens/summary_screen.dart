import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/summary_provider.dart';
import '../providers/analytics_provider.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Financial Intelligence'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Net Balance Card ─────────────────────────────────────────────
            _NetWorthCard(summary: summary, isDarkMode: isDarkMode),
            const SizedBox(height: 32),

            // ── Cash Flow Chart ─────────────────────────────────────────────
            Text(
              'Total Cash Flow',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _CashFlowChart(summary: summary, isDarkMode: isDarkMode),
            const SizedBox(height: 32),

            // ── Spending Breakdown ──────────────────────────────────────────
            Text(
              'Spending Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (categoryTotals.isEmpty)
              const _NoDataPlaceholder(message: 'No expenses tracked yet.')
            else
              _SpendingPieChart(categoryTotals: categoryTotals, isDarkMode: isDarkMode),
            const SizedBox(height: 32),

            // ── Financial Health Summary ────────────────────────────────────
            _FinancialHealthCard(summary: summary, isDarkMode: isDarkMode),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  final FinancialSummary summary;
  final bool isDarkMode;

  const _NetWorthCard({required this.summary, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final bool isNegative = summary.netBalance < 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNegative 
            ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)] // Red for debt
            : [AppColors.primary, const Color(0xFF4F46E5)],      // Blue for savings
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isNegative ? Colors.red : AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isNegative ? 'DEBT STATUS' : 'AVAILABLE BALANCE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${isNegative ? "-" : ""}\$${summary.netBalance.abs().toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isNegative ? 'Financial Alert' : 'Healthy Savings',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashFlowChart extends StatelessWidget {
  final FinancialSummary summary;
  final bool isDarkMode;

  const _CashFlowChart({required this.summary, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey.withValues(alpha: 0.1)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (summary.totalEarnings > summary.totalExpenses ? summary.totalEarnings : summary.totalExpenses) * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(fontSize: 10, fontWeight: FontWeight.bold);
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(value == 0 ? 'Earnings' : 'Expenses', style: style),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: summary.totalEarnings,
                  color: const Color(0xFF10B981),
                  width: 32,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: summary.totalExpenses,
                  color: const Color(0xFFEF4444),
                  width: 32,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendingPieChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final bool isDarkMode;

  const _SpendingPieChart({required this.categoryTotals, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: categoryTotals.entries.toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final category = entry.value;
                  return PieChartSectionData(
                    color: colors[idx % colors.length],
                    value: category.value,
                    title: '${(category.value / categoryTotals.values.reduce((a, b) => a + b) * 100).toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categoryTotals.entries.toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final category = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[idx % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.key,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : AppColors.textPrimary,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialHealthCard extends StatelessWidget {
  final FinancialSummary summary;
  final bool isDarkMode;

  const _FinancialHealthCard({required this.summary, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    String feedback;
    IconData icon;
    Color color;

    if (summary.netBalance < 0) {
      feedback = "Warning: Your expenses exceed your earnings. Consider reducing non-essential spending.";
      icon = Icons.warning_amber_rounded;
      color = const Color(0xFFEF4444);
    } else if (summary.savingsRate > 20) {
      feedback = "Excellent! You're saving ${summary.savingsRate.toStringAsFixed(1)}% of your income. Keep building your wealth!";
      icon = Icons.star_rounded;
      color = const Color(0xFF10B981);
    } else {
      feedback = "Good start. You're living within your means. Try to increase your savings rate for long-term security.";
      icon = Icons.thumb_up_rounded;
      color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Health Analysis',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDataPlaceholder extends StatelessWidget {
  final String message;
  const _NoDataPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
