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

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _selectedMonth = DateTime.now();

  void _showAddEditDialog(BuildContext context, {Expense? expense}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return MultiBlocProvider(
          providers: [
            // Use value to pass existing instances from the screen's context
            BlocProvider.value(value: context.read<ExpensesCubit>()),
            BlocProvider.value(value: context.read<ProfileCubit>()),
            BlocProvider.value(value: context.read<ExpenseCategoryCubit>()),
          ],
          child: AddEditExpenseDialog(expense: expense),
        );
      },
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'اختر الشهر والسنة',
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ExpensesCubit()..loadExpenses()),
        BlocProvider(create: (context) => ProfileCubit()..loadProfile()),
        BlocProvider(create: (context) => ExpenseCategoryCubit()..loadCategories()),
      ],
      // Wrap Scaffold in Builder to ensure FAB has access to the Providers above
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: InkWell(
                onTap: () => _pickMonth(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'المصروفات: ${DateFormat.yMMM('ar').format(_selectedMonth)}',
                      style: TextStyle(fontSize: scaleConfig.scaleText(18)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              centerTitle: true,
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

                        // 1. Filter by Selected Month
                        final filteredExpenses = expenseState.expenses.where((e) {
                          return e.expenseDate.year == _selectedMonth.year &&
                              e.expenseDate.month == _selectedMonth.month;
                        }).toList();

                        if (filteredExpenses.isEmpty) {
                          return Center(
                            child: Text(
                              'لا توجد مصروفات في ${DateFormat.yMMM('ar').format(_selectedMonth)}.',
                              style: TextStyle(fontSize: scaleConfig.scaleText(16)),
                            ),
                          );
                        }

                        final categories = categoryState.categories;

                        // 2. Group by Date
                        final groupedExpenses = <String, List<Expense>>{};
                        for (var expense in filteredExpenses) {
                          final dateKey = DateFormat('yyyy-MM-dd').format(expense.expenseDate);
                          if (!groupedExpenses.containsKey(dateKey)) {
                            groupedExpenses[dateKey] = [];
                          }
                          groupedExpenses[dateKey]!.add(expense);
                        }
                        // Sort keys (dates) descending
                        final sortedKeys = groupedExpenses.keys.toList()
                          ..sort((a, b) => b.compareTo(a));

                        return RefreshIndicator(
                          onRefresh: () async {
                            await context.read<ExpensesCubit>().loadExpenses();
                            await context.read<ExpenseCategoryCubit>().loadCategories();
                          },
                          child: ListView.builder(
                            padding: EdgeInsets.all(scaleConfig.scale(8)),
                            itemCount: sortedKeys.length,
                            itemBuilder: (ctx, index) {
                              final dateKey = sortedKeys[index];
                              final dayExpenses = groupedExpenses[dateKey]!;
                              final date = DateTime.parse(dateKey);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date Header
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 4.0),
                                    child: Text(
                                      _formatDateHeader(date),
                                      style: TextStyle(
                                        fontSize: scaleConfig.scaleText(14),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  // Items
                                  ...dayExpenses.map((expense) {
                                    final category = categories.firstWhere(
                                      (c) => c.id == expense.categoryId,
                                      orElse: () =>
                                          const ExpenseCategory(id: -1, name: 'غير مصنف'),
                                    );
                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(scaleConfig.scale(12)),
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: scaleConfig.scale(16),
                                          vertical: scaleConfig.scale(8),
                                        ),
                                        leading: _getIconForCategory(
                                            category.name, scaleConfig),
                                        title: Text(
                                          expense.description,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: scaleConfig.scaleText(16),
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${category.name} • ${DateFormat('hh:mm a', 'ar').format(expense.expenseDate)}',
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
                                  }).toList(),
                                ],
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
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddEditDialog(context),
              tooltip: 'إضافة مصروف',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'اليوم';
    if (checkDate == yesterday) return 'أمس';
    return DateFormat.yMMMd('ar').format(date);
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