
import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/withdrawal_model.dart';

enum WithdrawalsStatus { initial, loading, success, failure }

class WithdrawalsState extends Equatable {
  final WithdrawalsStatus status;
  final List<Withdrawal> withdrawals;
  final String? errorMessage;

  const WithdrawalsState({
    this.status = WithdrawalsStatus.initial,
    this.withdrawals = const [],
    this.errorMessage,
  });

  WithdrawalsState copyWith({
    WithdrawalsStatus? status,
    List<Withdrawal>? withdrawals,
    String? errorMessage,
  }) {
    return WithdrawalsState(
      status: status ?? this.status,
      withdrawals: withdrawals ?? this.withdrawals,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, withdrawals, errorMessage];
}
