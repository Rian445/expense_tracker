import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExportService {
  static Future<void> exportCSV(List<Expense> expenses, String timeframe) async {
    List<List<dynamic>> rows = [
      ['Date', 'Category', 'Sub-Category', 'Amount', 'Payment Method']
    ];

    double total = 0;
    for (var expense in expenses) {
      total += expense.amount;
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm').format(expense.date),
        expense.category,
        expense.subCategory ?? '',
        expense.amount,
        expense.paymentMethod,
      ]);
    }

    rows.add([]);
    rows.add(['', '', 'TOTAL', total, '']);

    String csv = Csv().encode(rows);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/expenses_export_$timeframe.csv';
    final file = File(path);
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(path, mimeType: 'text/csv')], text: 'Expense Export ($timeframe)');
  }

  static Future<void> exportExcel(List<Expense> expenses, String timeframe) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow(['Date', 'Category', 'Sub-Category', 'Amount', 'Payment Method'].map((e) => TextCellValue(e)).toList());

    double total = 0;
    for (var expense in expenses) {
      total += expense.amount;
      sheetObject.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(expense.date)),
        TextCellValue(expense.category),
        TextCellValue(expense.subCategory ?? ''),
        DoubleCellValue(expense.amount),
        TextCellValue(expense.paymentMethod),
      ]);
    }

    sheetObject.appendRow([TextCellValue(''), TextCellValue(''), TextCellValue('TOTAL'), DoubleCellValue(total), TextCellValue('')]);

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/expenses_export_$timeframe.xlsx';
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await File(path).writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')], text: 'Expense Export ($timeframe)');
    }
  }

  static Future<void> exportPDF(List<Expense> expenses, String timeframe) async {
    final pdf = pw.Document();
    expenses.sort((a, b) => a.date.compareTo(b.date));
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

    final Map<int, Map<String, List<Expense>>> hierarchicalGroups = {};
    for (var e in expenses) {
      final year = e.date.year;
      final month = DateFormat('MMMM').format(e.date);
      hierarchicalGroups[year] ??= {};
      hierarchicalGroups[year]![month] = (hierarchicalGroups[year]![month] ?? [])..add(e);
    }

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(timeframe == 'All_Time' ? 'Historical Expense Report' : 'Expense Report - $timeframe')),
          pw.Paragraph(text: 'Total Spending: ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 20),
          
          pw.Text('Category Distribution', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.SizedBox(height: 10),
          _buildPdfDistributionSection(expenses),
          
          pw.SizedBox(height: 30),
          pw.Divider(),

          ...hierarchicalGroups.entries.expand((yearEntry) {
            final year = yearEntry.key;
            final months = yearEntry.value;
            final yearTotal = months.values.expand((m) => m).fold(0.0, (sum, e) => sum + e.amount);

            return [
              pw.SizedBox(height: 20),
              pw.Text('YEAR $year', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22, color: PdfColors.indigo900)),
              pw.Text('Sub-total: ${yearTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              
              ...months.entries.map((monthEntry) {
                final monthName = monthEntry.key;
                final monthExpenses = monthEntry.value;
                final monthTotal = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 15),
                    pw.Text('$monthName $year', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.SizedBox(height: 8),
                    pw.TableHelper.fromTextArray(
                      headers: ['Date', 'Category', 'Sub-Category', 'Amount', 'Method'],
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      data: monthExpenses.map((e) => [
                        DateFormat('MMM dd').format(e.date),
                        e.category,
                        e.subCategory ?? '',
                        e.amount.toStringAsFixed(2),
                        e.paymentMethod,
                      ]).toList(),
                    ),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 8),
                        child: pw.Text('Month Total: ${monthTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              }),
            ];
          }),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/expenses_export_$timeframe.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(path, mimeType: 'application/pdf')], text: 'Expense Export ($timeframe)');
  }

  static pw.Widget _buildPdfDistributionSection(List<Expense> expenses) {
    if (expenses.isEmpty) return pw.SizedBox.shrink();
    
    final Map<String, double> categoryTotals = {};
    for (var e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }
    
    final sortedCats = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final totalSpent = sortedCats.fold(0.0, (sum, e) => sum + e.value);

    final colors = [PdfColors.indigo, PdfColors.amber, PdfColors.pink, PdfColors.teal, PdfColors.orange, PdfColors.cyan, PdfColors.purple];

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          if (totalSpent > 0)
            pw.Container(
              height: 20,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: sortedCats.map((cat) {
                  final idx = sortedCats.indexOf(cat);
                  final weight = cat.value / totalSpent;
                  if (weight < 0.01) return pw.SizedBox.shrink();
                  return pw.Expanded(
                    flex: (weight * 1000).toInt(),
                    child: pw.Container(color: colors[idx % colors.length]),
                  );
                }).toList(),
              ),
            ),
          pw.SizedBox(height: 20),
          pw.Column(
            children: sortedCats.take(10).map((cat) {
              final idx = sortedCats.indexOf(cat);
              final perc = (cat.value / totalSpent * 100).toStringAsFixed(1);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  children: [
                    pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(color: colors[idx % colors.length], shape: pw.BoxShape.circle)),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Text('${cat.key}: $perc%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Text(cat.value.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10)),
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
