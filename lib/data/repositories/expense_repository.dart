import 'package:hasbni/core/services/database_service.dart';
import 'package:hasbni/data/models/expense_model.dart';

class ExpenseRepository {
  final DatabaseService _db = DatabaseService();

  // GET: Fetch from Local DB
  Future<List<Expense>> getExpenses() async {
    final db = await _db.database;
    // Get all except deleted
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'sync_status != 3',
      orderBy: 'expense_date DESC',
    );
    
    return maps.map((e) {
      return Expense(
        id: e['local_id'], // Use local_id for UI
        description: e['description'] ?? '',
        amount: (e['amount'] as num).toDouble(),
        expenseDate: DateTime.parse(e['expense_date']),
        currencyCode: e['currency_code'] ?? 'USD',
        amountInCurrency: (e['amount_in_currency'] ?? e['amount'] as num).toDouble(),
        categoryId: e['category_local_id'],
        recurrence: e['recurrence'] ?? 'one_time',
      );
    }).toList();
  }

  // ADD: Save to Local DB with sync_status = 1
  Future<void> addExpense({required Expense expense, required double rateToUsd}) async {
    final db = await _db.database;
    await db.insert('expenses', {
      'description': expense.description,
      'amount': expense.amountInCurrency / rateToUsd, // Normalized USD
      'amount_in_currency': expense.amountInCurrency,
      'currency_code': expense.currencyCode,
      'expense_date': expense.expenseDate.toIso8601String(),
      'category_local_id': expense.categoryId,
      'recurrence': expense.recurrence,
      'sync_status': 1, // 1 = Created Locally
    });
  }

  // UPDATE: Set sync_status = 2
  Future<void> updateExpense({required Expense expense, required double rateToUsd}) async {
    final db = await _db.database;
    
    // Check current status
    final existing = await db.query('expenses', where: 'local_id = ?', whereArgs: [expense.id]);
    int newStatus = 2; 
    if (existing.isNotEmpty && existing.first['sync_status'] == 1) {
      newStatus = 1; // Keep as 'Created' if not synced yet
    }

    await db.update('expenses', {
      'description': expense.description,
      'amount': expense.amountInCurrency / rateToUsd,
      'amount_in_currency': expense.amountInCurrency,
      'currency_code': expense.currencyCode,
      'expense_date': expense.expenseDate.toIso8601String(),
      'category_local_id': expense.categoryId,
      'recurrence': expense.recurrence,
      'sync_status': newStatus
    }, where: 'local_id = ?', whereArgs: [expense.id]);
  }

  // DELETE: Set sync_status = 3
  Future<void> deleteExpense(int localId) async {
    final db = await _db.database;
    final existing = await db.query('expenses', where: 'local_id = ?', whereArgs: [localId]);
    
    if (existing.isNotEmpty) {
      if (existing.first['sync_status'] == 1) {
        // Not on server yet, safe to hard delete
        await db.delete('expenses', where: 'local_id = ?', whereArgs: [localId]);
      } else {
        // Exists on server, soft delete
        await db.update('expenses', {'sync_status': 3}, where: 'local_id = ?', whereArgs: [localId]);
      }
    }
  }
}