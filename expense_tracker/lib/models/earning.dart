import 'package:hive/hive.dart';

part 'earning.g.dart';

@HiveType(typeId: 1)
class Earning {
  @HiveField(0)
  String id;

  @HiveField(1)
  String incomeSource;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String receiveMethod;

  @HiveField(4)
  DateTime date;

  Earning({
    required this.id,
    required this.incomeSource,
    required this.amount,
    required this.receiveMethod,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'incomeSource': incomeSource,
      'amount': amount,
      'receiveMethod': receiveMethod,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory Earning.fromMap(Map<String, dynamic> map) {
    return Earning(
      id: map['id'],
      incomeSource: map['incomeSource'],
      amount: (map['amount'] as num).toDouble(),
      receiveMethod: map['receiveMethod'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
}
