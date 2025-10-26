// lib/presentation/cubits/session/session_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/employee_model.dart';
import 'package:hasbni/data/repositories/employee_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_state.dart';

const String _roleKey = 'user_session_role'; // Key for persistent storage

class SessionCubit extends Cubit<SessionState> {
  final EmployeeRepository _employeeRepository;

  SessionCubit()
    : _employeeRepository = EmployeeRepository(),
      super(const SessionState());

  /// This method should be called right after the user authenticates.
  /// It checks for a persisted role and updates the state accordingly.
  Future<void> initializeSession() async {
    emit(state.copyWith(status: SessionStatus.loading));

    final prefs = await SharedPreferences.getInstance();
    final roleData = prefs.getString(_roleKey);

    if (roleData == null) {
      // No role was saved, so the user needs to choose one.
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
          // Employee not found or other error, clear the invalid session.
          await clearSession();
        }
      }
    } else {
      // Data is corrupt or invalid.
      await clearSession();
    }
  }

  /// Sets the role to Manager and persists this choice to device storage.
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

  /// Sets the role to a specific Employee and persists this choice.
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

  /// Clears the session from state and storage. Called on sign-out.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    // Reset to initial state, which will trigger needsSelection on next login
    emit(const SessionState(status: SessionStatus.initial));
  }
}
