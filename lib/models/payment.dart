class Payment {
  String id;
  DateTime date;
  double amount;
  String note;

  Payment({
    required this.id,
    required this.date,
    required this.amount,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'note': note,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      date: DateTime.parse(json['date']),
      amount: json['amount'],
      note: json['note'] ?? '',
    );
  }
}
