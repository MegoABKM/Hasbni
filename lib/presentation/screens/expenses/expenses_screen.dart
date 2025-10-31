
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/core/utils/extention_shortcut.dart';
import 'package:hasbni/core/utils/scale_config.dart';
import 'package:hasbni/data/models/expense_category_model.dart';
import 'package:hasbni/data/models/expense_model.dart';
import 'package:hasbni/presentation/cubits/expense_category/expense_category_cubit.dart';
import 'package:hasbni/presentation/cubits/expenses/expenses_cubit.dart';
import 'package:hasbni/presentation/cubits/expenses/expenses_state.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/cubits/profile/profile_state.dart';
import 'package:intl/intl.dart';
import 'widgets/add_edit_expense_dialog.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  
  
  void _showAddEditDialog(BuildContext context, {Expense? expense}) {
    showDialog(
      context: context,
      builder: (_) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<ExpensesCubit>()),
            BlocProvider.value(value: context.read<ProfileCubit>()),
            BlocProvider.value(value: context.read<ExpenseCategoryCubit>()),
          ],
          
          child: AddEditExpenseDialog(expense: expense),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ExpensesCubit()..loadExpenses()),
        BlocProvider(create: (context) => ProfileCubit()..loadProfile()),
        BlocProvider(
          create: (context) => ExpenseCategoryCubit()..loadCategories(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'المصروفات',
            style: TextStyle(fontSize: scaleConfig.scaleText(20)),
          ),
        ),
        body: BlocBuilder<ExpenseCategoryCubit, ExpenseCategoryState>(
          builder: (context, categoryState) {
            return BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                if (profileState.status == ProfileStatus.loading ||
                    categoryState.status == CategoryStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return BlocBuilder<ExpensesCubit, ExpensesState>(
                  builder: (context, expenseState) {
                    if (expenseState.status == ExpensesStatus.loading &&
                        expenseState.expenses.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (expenseState.expenses.isEmpty) {
                      return Center(
                        child: Text(
                          'لا توجد مصروفات مسجلة.',
                          style: TextStyle(fontSize: scaleConfig.scaleText(16)),
                        ),
                      );
                    }

                    final categories = categoryState.categories;

                    return RefreshIndicator(
                      onRefresh: () async {
                        await context.read<ExpensesCubit>().loadExpenses();
                        await context
                            .read<ExpenseCategoryCubit>()
                            .loadCategories();
                      },
                      child: ListView.separated(
                        padding: EdgeInsets.all(scaleConfig.scale(8)),
                        itemCount: expenseState.expenses.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: scaleConfig.scale(8)),
                        itemBuilder: (ctx, index) {
                          final expense = expenseState.expenses[index];
                          final category = categories.firstWhere(
                            (c) => c.id == expense.categoryId,
                            orElse: () =>
                                const ExpenseCategory(id: -1, name: 'غير مصنف'),
                          );
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                scaleConfig.scale(12),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: scaleConfig.scale(16),
                                vertical: scaleConfig.scale(10),
                              ),
                              leading: _getIconForCategory(
                                category.name,
                                scaleConfig,
                              ),
                              title: Text(
                                expense.description,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: scaleConfig.scaleText(16),
                                ),
                              ),
                              subtitle: Text(
                                '${category.name} • ${DateFormat.yMMMd('ar').format(expense.expenseDate)}',
                                style: TextStyle(
                                  fontSize: scaleConfig.scaleText(13),
                                ),
                              ),
                              trailing: Text(
                                '${expense.amountInCurrency.toStringAsFixed(2)} ${expense.currencyCode}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                  fontSize: scaleConfig.scaleText(15),
                                ),
                              ),
                              
                              onTap: () {
                                _showAddEditDialog(context, expense: expense);
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            
            onPressed: () => _showAddEditDialog(context),
            tooltip: 'إضافة مصروف',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _getIconForCategory(String categoryName, ScaleConfig scaleConfig) {
    IconData iconData;
    switch (categoryName.toLowerCase()) {
      case 'إيجار':
      case 'rent':
        iconData = Icons.house_outlined;
        break;
      case 'رواتب':
      case 'salaries':
        iconData = Icons.people_outline;
        break;
      case 'كهرباء وماء':
      case 'utilities':
        iconData = Icons.lightbulb_outline;
        break;
      case 'صيانة':
      case 'maintenance':
        iconData = Icons.build_outlined;
        break;
      default:
        iconData = Icons.payment;
    }
    return CircleAvatar(
      radius: scaleConfig.scale(22),
      child: Icon(iconData, size: scaleConfig.scale(24)),
    );
  }
}
