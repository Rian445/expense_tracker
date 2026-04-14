import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/analytics_provider.dart';
import '../models/expense.dart';
import '../core/services/export_service.dart';
import '../core/services/google_sheets_service.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _chartMode = 0; // 0: Category, 1: Subcategory, 2: Time
  String? _selectedCategoryForSubChart;

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              if (expenses.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No expenses to export')),
                );
                return;
              }
              _showExportOptions(context, expenses.cast<Expense>());
            },
          )
        ],
      ),
      body: expenses.isEmpty
          ? const Center(child: Text('No expenses yet. Add one!'))
          : Column(
              children: [
                _buildChartToggles(categoryTotals),
                Expanded(flex: 2, child: _buildChart(categoryTotals)),
                const Divider(),
                Expanded(flex: 3, child: _buildExpenseList(expenses)),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showExportOptions(BuildContext context, List<Expense> expenses) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Export to CSV'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final path = await ExportService().exportToCsv(expenses);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path')));
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_on),
                title: const Text('Export to Excel'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final path = await ExportService().exportToExcel(expenses);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path')));
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Export to PDF'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final path = await ExportService().exportToPdf(expenses);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path')));
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: const Text('Export to Google Sheets'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading...')));
                    await GoogleSheetsService().exportToGoogleSheets(expenses);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded to Google Sheets')));
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                  }
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildChartToggles(Map<String, double> categoryTotals) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Category')),
              ButtonSegment(value: 1, label: Text('Subcat')),
              ButtonSegment(value: 2, label: Text('Time')),
            ],
            selected: {_chartMode},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _chartMode = newSelection.first;
              });
            },
          ),
          if (_chartMode == 1) ...[
            const SizedBox(height: 8),
            DropdownButton<String>(
              hint: const Text('Select a Category'),
              value: _selectedCategoryForSubChart,
              items: categoryTotals.keys.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategoryForSubChart = val;
                });
              },
            )
          ]
        ],
      ),
    );
  }

  Widget _buildChart(Map<String, double> categoryTotals) {
    if (_chartMode == 0) {
      if (categoryTotals.isEmpty) return const SizedBox();
      return PieChart(
        PieChartData(
          sections: categoryTotals.entries.map((e) {
            return PieChartSectionData(
              title: '\$${e.value.toStringAsFixed(0)}',
              value: e.value,
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              color: Colors.primaries[e.key.hashCode % Colors.primaries.length],
            );
          }).toList(),
        ),
      );
    } else if (_chartMode == 1) {
      if (_selectedCategoryForSubChart == null) {
        return const Center(child: Text('Please select a category above'));
      }
      final subTotals = ref.watch(subcategoryTotalsProvider(_selectedCategoryForSubChart!));
      if (subTotals.isEmpty) return const Center(child: Text('No subcategories'));
      return PieChart(
        PieChartData(
          sections: subTotals.entries.map((e) {
            return PieChartSectionData(
              title: '\$${e.value.toStringAsFixed(0)}',
              value: e.value,
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              color: Colors.primaries[e.key.hashCode % Colors.primaries.length],
            );
          }).toList(),
        ),
      );
    } else {
      final monthly = ref.watch(monthlyTotalsProvider);
      if (monthly.isEmpty) return const SizedBox();
      final highest = monthly.values.reduce((a, b) => a > b ? a : b);
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: highest * 1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final key = value.toInt();
                  final year = key ~/ 100;
                  final month = key % 100;
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text('$month/$year', style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: monthly.entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(toY: e.value, color: Colors.blue, width: 16),
              ],
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildExpenseList(List<dynamic> expenses) {
    final formatter = DateFormat('MMM dd, yyyy');
    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return ListTile(
          title: Text('${expense.category}${expense.subCategory != null ? ' > ${expense.subCategory}' : ''}'),
          subtitle: Text('${formatter.format(expense.date)} • ${expense.paymentMethod}'),
          trailing: Text(
            '\$${expense.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }
}
