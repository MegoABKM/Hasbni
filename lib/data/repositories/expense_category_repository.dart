import 'package:hasbni/core/services/database_service.dart';
import 'package:hasbni/data/models/expense_category_model.dart';

class ExpenseCategoryRepository {
  final DatabaseService _db = DatabaseService();

  // GET: From Local DB
  Future<List<ExpenseCategory>> getCategories() async {
    final db = await _db.database;
    // Get all except deleted
    final List<Map<String, dynamic>> maps = await db.query(
      'expense_categories',
      where: 'sync_status != 3',
    );
    return maps.map((item) => ExpenseCategory(
      id: item['local_id'], // Use local_id for UI linkage
      name: item['name'],
    )).toList();
  }

  // ADD: Save to Local DB
  Future<void> addCategory(String name) async {
    final db = await _db.database;
    await db.insert('expense_categories', {
      'name': name,
      'sync_status': 1, // 1 = Created Locally
    });
  }

  // DELETE
  Future<void> deleteCategory(int localId) async {
    final db = await _db.database;
    await db.update('expense_categories', 
      {'sync_status': 3}, 
      where: 'local_id = ?', 
      whereArgs: [localId]
    );
  }
}