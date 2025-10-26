// lib/data/models/expense_model.dart
import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final int? id;
  final String description;
  final double amount;
  final DateTime expenseDate;
  final String currencyCode;
  final double amountInCurrency;

  // NEW FIELDS
  final int? categoryId;
  final String recurrence; // 'one_time', 'daily', 'monthly', 'yearly'

  const Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.expenseDate,
    required this.currencyCode,
    required this.amountInCurrency,
    this.categoryId,
    required this.recurrence,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expense_date']),
      currencyCode: json['currency_code'] ?? 'USD',
      amountInCurrency:
          (json['amount_in_currency'] as num?)?.toDouble() ??
          (json['amount'] as num).toDouble(),
      categoryId: json['category_id'],
      recurrence: json['recurrence'] ?? 'one_time',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'description': description,
      'amount_in_currency': amountInCurrency,
      'currency_code': currencyCode,
      'expense_date': expenseDate.toIso8601String(),
      'category_id': categoryId,
      'recurrence': recurrence,
    };
  }

  @override
  List<Object?> get props => [
    id,
    description,
    amount,
    expenseDate,
    currencyCode,
    amountInCurrency,
    categoryId,
    recurrence,
  ];
}
