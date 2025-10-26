// lib/data/repositories/withdrawal_repository.dart
import 'package:hasbni/data/models/withdrawal_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WithdrawalRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String _tableName = 'owner_withdrawals';

  Future<List<Withdrawal>> getWithdrawals() async {
    final data = await _client
        .from(_tableName)
        .select('*, currency_code, amount_in_currency')
        .order('withdrawal_date', ascending: false);
    return data.map((item) => Withdrawal.fromJson(item)).toList();
  }

  Future<void> addWithdrawal({
    required Withdrawal withdrawal,
    required double rateToUsd,
  }) async {
    final dataToInsert = withdrawal.toJson();
    final amountInUsd = withdrawal.amountInCurrency / rateToUsd;
    dataToInsert['amount'] = amountInUsd;
    dataToInsert['rate_to_usd_at_withdrawal'] = rateToUsd;
    await _client.from(_tableName).insert(dataToInsert);
  }

  // --- NEW METHOD FOR EDITING ---
  Future<void> updateWithdrawal({
    required Withdrawal withdrawal,
    required double rateToUsd,
  }) async {
    final dataToUpdate = withdrawal.toJson();
    final amountInUsd = withdrawal.amountInCurrency / rateToUsd;
    dataToUpdate['amount'] = amountInUsd;
    dataToUpdate['rate_to_usd_at_withdrawal'] = rateToUsd;
    await _client
        .from(_tableName)
        .update(dataToUpdate)
        .eq('id', withdrawal.id!);
  }

  Future<void> deleteWithdrawal(int id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }
}
