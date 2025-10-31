
import 'package:hasbni/data/models/expense_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String _tableName = 'expenses';

  Future<List<Expense>> getExpenses() async {
    
    final data = await _client
        .from(_tableName)
        .select(
          '*, currency_code, amount_in_currency, category_id, recurrence, category:expense_categories(name)',
        )
        .order('expense_date', ascending: false);

    
    return data.map((item) {
      final expense = Expense.fromJson(item);
      
      final categoryName =
          (item['category'] as Map<String, dynamic>?)?['name'] as String?;
      
      
      return expense;
    }).toList();
  }

  
  Future<void> addExpense({
    required Expense expense,
    required double rateToUsd,
  }) async {
    final dataToInsert = expense.toJson();
    
    final amountInUsd = expense.amountInCurrency / rateToUsd;

    dataToInsert['amount'] = amountInUsd;
    dataToInsert['rate_to_usd_at_expense'] = rateToUsd;

    await _client.from(_tableName).insert(dataToInsert);
  }

  
  Future<void> updateExpense({
    required Expense expense,
    required double rateToUsd,
  }) async {
    final dataToUpdate = expense.toJson();
    final amountInUsd = expense.amountInCurrency / rateToUsd;

    dataToUpdate['amount'] = amountInUsd;
    dataToUpdate['rate_to_usd_at_expense'] = rateToUsd;

    await _client.from(_tableName).update(dataToUpdate).eq('id', expense.id!);
  }

  Future<void> deleteExpense(int id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }
}
