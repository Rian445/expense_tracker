import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';

class ExportService {
  Future<String> exportToCsv(List<Expense> expenses) async {
    List<List<dynamic>> rows = [];
    rows.add(['Date', 'Category', 'Subcategory', 'Amount', 'Payment Method']);

    for (var expense in expenses) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.category,
        expense.subCategory ?? '',
        expense.amount,
        expense.paymentMethod,
      ]);
    }

    // csv v8 uses CsvEncoder (replaces old ListToCsvConverter)
    String csvString = const CsvEncoder().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/expenses_export.csv';
    await File(path).writeAsString(csvString);
    return path;
  }

  Future<String> exportToExcel(List<Expense> expenses) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow([
      TextCellValue('Date'),
      TextCellValue('Category'),
      TextCellValue('Subcategory'),
      TextCellValue('Amount'),
      TextCellValue('Payment Method'),
    ]);

    for (var expense in expenses) {
      sheetObject.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(expense.date)),
        TextCellValue(expense.category),
        TextCellValue(expense.subCategory ?? ''),
        DoubleCellValue(expense.amount),
        TextCellValue(expense.paymentMethod),
      ]);
    }

    var fileBytes = excel.save();
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/expenses_export.xlsx';
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes!);

    return path;
  }

  Future<String> exportToPdf(List<Expense> expenses) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Expense Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  ['Date', 'Category', 'Subcategory', 'Amount', 'Payment Method'],
                  ...expenses.map((expense) => [
                    DateFormat('yyyy-MM-dd').format(expense.date),
                    expense.category,
                    expense.subCategory ?? '',
                    '\$${expense.amount.toStringAsFixed(2)}',
                    expense.paymentMethod,
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/expenses_export.pdf';
    await File(path).writeAsBytes(await pdf.save());
    return path;
  }
}
