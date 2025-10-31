
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/expense_category_model.dart';
import 'package:hasbni/data/repositories/expense_category_repository.dart';
import 'package:equatable/equatable.dart';

part 'expense_category_state.dart';

class ExpenseCategoryCubit extends Cubit<ExpenseCategoryState> {
  final ExpenseCategoryRepository _repository;

  ExpenseCategoryCubit()
    : _repository = ExpenseCategoryRepository(),
      super(const ExpenseCategoryState());

  Future<void> loadCategories() async {
    emit(state.copyWith(status: CategoryStatus.loading));
    try {
      final categories = await _repository.getCategories();
      emit(
        state.copyWith(status: CategoryStatus.success, categories: categories),
      );
    } catch (e) {
      emit(state.copyWith(status: CategoryStatus.failure));
    }
  }

  Future<void> addCategory(String name) async {
    try {
      await _repository.addCategory(name);
      await loadCategories(); 
    } catch (e) {
      
    }
  }
}
