// lib/data/repositories/expense_repository.dart
import 'package:hasbni/data/models/expense_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String _tableName = 'expenses';

  Future<List<Expense>> getExpenses() async {
    // Join with categories table to get the category name
    final data = await _client
        .from(_tableName)
        .select(
          '*, currency_code, amount_in_currency, category_id, recurrence, category:expense_categories(name)',
        )
        .order('expense_date', ascending: false);

    // We need to manually parse the nested category object
    return data.map((item) {
      final expense = Expense.fromJson(item);
      // ignore: unused_local_variable
      final categoryName =
          (item['category'] as Map<String, dynamic>?)?['name'] as String?;
      // While we don't store the name in the model, we could use it here if needed.
      // For now, the model is fine, but this shows how to fetch it.
      return expense;
    }).toList();
  }

  // MODIFIED: addExpense now requires the rate to calculate the USD amount
  Future<void> addExpense({
    required Expense expense,
    required double rateToUsd,
  }) async {
    final dataToInsert = expense.toJson();
    // Calculate the USD amount before inserting
    final amountInUsd = expense.amountInCurrency / rateToUsd;

    dataToInsert['amount'] = amountInUsd;
    dataToInsert['rate_to_usd_at_expense'] = rateToUsd;

    await _client.from(_tableName).insert(dataToInsert);
  }

  // MODIFIED: updateExpense now also requires the rate
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
