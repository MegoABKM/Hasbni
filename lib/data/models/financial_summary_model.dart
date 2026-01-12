import 'package:equatable/equatable.dart';

class FinancialSummary extends Equatable {
  final double totalRevenue;
  final double totalProfit;
  final double totalExpenses;
  final double totalWithdrawals;
  final double netProfit;
  final double inventoryValue;

  const FinancialSummary({
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalExpenses,
    required this.totalWithdrawals,
    required this.netProfit,
    required this.inventoryValue,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse any field
    double toDouble(dynamic val) => double.tryParse(val.toString()) ?? 0.0;

    return FinancialSummary(
      totalRevenue: toDouble(json['total_revenue']),
      totalProfit: toDouble(json['total_profit']),
      totalExpenses: toDouble(json['total_expenses']),
      totalWithdrawals: toDouble(json['total_withdrawals']),
      netProfit: toDouble(json['net_profit']),
      inventoryValue: toDouble(json['inventory_value']),
    );
  }

  factory FinancialSummary.empty() {
    return const FinancialSummary(
      totalRevenue: 0,
      totalProfit: 0,
      totalExpenses: 0,
      totalWithdrawals: 0,
      netProfit: 0,
      inventoryValue: 0,
    );
  }

  @override
  List<Object?> get props => [
    totalRevenue,
    totalProfit,
    totalExpenses,
    totalWithdrawals,
    netProfit,
    inventoryValue,
  ];
}