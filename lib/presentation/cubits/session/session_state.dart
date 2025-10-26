// lib/presentation/cubits/session/session_state.dart
import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/employee_model.dart';

enum SessionRole { unknown, manager, employee }

enum SessionStatus { initial, loading, determined, needsSelection }

class SessionState extends Equatable {
  final SessionStatus status;
  final SessionRole role;
  final Employee? currentEmployee;

  const SessionState({
    this.status = SessionStatus.initial,
    this.role = SessionRole.unknown,
    this.currentEmployee,
  });

  SessionState copyWith({
    SessionStatus? status,
    SessionRole? role,
    Employee? Function()? currentEmployee,
  }) {
    return SessionState(
      status: status ?? this.status,
      role: role ?? this.role,
      currentEmployee: currentEmployee != null
          ? currentEmployee()
          : this.currentEmployee,
    );
  }

  @override
  List<Object?> get props => [status, role, currentEmployee];
}
