import 'package:hive/hive.dart';

part 'loan.g.dart';

@HiveType(typeId: 2)
class Loan extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final String purpose;
  @HiveField(3)
  final String loanFrom;
  @HiveField(4)
  final String duration;
  @HiveField(5)
  final String receiveMethod;
  @HiveField(6)
  final DateTime date;

  Loan({
    required this.id,
    required this.amount,
    required this.purpose,
    required this.loanFrom,
    required this.duration,
    required this.receiveMethod,
    required this.date,
  });
}
