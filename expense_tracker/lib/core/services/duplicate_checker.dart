import '../../models/expense.dart';

/// Prevents inserting duplicate SMS-parsed expenses.
/// A duplicate is: same amount + same merchant + within [windowSeconds].
class DuplicateChecker {
  DuplicateChecker._();

  static const int windowSeconds = 120; // 2 minutes

  static bool isDuplicate(
    List<Expense> existing,
    double amount,
    String merchant,
    DateTime dateTime,
  ) {
    final window = Duration(seconds: windowSeconds);
    return existing.any((e) {
      if (!e.isAuto) return false; // only check auto entries
      final sameAmount = e.amount == amount;
      final sameMerchant = (e.subCategory ?? '').toLowerCase() == merchant.toLowerCase();
      final timeDiff = e.date.difference(dateTime).abs();
      return sameAmount && sameMerchant && timeDiff <= window;
    });
  }
}
