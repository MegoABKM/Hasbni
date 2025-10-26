// lib/data/models/withdrawal_model.dart
import 'package:equatable/equatable.dart';

class Withdrawal extends Equatable {
  final int? id;
  final String? description;
  final double amount; // This will now always be the USD amount
  final DateTime withdrawalDate;

  // NEW FIELDS
  final String currencyCode;
  final double amountInCurrency;

  const Withdrawal({
    this.id,
    this.description,
    required this.amount,
    required this.withdrawalDate,
    required this.currencyCode,
    required this.amountInCurrency,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['id'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(), // The stored USD amount
      withdrawalDate: DateTime.parse(json['withdrawal_date']),
      // Populate new fields
      currencyCode: json['currency_code'] ?? 'USD',
      amountInCurrency:
          (json['amount_in_currency'] as num?)?.toDouble() ??
          (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'description': description,
      // 'amount' will be calculated in the repository
      'amount_in_currency': amountInCurrency,
      'currency_code': currencyCode,
      'withdrawal_date': withdrawalDate.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    description,
    amount,
    withdrawalDate,
    currencyCode,
    amountInCurrency,
  ];
}
