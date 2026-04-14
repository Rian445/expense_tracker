import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../models/expense.dart';

/// An authenticated HTTP client that attaches the Google OAuth Bearer token.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request..headers.addAll(_headers));
  }
}

class GoogleSheetsService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [sheets.SheetsApi.spreadsheetsScope],
  );

  Future<void> exportToGoogleSheets(List<Expense> expenses) async {
    // Sign in the user (google_sign_in v6)
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Sign-in cancelled by user');

    // Get OAuth tokens
    final GoogleSignInAuthentication auth = await account.authentication;
    final String? accessToken = auth.accessToken;
    if (accessToken == null) throw Exception('Failed to get access token');

    // Build an authenticated HTTP client
    final authClient = _GoogleAuthClient({
      'Authorization': 'Bearer $accessToken',
      'X-Goog-AuthUser': '0',
    });

    final sheetsApi = sheets.SheetsApi(authClient);

    // Create a new spreadsheet
    final spreadsheet = sheets.Spreadsheet(
      properties: sheets.SpreadsheetProperties(
        title: 'Expense Export - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
      ),
    );
    final created = await sheetsApi.spreadsheets.create(spreadsheet);
    final spreadsheetId = created.spreadsheetId;
    if (spreadsheetId == null) throw Exception('Failed to create spreadsheet');

    // Prepare rows
    final List<List<Object>> rows = [
      ['Date', 'Category', 'Subcategory', 'Amount', 'Payment Method'],
      ...expenses.map((e) => [
        DateFormat('yyyy-MM-dd').format(e.date),
        e.category,
        e.subCategory ?? '',
        e.amount,
        e.paymentMethod,
      ]),
    ];

    await sheetsApi.spreadsheets.values.append(
      sheets.ValueRange(values: rows),
      spreadsheetId,
      'Sheet1!A1',
      valueInputOption: 'USER_ENTERED',
    );
  }
}
