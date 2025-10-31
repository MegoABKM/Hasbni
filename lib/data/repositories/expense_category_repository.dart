
import 'package:hasbni/data/models/expense_category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseCategoryRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String _tableName = 'expense_categories';

  Future<List<ExpenseCategory>> getCategories() async {
    final data = await _client.from(_tableName).select().order('name');
    return data.map((item) => ExpenseCategory.fromJson(item)).toList();
  }

  Future<ExpenseCategory> addCategory(String name) async {
    final response = await _client.from(_tableName).insert({
      'name': name,
    }).select();
    return ExpenseCategory.fromJson(response.first);
  }

  Future<void> deleteCategory(int id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }
}
