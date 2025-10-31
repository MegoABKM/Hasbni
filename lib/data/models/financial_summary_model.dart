
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
    return FinancialSummary(
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      totalProfit: (json['total_profit'] as num).toDouble(),
      totalExpenses: (json['total_expenses'] as num).toDouble(),
      totalWithdrawals: (json['total_withdrawals'] as num).toDouble(),
      netProfit: (json['net_profit'] as num).toDouble(),
      inventoryValue: (json['inventory_value'] as num).toDouble(),
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
