import 'package:hasbni/core/constants/api_constants.dart';
import 'package:hasbni/core/services/api_services.dart';
import 'package:hasbni/core/services/database_service.dart';
import 'package:hasbni/data/models/chart_data_model.dart';
import 'package:hasbni/data/models/dairy_item_model.dart';
import 'package:hasbni/data/models/expense_model.dart';
import 'package:hasbni/data/models/financial_summary_model.dart';
import 'package:hasbni/data/models/sale_model.dart';
import 'package:hasbni/data/models/withdrawal_model.dart';

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

  Future<List<DiaryItem>> getDiaryEntries({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _db.database;
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();
    final List<DiaryItem> items = [];

    // 1. Fetch Sales
    final salesMaps = await db.query(
      'sales',
      where: 'created_at BETWEEN ? AND ? AND sync_status != 3',
      whereArgs: [startStr, endStr],
    );
    for (var map in salesMaps) {
      // Manual mapping to ensure ID correctness
      final sale = Sale.fromJson({
        'id': map['local_id'], // Local ID for UI
        'total_price': map['total_price'],
        'currency_code': map['currency_code'],
        'created_at': map['created_at'],
      });
      
      // Calculate normalized USD amount for sorting/logic
      double rate = (map['rate_to_usd_at_sale'] as num?)?.toDouble() ?? 1.0;
      if (rate <= 0) rate = 1.0;
      
      items.add(DiaryItem(
        date: sale.createdAt,
        type: DiaryType.sale,
        amount: sale.totalPrice / rate,
        originalItem: sale,
      ));
    }

    // 2. Fetch Expenses
    final expMaps = await db.query(
      'expenses',
      where: 'expense_date BETWEEN ? AND ? AND sync_status != 3',
      whereArgs: [startStr, endStr],
    );
    for (var map in expMaps) {
      final expense = Expense.fromJson({
        'id': map['local_id'],
        'description': map['description'] ?? '',
        'amount': map['amount'], // Already USD in DB
        'amount_in_currency': map['amount_in_currency'],
        'currency_code': map['currency_code'],
        'expense_date': map['expense_date'],
        'category_id': map['category_local_id'],
        'recurrence': map['recurrence'],
      });
      items.add(DiaryItem(
        date: expense.expenseDate,
        type: DiaryType.expense,
        amount: expense.amount,
        originalItem: expense,
      ));
    }

    // 3. Fetch Withdrawals
    final withMaps = await db.query(
      'withdrawals',
      where: 'withdrawal_date BETWEEN ? AND ? AND sync_status != 3',
      whereArgs: [startStr, endStr],
    );
    for (var map in withMaps) {
      final withdrawal = Withdrawal.fromJson({
        'id': map['local_id'],
        'description': map['description'],
        'amount': map['amount'], // Already USD
        'amount_in_currency': map['amount_in_currency'],
        'currency_code': map['currency_code'],
        'withdrawal_date': map['withdrawal_date'],
      });
      items.add(DiaryItem(
        date: withdrawal.withdrawalDate,
        type: DiaryType.withdrawal,
        amount: withdrawal.amount,
        originalItem: withdrawal,
      ));
    }

    // 4. Sort by Date Descending (Newest first)
    items.sort((a, b) => b.date.compareTo(a.date));

    return items;
  }




     Future<List<DailyFinancialData>> getChartData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Re-use existing method to get raw data
    final items = await getDiaryEntries(startDate: startDate, endDate: endDate);
    
    // Sort oldest to newest for the chart X-axis
    items.sort((a, b) => a.date.compareTo(b.date));

    final Map<String, DailyFinancialData> groupedData = {};

    for (var item in items) {
      // Key by Date (YYYY-MM-DD) to group daily
      final key = "${item.date.year}-${item.date.month}-${item.date.day}";
      
      // Initialize if not exists
      if (!groupedData.containsKey(key)) {
        groupedData[key] = DailyFinancialData(
          date: DateTime(item.date.year, item.date.month, item.date.day),
          revenue: 0,
          expenses: 0,
          profit: 0,
        );
      }

      final current = groupedData[key]!;
      
      double newRev = current.revenue;
      double newExp = current.expenses;
      double newProfit = current.profit;

      if (item.type == DiaryType.sale) {
        newRev += item.amount;
        // Approximation: We don't have profit per diary item easily in DiaryItem model yet
        // For accurate profit chart, ideally DiaryItem should hold cost.
        // Let's assume you fetch Sale object which has profit calculation inside
        // For MVP chart, let's just use Revenue. 
        // Better: In getDiaryEntries, store 'profit' in DiaryItem if type is sale.
        final sale = item.originalItem as Sale;
        // Warning: This requires 'profit' to be added to Sale model & DB query
        // If not available, we chart Revenue vs Expense only.
      } else if (item.type == DiaryType.expense) {
        newExp += item.amount;
      }

      groupedData[key] = DailyFinancialData(
        date: current.date,
        revenue: newRev,
        expenses: newExp,
        profit: newRev - newExp, // Gross estimation
      );
    }

    return groupedData.values.toList();
  }
  
}