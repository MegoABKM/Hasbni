
import 'package:equatable/equatable.dart';

class Withdrawal extends Equatable {
  final int? id;
  final String? description;
  final double amount; 
  final DateTime withdrawalDate;

  
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
      amount: (json['amount'] as num).toDouble(), 
      withdrawalDate: DateTime.parse(json['withdrawal_date']),
      
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
