// lib/presentation/cubits/auth/auth_state.dart
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- SIMPLIFIED STATES ---
enum AuthStatus { unknown, loading, authenticated, unauthenticated, failure }
// --- END SIMPLIFIED ---

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  // profile and related properties are removed
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? Function()? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
