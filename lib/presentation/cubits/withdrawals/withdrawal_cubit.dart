// lib/presentation/cubits/withdrawals/withdrawals_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/withdrawal_model.dart';
import 'package:hasbni/data/repositories/withdrawal_repository.dart';
import 'package:hasbni/presentation/cubits/withdrawals/withdrawal_state.dart';

class WithdrawalsCubit extends Cubit<WithdrawalsState> {
  final WithdrawalRepository _repository;

  WithdrawalsCubit()
    : _repository = WithdrawalRepository(),
      super(const WithdrawalsState());

  Future<void> loadWithdrawals() async {
    emit(state.copyWith(status: WithdrawalsStatus.loading));
    try {
      final withdrawals = await _repository.getWithdrawals();
      emit(
        state.copyWith(
          status: WithdrawalsStatus.success,
          withdrawals: withdrawals,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: WithdrawalsStatus.failure,
          errorMessage: 'فشل تحميل المسحوبات',
        ),
      );
    }
  }

  Future<void> addWithdrawal({
    required Withdrawal withdrawal,
    required double rateToUsd,
  }) async {
    await _repository.addWithdrawal(
      withdrawal: withdrawal,
      rateToUsd: rateToUsd,
    );
    loadWithdrawals();
  }

  // --- NEW METHOD FOR EDITING ---
  Future<void> updateWithdrawal({
    required Withdrawal withdrawal,
    required double rateToUsd,
  }) async {
    await _repository.updateWithdrawal(
      withdrawal: withdrawal,
      rateToUsd: rateToUsd,
    );
    loadWithdrawals();
  }

  Future<void> deleteWithdrawal(int id) async {
    await _repository.deleteWithdrawal(id);
    loadWithdrawals();
  }
}
