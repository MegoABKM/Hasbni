import 'package:hasbni/core/constants/api_constants.dart';
import 'package:hasbni/core/services/api_services.dart';
import 'package:hasbni/data/models/employee_model.dart';

class EmployeeRepository {
  final ApiService _api = ApiService();

  Future<List<Employee>> getEmployees() async {
    final List data = await _api.get(ApiConstants.employees);
    return data.map((item) => Employee.fromJson(item)).toList();
  }

  Future<void> addEmployee(String fullName) async {
    await _api.post(ApiConstants.employees, {'full_name': fullName});
  }

  Future<void> updateEmployee(int id, String newName) async {
    await _api.put('${ApiConstants.employees}/$id', {'full_name': newName});
  }

  Future<void> deleteEmployee(int id) async {
    await _api.delete('${ApiConstants.employees}/$id');
  }
}