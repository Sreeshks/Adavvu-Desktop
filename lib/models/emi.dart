import 'package:uuid/uuid.dart';
import 'payment.dart';

class EMI {
  String id;
  String name;
  double totalAmount;
  double monthlyPayment;
  int tenureMonths;
  int paidMonths;
  DateTime startDate;
  DateTime nextDueDate;
  List<Payment> payments;

  EMI({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.monthlyPayment,
    required this.tenureMonths,
    required this.paidMonths,
    required this.startDate,
    required this.nextDueDate,
    required this.payments,
  });

  double get remainingAmount => totalAmount - (monthlyPayment * paidMonths);
  int get remainingMonths => tenureMonths - paidMonths;
  double get percentageCompleted => (paidMonths / tenureMonths) * 100;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'monthlyPayment': monthlyPayment,
      'tenureMonths': tenureMonths,
      'paidMonths': paidMonths,
      'startDate': startDate.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'payments': payments.map((payment) => payment.toJson()).toList(),
    };
  }

  factory EMI.fromJson(Map<String, dynamic> json) {
    return EMI(
      id: json['id'],
      name: json['name'],
      totalAmount: json['totalAmount'],
      monthlyPayment: json['monthlyPayment'],
      tenureMonths: json['tenureMonths'],
      paidMonths: json['paidMonths'],
      startDate: DateTime.parse(json['startDate']),
      nextDueDate: DateTime.parse(json['nextDueDate']),
      payments:
          (json['payments'] as List)
              .map((payment) => Payment.fromJson(payment))
              .toList(),
    );
  }
}
