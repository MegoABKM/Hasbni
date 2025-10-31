




import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/employee_model.dart';

enum EmployeeStatus { initial, loading, success, failure }

class EmployeesState extends Equatable {
  final EmployeeStatus status;
  final List<Employee> employees;
  final String? errorMessage;

  const EmployeesState({
    this.status = EmployeeStatus.initial,
    this.employees = const [],
    this.errorMessage,
  });

  EmployeesState copyWith({
    EmployeeStatus? status,
    List<Employee>? employees,
    String? errorMessage,
  }) {
    return EmployeesState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, employees, errorMessage];
}
