
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/employee_model.dart';
import 'package:hasbni/presentation/cubits/employees/employee_cubit.dart';

class AddEditEmployeeDialog extends StatefulWidget {
  final Employee? employee;
  const AddEditEmployeeDialog({super.key, this.employee});

  @override
  State<AddEditEmployeeDialog> createState() => _AddEditEmployeeDialogState();
}

class _AddEditEmployeeDialogState extends State<AddEditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.employee?.fullName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final cubit = context.read<EmployeesCubit>();
      final name = _nameController.text.trim();

      if (_isEditing) {
        cubit.updateEmployee(widget.employee!.id, name);
      } else {
        cubit.addEmployee(name);
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
        content: Text(
          'هل أنت متأكد من رغبتك في حذف الموظف "${widget.employee!.fullName}"؟',
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
            onPressed: () {
              context.read<EmployeesCubit>().deleteEmployee(
                widget.employee!.id,
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
    return AlertDialog(
      title: Text(_isEditing ? 'تعديل بيانات الموظف' : 'إضافة موظف جديد'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'الاسم الكامل للموظف'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'اسم الموظف مطلوب';
            }
            return null;
          },
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: _delete,
            child: const Text(
              'حذف الموظف',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'حفظ التعديلات' : 'إضافة'),
        ),
      ],
    );
  }
}
