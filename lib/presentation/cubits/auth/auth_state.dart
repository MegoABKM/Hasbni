
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


enum AuthStatus { unknown, loading, authenticated, unauthenticated, failure }


class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  
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
