
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/employee_model.dart';
import 'package:hasbni/data/repositories/employee_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_state.dart';

const String _roleKey = 'user_session_role'; 

class SessionCubit extends Cubit<SessionState> {
  final EmployeeRepository _employeeRepository;

  SessionCubit()
    : _employeeRepository = EmployeeRepository(),
      super(const SessionState());

  
  
  Future<void> initializeSession() async {
    emit(state.copyWith(status: SessionStatus.loading));

    final prefs = await SharedPreferences.getInstance();
    final roleData = prefs.getString(_roleKey);

    if (roleData == null) {
      
      emit(state.copyWith(status: SessionStatus.needsSelection));
      return;
    }

    if (roleData == 'manager') {
      emit(
        state.copyWith(
          status: SessionStatus.determined,
          role: SessionRole.manager,
          currentEmployee: () => null,
        ),
      );
    } else if (roleData.startsWith('employee_')) {
      final employeeId = int.tryParse(roleData.split('_').last);
      if (employeeId != null) {
        try {
          final allEmployees = await _employeeRepository.getEmployees();
          final employee = allEmployees.firstWhere((e) => e.id == employeeId);
          emit(
            state.copyWith(
              status: SessionStatus.determined,
              role: SessionRole.employee,
              currentEmployee: () => employee,
            ),
          );
        } catch (e) {
          
          await clearSession();
        }
      }
    } else {
      
      await clearSession();
    }
  }

  
  Future<void> setManagerRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, 'manager');
    emit(
      state.copyWith(
        status: SessionStatus.determined,
        role: SessionRole.manager,
        currentEmployee: () => null,
      ),
    );
  }

  
  Future<void> setEmployeeRole(Employee employee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, 'employee_${employee.id}');
    emit(
      state.copyWith(
        status: SessionStatus.determined,
        role: SessionRole.employee,
        currentEmployee: () => employee,
      ),
    );
  }

  
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    
    emit(const SessionState(status: SessionStatus.initial));
  }
}
