import 'package:hasbni/core/constants/api_constants.dart';
import 'package:hasbni/core/services/api_services.dart';
import 'package:hasbni/data/models/expense_category_model.dart';

class ExpenseCategoryRepository {
  final ApiService _api = ApiService();

  Future<List<ExpenseCategory>> getCategories() async {
    final List data = await _api.get(ApiConstants.expenseCategories);
    return data.map((item) => ExpenseCategory.fromJson(item)).toList();
  }

  Future<ExpenseCategory> addCategory(String name) async {
    final response = await _api.post(ApiConstants.expenseCategories, {'name': name});
    return ExpenseCategory.fromJson(response);
  }

  Future<void> deleteCategory(int id) async {
    await _api.delete('${ApiConstants.expenseCategories}/$id');
  }
}