// lib/presentation/cubits/employees/employees_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/employee_model.dart';
import 'package:hasbni/data/repositories/employee_repository.dart';
import 'package:hasbni/presentation/cubits/employees/employees_state.dart';

// تم حذف سطر "part"
// أضف هذا الاستيراد بدلاً منه

class EmployeesCubit extends Cubit<EmployeesState> {
  final EmployeeRepository _repository;

  EmployeesCubit()
    : _repository = EmployeeRepository(),
      super(const EmployeesState());

  Future<void> loadEmployees() async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      final employees = await _repository.getEmployees();
      emit(
        state.copyWith(status: EmployeeStatus.success, employees: employees),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> addEmployee(String fullName) async {
    try {
      await _repository.addEmployee(fullName);
      await loadEmployees();
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.failure,
          errorMessage: "Failed to add employee: $e",
        ),
      );
    }
  }

  Future<void> updateEmployee(int id, String newName) async {
    try {
      await _repository.updateEmployee(id, newName);
      await loadEmployees();
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.failure,
          errorMessage: "Failed to update employee: $e",
        ),
      );
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      final updatedList = List<Employee>.from(state.employees)
        ..removeWhere((emp) => emp.id == id);
      emit(state.copyWith(employees: updatedList)); // Optimistic update
      await _repository.deleteEmployee(id);
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.failure,
          errorMessage: "Failed to delete employee: $e",
        ),
      );
      await loadEmployees(); // Revert on failure
    }
  }
}
