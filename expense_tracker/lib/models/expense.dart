import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense {
  @HiveField(0)
  String id;

  @HiveField(1)
  String category;

  @HiveField(2)
  String? subCategory;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String paymentMethod;

  @HiveField(5)
  DateTime date;

  Expense({
    required this.id,
    required this.category,
    this.subCategory,
    required this.amount,
    required this.paymentMethod,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'subCategory': subCategory,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      category: map['category'],
      subCategory: map['subCategory'],
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['paymentMethod'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
}
