
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/core/utils/extention_shortcut.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:hasbni/data/models/withdrawal_model.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/cubits/withdrawals/withdrawal_cubit.dart';
import 'package:intl/intl.dart';

class AddEditWithdrawalDialog extends StatefulWidget {
  final Withdrawal? withdrawal;
  const AddEditWithdrawalDialog({super.key, this.withdrawal});

  @override
  State<AddEditWithdrawalDialog> createState() =>
      _AddEditWithdrawalDialogState();
}

class _AddEditWithdrawalDialogState extends State<AddEditWithdrawalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _selectedCurrency;
  late List<ExchangeRate> _availableRates;

  bool get _isEditing => widget.withdrawal != null;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileCubit>().state.profile;
    _availableRates = [
      const ExchangeRate(id: -1, currencyCode: 'USD', rateToUsd: 1.0),
      ...(profile?.exchangeRates ?? []),
    ];

    if (_isEditing) {
      final w = widget.withdrawal!;
      _descriptionController = TextEditingController(text: w.description ?? '');
      _amountController = TextEditingController(
        text: w.amountInCurrency.toString(),
      );
      _selectedDate = w.withdrawalDate;
      _selectedCurrency = w.currencyCode;
    } else {
      _descriptionController = TextEditingController();
      _amountController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedCurrency = 'USD';
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final cubit = context.read<WithdrawalsCubit>();
      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final rate = _availableRates
          .firstWhere((r) => r.currencyCode == _selectedCurrency)
          .rateToUsd;

      final newWithdrawal = Withdrawal(
        id: widget.withdrawal?.id,
        description: _descriptionController.text.trim(),
        amount: 0,
        amountInCurrency: amount,
        currencyCode: _selectedCurrency,
        withdrawalDate: _selectedDate,
      );

      if (_isEditing) {
        cubit.updateWithdrawal(withdrawal: newWithdrawal, rateToUsd: rate);
      } else {
        cubit.addWithdrawal(withdrawal: newWithdrawal, rateToUsd: rate);
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
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا السحب؟'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
            onPressed: () {
              context.read<WithdrawalsCubit>().deleteWithdrawal(
                widget.withdrawal!.id!,
              );
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

    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل السحب' : 'إضافة سحب شخصي',
        style: TextStyle(fontSize: scaleConfig.scaleText(20)),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  labelStyle: TextStyle(fontSize: scaleConfig.scaleText(16)),
                ),
              ),
              SizedBox(height: scaleConfig.scale(16)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                        if (value == null || value.isEmpty)
                          return 'المبلغ مطلوب';
                        if (double.tryParse(value) == null)
                          return 'أدخل رقماً صحيحاً';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: scaleConfig.scale(8)),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
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
                              child: Text(rate.currencyCode),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _selectedCurrency = value);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: scaleConfig.scale(16)),
              ListTile(
                title: Text(
                  'تاريخ السحب: ${DateFormat.yMMMd('ar').format(_selectedDate)}',
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
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: _delete,
            child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'حفظ' : 'إضافة'),
        ),
      ],
    );
  }
}
