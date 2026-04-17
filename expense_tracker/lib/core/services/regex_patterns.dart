/// Central registry for all SMS parsing regex patterns.
class RegexPatterns {
  RegexPatterns._();

  // ─── Amount ──────────────────────────────────────────────────────────────
  /// Matches: BDT 1,070.00  |  BDT1000.00  |  Tk 500.00  |  TK500 | 1200 taka
  static final amount = RegExp(
    r'(?:BDT|Tk\.?|TK|tk)\s?([\d,]+(?:\.\d{1,2})?)|\b([\d,]+(?:\.\d{1,2})?)\s?(?:taka|TK|Tk|BDT)\b',
    caseSensitive: false,
  );

  // ─── Merchant ─────────────────────────────────────────────────────────────
  /// Matches "at MERCHANT_NAME" up to next keyword
  static final merchant = RegExp(
    r'(?:at|to|from|for your|recharged)\s+(.+?)(?:\s+with|\s+has been|\s+confirmed|\s+completed|\s+successful|\s+order|\s+on|\s+at\s+\d|\.|$)',
    caseSensitive: false,
  );

  // ─── Date (multi-format) ─────────────────────────────────────────────────
  static final date = RegExp(
    r'(\d{2}[\/\-]\d{2}[\/\-]\d{2,4}|\d{2}\s[A-Za-z]{3}\s\d{4})',
  );

  // ─── Account Detection ────────────────────────────────────────────────────
  static final account = RegExp(r'A\/C\s?[A-Z0-9Xx]{3,}', caseSensitive: false);

  // ─── Time ────────────────────────────────────────────────────────────────
  static final time = RegExp(r'(\d{2}:\d{2})');

  // ─── Transaction Type ─────────────────────────────────────────────────────
  static final expenseKeywords = RegExp(
    r'\b(charged|debited|spent|purchase|purchased|used|payment|deducted|withdrawn|transaction|paid|sent|cash out|cashed out|fare|order|bill|fee|recharge|recharged|top-up|topup|flexiload|bundle|pack)\b',
    caseSensitive: false,
  );

  static final incomeKeywords = RegExp(
    r'\b(credited|deposited|received|added|salary|refund|cashback|remittance|EFT|RTGS|transferred|add kora hoyeche)\b',
    caseSensitive: false,
  );

  static final mfsExclusion = RegExp(
    r'\b(bkash|nagad|rocket|wallet|mfs|cash in|agent)\b',
    caseSensitive: false,
  );

  // ─── Bank-specific overrides ──────────────────────────────────────────────
  static final ucbAmount = RegExp(r'(?:BDT|Tk\.?|TK)\s?([\d,]+\.\d{2})', caseSensitive: false);
  static final dbblAmount = RegExp(r'(?:BDT|Tk\.?|TK)\s?([\d,]+\.\d{2})', caseSensitive: false);
  static final bracAmount = RegExp(r'(?:BDT|Tk\.?|TK)\s?([\d,]+(?:\.\d{2})?)', caseSensitive: false);
}
