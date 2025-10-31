
import 'package:hasbni/data/models/employee_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String _tableName = 'employees';

  Future<List<Employee>> getEmployees() async {
    final data = await _client.from(_tableName).select().order('full_name');
    return data.map((item) => Employee.fromJson(item)).toList();
  }

  Future<void> addEmployee(String fullName) async {
    await _client.from(_tableName).insert({'full_name': fullName});
  }

  Future<void> updateEmployee(int id, String newName) async {
    await _client.from(_tableName).update({'full_name': newName}).eq('id', id);
  }

  Future<void> deleteEmployee(int id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }
}
