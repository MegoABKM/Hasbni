import 'dart:async';
import 'package:hasbni/core/constants/api_constants.dart';
import 'package:hasbni/core/services/api_services.dart';
import 'package:hasbni/data/models/user_model.dart'; 

enum AuthChangeEvent { signedIn, signedOut }

class AuthRepository {
  final ApiService _api = ApiService();
  final _authEventController = StreamController<AuthChangeEvent>.broadcast();
  
  Stream<AuthChangeEvent> get authEvents => _authEventController.stream;

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null;
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await _api.getToken();
      if (token == null) return null;
      // Note: Assuming you implemented a /user endpoint or use stored data
      // For basic flow, we can return a local user if token exists or fetch from API
      // To strictly follow clean code, add Route::get('/user', ...) in Laravel
      // For now, return a placeholder or fetch if API ready:
       try {
         final data = await _api.get(ApiConstants.user);
         return User.fromJson(data);
       } catch (e) {
         return null;
       }
    } catch (e) {
      return null;
    }
  }

  Future<void> signInWithEmail({required String email, required String password}) async {
    final response = await _api.post(ApiConstants.login, {
      'email': email,
      'password': password,
    });
    await _api.saveToken(response['access_token']);
    _authEventController.add(AuthChangeEvent.signedIn);
  }

  Future<void> signUpWithEmail({required String email, required String password}) async {
    final response = await _api.post(ApiConstants.register, {
      'email': email,
      'password': password,
    });
    await _api.saveToken(response['access_token']);
    _authEventController.add(AuthChangeEvent.signedIn);
  }

  Future<void> signOut() async {
    try {
      await _api.post(ApiConstants.logout, {});
    } catch (_) {} 
    finally {
      await _api.deleteToken();
      _authEventController.add(AuthChangeEvent.signedOut);
    }
  }

  Future<void> setManagerPassword(String password) async {
    await _api.post(ApiConstants.setManagerPassword, {'p_password': password});
  }

  Future<bool> verifyManagerPassword(String password) async {
    final result = await _api.post(ApiConstants.verifyManagerPassword, {'p_password': password});
    return result as bool;
  }

  Future<bool> isManagerPasswordSet() async {
    final result = await _api.post(ApiConstants.isManagerPasswordSet, {});
    return result as bool;
  }
}