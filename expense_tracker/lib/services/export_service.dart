import 'dart:io';
import 'package:flutter/foundation.dart';
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
    debugPrint('DEBUG: Starting CSV export for $timeframe');
    try {
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
    } catch (e) {
      debugPrint('DEBUG ERROR: CSV export failed: $e');
      rethrow;
    }
  }

  static Future<void> exportExcel(List<Expense> expenses, String timeframe) async {
    debugPrint('DEBUG: Starting Excel export for $timeframe');
    try {
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
    } catch (e) {
      debugPrint('DEBUG ERROR: Excel export failed: $e');
      rethrow;
    }
  }

  static Future<void> exportPDF(List<Expense> expenses, String timeframe) async {
    debugPrint('DEBUG: Starting PDF export for $timeframe');
    try {
      final pdf = pw.Document();
      // Sort expenses by date chronologically
      expenses.sort((a, b) => a.date.compareTo(b.date));
      final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

      if (timeframe.toLowerCase() == 'yearly' || timeframe == 'All_Time' || RegExp(r'^\d{4}$').hasMatch(timeframe)) {
        // Group by Year first
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
              pw.Header(level: 0, child: pw.Text(timeframe == 'All_Time' ? 'Historical Expense Report' : 'Yearly Report - $timeframe')),
              pw.Paragraph(text: 'Grand Total Spending: ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              
              ...hierarchicalGroups.entries.expand((yearEntry) {
                final year = yearEntry.key;
                final months = yearEntry.value;
                final yearTotal = months.values.expand((m) => m).fold(0.0, (sum, e) => sum + e.amount);

                return [
                  pw.SizedBox(height: 30),
                  pw.Divider(),
                  pw.Text('YEAR $year', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20, color: PdfColors.blue900)),
                  pw.Text('Year Total: ${yearTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
      } else {
        // Normal list for Weekly/Monthly
        pdf.addPage(
          pw.MultiPage(
            build: (context) => [
              pw.Header(level: 0, child: pw.Text('Expense Report - $timeframe')),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Category', 'Sub-Category', 'Amount', 'Method'],
                data: [
                  ...expenses.map((e) => [
                    DateFormat('MM/dd HH:mm').format(e.date),
                    e.category,
                    e.subCategory ?? '',
                    e.amount.toStringAsFixed(2),
                    e.paymentMethod,
                  ]),
                  ['', '', 'TOTAL', total.toStringAsFixed(2), ''],
                ],
              ),
            ],
          ),
        );
      }

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/expenses_export_$timeframe.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(path, mimeType: 'application/pdf')], text: 'Expense Export ($timeframe)');
    } catch (e) {
      debugPrint('DEBUG ERROR: PDF export failed: $e');
      rethrow;
    }
  }
}
