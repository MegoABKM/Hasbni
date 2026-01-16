import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/core/utils/extention_shortcut.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:hasbni/data/models/expense_model.dart';
import 'package:hasbni/presentation/cubits/expense_category/expense_category_cubit.dart';
import 'package:hasbni/presentation/cubits/expenses/expenses_cubit.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:intl/intl.dart';

class AddEditExpenseDialog extends StatefulWidget {
  final Expense? expense;
  const AddEditExpenseDialog({super.key, this.expense});

  @override
  State<AddEditExpenseDialog> createState() => _AddEditExpenseDialogState();
}

class _AddEditExpenseDialogState extends State<AddEditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _selectedCurrency;
  late List<ExchangeRate> _availableRates;
  int? _selectedCategoryId;
  String _selectedRecurrence = 'one_time';

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileCubit>().state.profile;
    _availableRates = [
      const ExchangeRate(id: -1, currencyCode: 'USD', rateToUsd: 1.0),
      ...(profile?.exchangeRates ?? []),
    ];

    if (_isEditing) {
      final expense = widget.expense!;
      _descriptionController = TextEditingController(text: expense.description);
      _amountController = TextEditingController(
        text: expense.amountInCurrency.toString(),
      );
      _selectedDate = expense.expenseDate;
      _selectedCurrency = expense.currencyCode;
      _selectedCategoryId = expense.categoryId;
      _selectedRecurrence = expense.recurrence;
    } else {
      _descriptionController = TextEditingController();
      _amountController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedCurrency = 'USD';
      _selectedRecurrence = 'one_time';
      _selectedCategoryId = null;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final newCategoryController = TextEditingController();
    final newCategory = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة فئة جديدة'),
        content: TextFormField(
          controller: newCategoryController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'اسم الفئة'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newCategoryController.text.trim().isNotEmpty) {
                Navigator.of(dialogContext)
                    .pop(newCategoryController.text.trim());
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (newCategory != null && mounted) {
      await context.read<ExpenseCategoryCubit>().addCategory(newCategory);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار فئة للمصروف'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final expenseCubit = context.read<ExpensesCubit>();
      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final rate = _availableRates
          .firstWhere((r) => r.currencyCode == _selectedCurrency)
          .rateToUsd;

      final newExpense = Expense(
        id: widget.expense?.id,
        description: _descriptionController.text.trim(),
        amount: 0,
        amountInCurrency: amount,
        currencyCode: _selectedCurrency,
        expenseDate: _selectedDate,
        categoryId: _selectedCategoryId,
        recurrence: _selectedRecurrence,
      );

      if (_isEditing) {
        expenseCubit.updateExpense(expense: newExpense, rateToUsd: rate);
      } else {
        expenseCubit.addExpense(expense: newExpense, rateToUsd: rate);
      }

      Navigator.of(context).pop();
    }
  }

  void _delete() {
    if (!_isEditing) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا المصروف؟'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
            onPressed: () {
              context.read<ExpensesCubit>().deleteExpense(widget.expense!.id!);
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final categories = context.watch<ExpenseCategoryCubit>().state.categories;

    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل المصروف' : 'إضافة مصروف جديد',
        style: TextStyle(fontSize: scaleConfig.scaleText(20)),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int?>(
                value: _selectedCategoryId,
                hint: Text(
                  'اختر الفئة',
                  style: TextStyle(fontSize: scaleConfig.scaleText(14)),
                ),
                items: [
                  ...categories.map(
                    (cat) =>
                        DropdownMenuItem(value: cat.id, child: Text(cat.name)),
                  ),
                  const DropdownMenuItem(
                    value: -1,
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 8),
                        Text('إضافة فئة جديدة...'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == -1) {
                    _showAddCategoryDialog();
                  } else {
                    setState(() => _selectedCategoryId = value);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'فئة المصروف',
                  labelStyle: TextStyle(fontSize: scaleConfig.scaleText(16)),
                ),
                validator: (value) => value == null ? 'الفئة مطلوبة' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'وصف المصروف',
                  labelStyle: TextStyle(fontSize: scaleConfig.scaleText(16)),
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? 'الوصف مطلوب' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'المبلغ',
                        labelStyle: TextStyle(
                          fontSize: scaleConfig.scaleText(16),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'مطلوب';
                        }
                        if (double.tryParse(value) == null) {
                          return 'أدخل رقماً صحيحاً';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'العملة',
                        labelStyle: TextStyle(
                          fontSize: scaleConfig.scaleText(16),
                        ),
                      ),
                      items: _availableRates
                          .map(
                            (rate) => DropdownMenuItem(
                              value: rate.currencyCode,
                              child: Text(
                                rate.currencyCode,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCurrency = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRecurrence,
                decoration: InputDecoration(
                  labelText: 'تكرار المصروف',
                  labelStyle: TextStyle(fontSize: scaleConfig.scaleText(16)),
                ),
                items: const [
                  DropdownMenuItem(value: 'one_time', child: Text('مرة واحدة')),
                  DropdownMenuItem(value: 'daily', child: Text('يومي')),
                  DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                  DropdownMenuItem(value: 'yearly', child: Text('سنوي')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRecurrence = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  'تاريخ: ${DateFormat.yMMMd('ar').format(_selectedDate)}',
                  style: TextStyle(fontSize: scaleConfig.scaleText(14)),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: _delete,
            child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
          )
        else
          const SizedBox(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isEditing ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ],
    );
  }
}
