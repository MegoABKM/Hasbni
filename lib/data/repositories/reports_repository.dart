import 'package:hasbni/core/constants/api_constants.dart';
import 'package:hasbni/core/services/api_services.dart';
import 'package:hasbni/core/services/database_service.dart';
import 'package:hasbni/data/models/financial_summary_model.dart';

class ReportsRepository {
  final ApiService _api = ApiService();
  final DatabaseService _db = DatabaseService();

  Future<FinancialSummary> getFinancialSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Try API first
      final result = await _api.post(ApiConstants.financialSummary, {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });
      return FinancialSummary.fromJson(result);
    } catch (e) {
      print("⚠️ Offline Mode: Calculating reports locally...");
      return await _calculateLocalSummary(startDate, endDate);
    }
  }

  Future<FinancialSummary> _calculateLocalSummary(DateTime start, DateTime end) async {
    final db = await _db.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    // 1. Total Revenue (Sales) - Sum of total_price converted to USD
    // We assume total_price in DB is in local currency, and we stored rate_to_usd_at_sale
    // Revenue USD = total_price / rate_to_usd
    final salesResult = await db.rawQuery('''
      SELECT SUM(total_price / CASE WHEN rate_to_usd_at_sale > 0 THEN rate_to_usd_at_sale ELSE 1 END) as total 
      FROM sales 
      WHERE created_at BETWEEN ? AND ? AND sync_status != 3
    ''', [startStr, endStr]);
    double revenue = (salesResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // 2. Calculate Profit (Complex without storing cost in sales table directly, approximation)
    // To be accurate offline, we should have stored 'total_profit' in sales table.
    // Let's assume you added 'total_profit' to sales table in DatabaseService or fetch from items.
    // For now, let's query sale_items to get profit: (price - cost) * qty
    final profitResult = await db.rawQuery('''
      SELECT SUM( ( (price / CASE WHEN s.rate_to_usd_at_sale > 0 THEN s.rate_to_usd_at_sale ELSE 1 END) - si.cost_price_at_sale ) * (si.quantity - si.returned_quantity) ) as profit
      FROM sale_items si
      JOIN sales s ON si.sale_local_id = s.local_id
      WHERE s.created_at BETWEEN ? AND ? AND s.sync_status != 3
    ''', [startStr, endStr]);
    double profit = (profitResult.first['profit'] as num?)?.toDouble() ?? 0.0;

    // 3. Expenses
    final expResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM expenses 
      WHERE expense_date BETWEEN ? AND ? AND sync_status != 3
    ''', [startStr, endStr]);
    double expenses = (expResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // 4. Withdrawals
    final withResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM withdrawals 
      WHERE withdrawal_date BETWEEN ? AND ? AND sync_status != 3
    ''', [startStr, endStr]);
    double withdrawals = (withResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // 5. Inventory Value
    final invResult = await db.rawQuery('''
      SELECT SUM(cost_price * quantity) as total FROM products WHERE sync_status != 3
    ''');
    double inventory = (invResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return FinancialSummary(
      totalRevenue: revenue,
      totalProfit: profit,
      totalExpenses: expenses,
      totalWithdrawals: withdrawals,
      netProfit: profit - expenses,
      inventoryValue: inventory,
    );
  }
}