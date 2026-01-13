import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/core/services/sync_service.dart';
import 'package:hasbni/data/repositories/auth_repository.dart';
import 'package:hasbni/data/models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  late StreamSubscription<AuthChangeEvent> _authSubscription;

  AuthCubit() : _authRepository = AuthRepository(), super(const AuthState());

  void initialize() async {
    emit(state.copyWith(status: AuthStatus.loading));

    _authSubscription = _authRepository.authEvents.listen((event) async {
      if (event == AuthChangeEvent.signedIn) {
        final user = await _authRepository.getCurrentUser();
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
      }
    });

    // Check Initial
    final loggedIn = await _authRepository.isLoggedIn();
    if (loggedIn) {
       final user = await _authRepository.getCurrentUser();
       emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  // --- NEW: Guest Mode ---
  void enterGuestMode() {
    // Create a dummy user for offline testing
    const guestUser = User(
      id: 0, 
      email: 'guest@offline.app', 
      name: 'Guest User'
    );
    
    // Force the state to authenticated
    emit(state.copyWith(status: AuthStatus.authenticated, user: guestUser));
  }

  Future<void> signIn(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authRepository.signInWithEmail(email: email, password: password);
       await SyncService().syncEverything();
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: () => e.toString().replaceAll('Exception: ', ''),
      ));
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authRepository.signUpWithEmail(email: email, password: password);
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: () => e.toString().replaceAll('Exception: ', ''),
      ));
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}