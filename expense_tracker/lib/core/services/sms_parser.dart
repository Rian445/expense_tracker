import 'package:intl/intl.dart';
import 'regex_patterns.dart';
import 'bank_detector.dart';
import 'category_mapper.dart';

enum TransactionType { expense, earning }

/// Result of a successful SMS parse.
class ParsedTransaction {
  final double amount;
  final String merchant;
  final String category;
  final DateTime dateTime;
  final String bank;
  final double confidence; // 0.0 – 1.0
  final TransactionType type;

  const ParsedTransaction({
    required this.amount,
    required this.merchant,
    required this.category,
    required this.dateTime,
    required this.bank,
    required this.confidence,
    required this.type,
  });

  @override
  String toString() =>
      'ParsedTransaction(type: $type, amount: $amount, merchant: $merchant, '
      'category: $category, bank: $bank, confidence: $confidence)';
}

/// Stateless parser that converts raw SMS text into [ParsedExpense].
class SmsParser {
  SmsParser._();

  /// Returns null if the SMS is not a recognized transaction.
  static ParsedTransaction? parse(String sms, {String? sender, DateTime? receivedDate}) {
    // ── 1. Transaction type check ──────────────────────────────────────────
    final isExpense = RegexPatterns.expenseKeywords.hasMatch(sms);
    final isIncome = RegexPatterns.incomeKeywords.hasMatch(sms);
    
    // Determine type: prioritize Expense if clear debit words are found
    TransactionType type;
    if (isExpense && !sms.toLowerCase().contains('credited') && !sms.toLowerCase().contains('deposited')) {
      type = TransactionType.expense;
    } else if (isIncome) {
      type = TransactionType.earning;
    } else {
      type = TransactionType.expense;
    }

    // ── 2. Bank identification ─────────────────────────────────────────────
    // Check both the SMS body and the Sender name for bank keywords
    final bank = BankDetector.detect("$sms ${sender ?? ''}");

    // ── 2.1 Earning Filter (Bank Only) ─────────────────────────────────────
    if (type == TransactionType.earning) {
      // 1. Check for MFS exclusion (user doesn't want bKash/Nagad income)
      if (RegexPatterns.mfsExclusion.hasMatch(sms)) {
        return null;
      }
      
      // 2. Reject operator bonuses
      if (sms.toLowerCase().contains('bonus')) {
        return null;
      }

      // 3. Must look like a bank transaction (Bank name, A/C, account, or salary)
      final hasBankKeywords = sms.toLowerCase().contains('account') || 
                               sms.toLowerCase().contains('salary') ||
                               sms.toLowerCase().contains('ref:');
                               
      if (bank == BankDetector.unknown && !hasBankKeywords && !RegexPatterns.account.hasMatch(sms)) {
        return null;
      }
    }

    // ── 3. Amount parsing ──────────────────────────────────────────────────
    final amountMatch = _pickAmountPattern(bank).firstMatch(sms);
    if (amountMatch == null) return null;

    final rawAmount = (amountMatch.group(1) ?? amountMatch.group(2) ?? '').replaceAll(',', '');
    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) return null;

    // ── 4. Merchant parsing ────────────────────────────────────────────────
    final merchantMatch = RegexPatterns.merchant.firstMatch(sms);
    String rawMerchant = merchantMatch?.group(1)?.trim() ?? '';
    
    // Filter out generic noise (e.g., "from your account" -> "your account" is not a merchant)
    final noiseWords = ['your account', 'my account', 'account', 'a/c', 'the account'];
    if (noiseWords.contains(rawMerchant.toLowerCase())) {
      rawMerchant = '';
    }
    
    // Fallback 1: If no merchant found, try to extract a phone number
    if (rawMerchant.isEmpty) {
      final phoneMatch = RegExp(r'\b(01[3-9]\d{8})\b').firstMatch(sms);
      if (phoneMatch != null) {
        rawMerchant = phoneMatch.group(1)!;
      }
    }

    // Fallback 2: Internet packs and generic recharges
    if (rawMerchant.isEmpty) {
      if (RegExp(r'\b(internet pack|bundle|gb|mb|data|minute|mins)\b', caseSensitive: false).hasMatch(sms)) {
        rawMerchant = 'Internet Recharge';
      } else if (RegExp(r'\b(recharge|top-up|topup|flexiload)\b', caseSensitive: false).hasMatch(sms)) {
        rawMerchant = 'Mobile Recharge';
      }
    }

    // Fallback 3: Use sender name if merchant is still unknown
    if (rawMerchant.isEmpty && sender != null && sender.isNotEmpty) {
      rawMerchant = sender;
    }

    // Resolve truncated bank names (e.g., "City" -> "CityBank")
    final detectedBank = BankDetector.detect(rawMerchant);
    if (detectedBank != BankDetector.unknown) {
      rawMerchant = detectedBank;
    }

    final merchant = CategoryMapper.clean(rawMerchant);

    // ── 5. Category mapping (pass full SMS for context) ────────────────────
    final category = CategoryMapper.map(merchant, sms);

    // ── 6. Date/time parsing ──────────────────────────────────────────────
    final dateTime = _parseDateTime(sms, receivedDate);

    // ── 7. Confidence score ────────────────────────────────────────────────
    double confidence = 0.5;
    if (merchantMatch != null) confidence += 0.2;
    if (dateTime != DateTime.now()) confidence += 0.2;
    if (bank != BankDetector.unknown) confidence += 0.1;

    return ParsedTransaction(
      amount: amount,
      merchant: merchant.isEmpty ? (type == TransactionType.earning ? 'Income' : 'Unknown Merchant') : merchant,
      category: category,
      dateTime: dateTime,
      bank: bank,
      confidence: confidence.clamp(0.0, 1.0),
      type: type,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static RegExp _pickAmountPattern(String bank) {
    switch (bank) {
      case 'UCB':  return RegexPatterns.ucbAmount;
      case 'DBBL': return RegexPatterns.dbblAmount;
      case 'BRAC': return RegexPatterns.bracAmount;
      default:     return RegexPatterns.amount;
    }
  }

  static DateTime _parseDateTime(String sms, DateTime? fallbackDate) {
    final now = fallbackDate ?? DateTime.now();
    
    // Find all potential dates
    final dateMatches = RegexPatterns.date.allMatches(sms);
    Match? validDateMatch;
    
    for (final match in dateMatches) {
      // Check the text just before the date to see if it's an expiration date
      final prefix = sms.substring(0, match.start).toLowerCase();
      if (!prefix.endsWith('till ') && !prefix.endsWith('validity ') && !prefix.endsWith('valid ')) {
        validDateMatch = match;
        break;
      }
    }

    final timeMatch = RegexPatterns.time.firstMatch(sms);

    DateTime date = now;

    if (validDateMatch != null) {
      final raw = validDateMatch.group(1)!;
      date = _tryParseDate(raw) ?? now;
    }

    if (timeMatch != null) {
      final parts = timeMatch.group(1)!.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      date = DateTime(date.year, date.month, date.day, hour, minute);
    }

    return date;
  }

  static DateTime? _tryParseDate(String raw) {
    final formats = [
      DateFormat('dd MMM yyyy'),
      DateFormat('dd/MM/yy'),
      DateFormat('dd-MM-yy'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('dd-MM-yyyy'),
    ];
    for (final fmt in formats) {
      try {
        return fmt.parseStrict(raw);
      } catch (_) {}
    }
    return null;
  }
}
