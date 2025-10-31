
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/expense_model.dart';
import 'package:hasbni/data/repositories/expense_repository.dart';
import 'expenses_state.dart';

class ExpensesCubit extends Cubit<ExpensesState> {
  final ExpenseRepository _repository;

  ExpensesCubit()
    : _repository = ExpenseRepository(),
      super(const ExpensesState());

  Future<void> loadExpenses() async {
    emit(state.copyWith(status: ExpensesStatus.loading));
    try {
      final expenses = await _repository.getExpenses();
      emit(state.copyWith(status: ExpensesStatus.success, expenses: expenses));
    } catch (e) {
      emit(
        state.copyWith(
          status: ExpensesStatus.failure,
          errorMessage: 'فشل تحميل المصروفات',
        ),
      );
    }
  }

  
  Future<void> addExpense({
    required Expense expense,
    required double rateToUsd,
  }) async {
    await _repository.addExpense(expense: expense, rateToUsd: rateToUsd);
    loadExpenses(); 
  }

  
  Future<void> updateExpense({
    required Expense expense,
    required double rateToUsd,
  }) async {
    await _repository.updateExpense(expense: expense, rateToUsd: rateToUsd);
    loadExpenses(); 
  }

  Future<void> deleteExpense(int id) async {
    await _repository.deleteExpense(id);
    loadExpenses(); 
  }
}
