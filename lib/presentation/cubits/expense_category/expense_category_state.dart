// lib/presentation/cubits/expense_category/expense_category_state.dart
part of 'expense_category_cubit.dart';

enum CategoryStatus { initial, loading, success, failure }

class ExpenseCategoryState extends Equatable {
  final CategoryStatus status;
  final List<ExpenseCategory> categories;

  const ExpenseCategoryState({
    this.status = CategoryStatus.initial,
    this.categories = const [],
  });

  ExpenseCategoryState copyWith({
    CategoryStatus? status,
    List<ExpenseCategory>? categories,
  }) {
    return ExpenseCategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
    );
  }

  @override
  List<Object> get props => [status, categories];
}
