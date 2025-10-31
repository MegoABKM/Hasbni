
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  late StreamSubscription<supabase.AuthState> _authStateSubscription;

  AuthCubit() : _authRepository = AuthRepository(), super(const AuthState());

  void initialize() {
    print("AuthCubit: Initializing...");

    _authStateSubscription = _authRepository.authStateChanges.listen((data) {
      final user = data.session?.user;
      print(
        "AuthCubit: Auth state stream changed. User is: ${user?.id ?? 'null'}",
      );
      _onUserAuthenticated(user);
    });

    final initialUser = _authRepository.currentUser;
    print(
      "AuthCubit: Initial user check. User is: ${initialUser?.id ?? 'null'}",
    );
    if (initialUser != null) {
      _onUserAuthenticated(initialUser);
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  void _onUserAuthenticated(supabase.User? user) {
    if (user != null) {
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
    }
  }

  Future<void> _handleAuthAction(Future<void> Function() action) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await action();
    } catch (e) {
      print("❌ AuthCubit: Auth action failed. Error: $e");
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: () => e.toString(),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 100));
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> signIn(String email, String password) async {
    await _handleAuthAction(
      () => _authRepository.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signUp(String email, String password) async {
    await _handleAuthAction(
      () => _authRepository.signUpWithEmail(email: email, password: password),
    );
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}
