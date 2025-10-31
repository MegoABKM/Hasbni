
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/employee_model.dart';
import 'package:hasbni/presentation/cubits/employees/employee_cubit.dart';
import 'package:hasbni/presentation/cubits/employees/employees_state.dart';


import 'package:hasbni/presentation/screens/employees/widgets/add_edit_employee_dialog.dart';

class EmployeeManagementScreen extends StatelessWidget {
  const EmployeeManagementScreen({super.key});

  
  void _showAddEditDialog(BuildContext context, {Employee? employee}) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<EmployeesCubit>(),
        child: AddEditEmployeeDialog(employee: employee),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EmployeesCubit()..loadEmployees(),
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة الموظفين')),
        body: BlocConsumer<EmployeesCubit, EmployeesState>(
          listener: (context, state) {
            if (state.status == EmployeeStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'حدث خطأ'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == EmployeeStatus.loading &&
                state.employees.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.employees.isEmpty) {
              return const Center(
                child: Text(
                  'لم تقم بإضافة أي موظفين بعد.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<EmployeesCubit>().loadEmployees(),
              child: ListView.builder(
                itemCount: state.employees.length,
                itemBuilder: (ctx, index) {
                  final employee = state.employees[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        employee.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            _showAddEditDialog(context, employee: employee),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () => _showAddEditDialog(context),
            tooltip: 'إضافة موظف جديد',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
