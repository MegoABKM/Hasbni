import 'package:hasbni/core/constants/api_constants.dart';
import 'package:hasbni/core/services/api_services.dart';
import 'package:hasbni/data/models/expense_model.dart';

class ExpenseRepository {
  final ApiService _api = ApiService();

  Future<List<Expense>> getExpenses() async {
    final List data = await _api.get(ApiConstants.expenses);
    return data.map((item) => Expense.fromJson(item)).toList();
  }

  Future<void> addExpense({required Expense expense, required double rateToUsd}) async {
    final data = expense.toJson();
    data['amount'] = expense.amountInCurrency / rateToUsd;
    data['rate_to_usd_at_expense'] = rateToUsd;
    await _api.post(ApiConstants.expenses, data);
  }

  Future<void> updateExpense({required Expense expense, required double rateToUsd}) async {
    final data = expense.toJson();
    data['amount'] = expense.amountInCurrency / rateToUsd;
    data['rate_to_usd_at_expense'] = rateToUsd;
    await _api.put('${ApiConstants.expenses}/${expense.id}', data);
  }

  Future<void> deleteExpense(int id) async {
    await _api.delete('${ApiConstants.expenses}/$id');
  }
}