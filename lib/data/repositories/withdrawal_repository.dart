import 'package:hasbni/core/services/database_service.dart';
import 'package:hasbni/data/models/withdrawal_model.dart';

class WithdrawalRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<Withdrawal>> getWithdrawals() async {
    final db = await _db.database;
    final maps = await db.query('withdrawals', where: 'sync_status != 3', orderBy: 'withdrawal_date DESC');
    
    return maps.map((e) => Withdrawal.fromJson({
      'id': e['local_id'],
      'description': e['description'],
      'amount': e['amount'],
      'withdrawal_date': e['withdrawal_date'],
      'currency_code': e['currency_code'],
      'amount_in_currency': e['amount_in_currency']
    })).toList();
  }

  Future<void> addWithdrawal({required Withdrawal withdrawal, required double rateToUsd}) async {
    final db = await _db.database;
    await db.insert('withdrawals', {
      'description': withdrawal.description,
      'amount': withdrawal.amountInCurrency / rateToUsd,
      'amount_in_currency': withdrawal.amountInCurrency,
      'currency_code': withdrawal.currencyCode,
      'withdrawal_date': withdrawal.withdrawalDate.toIso8601String(),
      'sync_status': 1, // Created
    });
  }

  Future<void> updateWithdrawal({required Withdrawal withdrawal, required double rateToUsd}) async {
    final db = await _db.database;
    // Simplified update logic for brevity
    await db.update('withdrawals', {
      'description': withdrawal.description,
      'amount': withdrawal.amountInCurrency / rateToUsd,
      'amount_in_currency': withdrawal.amountInCurrency,
      'currency_code': withdrawal.currencyCode,
      'sync_status': 2, // Updated
    }, where: 'local_id = ?', whereArgs: [withdrawal.id]);
  }

  Future<void> deleteWithdrawal(int localId) async {
    final db = await _db.database;
    await db.update('withdrawals', {'sync_status': 3}, where: 'local_id = ?', whereArgs: [localId]);
  }
}