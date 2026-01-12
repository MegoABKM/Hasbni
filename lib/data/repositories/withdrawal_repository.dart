import 'package:hasbni/core/constants/api_constants.dart';
import 'package:hasbni/core/services/api_services.dart';
import 'package:hasbni/data/models/withdrawal_model.dart';

class WithdrawalRepository {
  final ApiService _api = ApiService();

  Future<List<Withdrawal>> getWithdrawals() async {
    final List data = await _api.get(ApiConstants.withdrawals);
    return data.map((item) => Withdrawal.fromJson(item)).toList();
  }

  Future<void> addWithdrawal({required Withdrawal withdrawal, required double rateToUsd}) async {
    final data = withdrawal.toJson();
    data['amount'] = withdrawal.amountInCurrency / rateToUsd;
    data['rate_to_usd_at_withdrawal'] = rateToUsd;
    await _api.post(ApiConstants.withdrawals, data);
  }

  Future<void> updateWithdrawal({required Withdrawal withdrawal, required double rateToUsd}) async {
    final data = withdrawal.toJson();
    data['amount'] = withdrawal.amountInCurrency / rateToUsd;
    data['rate_to_usd_at_withdrawal'] = rateToUsd;
    await _api.put('${ApiConstants.withdrawals}/${withdrawal.id}', data);
  }

  Future<void> deleteWithdrawal(int id) async {
    await _api.delete('${ApiConstants.withdrawals}/$id');
  }
}