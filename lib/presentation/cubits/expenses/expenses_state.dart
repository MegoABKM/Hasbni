// lib/presentation/cubits/expenses/expenses_state.dart
import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/expense_model.dart';

enum ExpensesStatus { initial, loading, success, failure }

class ExpensesState extends Equatable {
  final ExpensesStatus status;
  final List<Expense> expenses;
  final String? errorMessage;

  const ExpensesState({
    this.status = ExpensesStatus.initial,
    this.expenses = const [],
    this.errorMessage,
  });

  ExpensesState copyWith({
    ExpensesStatus? status,
    List<Expense>? expenses,
    String? errorMessage,
  }) {
    return ExpensesState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, expenses, errorMessage];
}
