
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  
  
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print("AuthRepo: Attempting to sign in with email: $email");
      await _client.auth.signInWithPassword(email: email, password: password);
      print("✅ AuthRepo: Sign in successful for $email. Waiting for stream...");
    } on AuthException catch (e) {
      print("❌ AuthRepo: Sign in failed. Supabase message: ${e.message}");
      throw Exception('فشل تسجيل الدخول: ${e.message}');
    } catch (e) {
      print("❌ AuthRepo: An unexpected error occurred during sign in: $e");
      throw Exception('حدث خطأ غير متوقع.');
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print("AuthRepo: Attempting to sign up with email: $email");
      await _client.auth.signUp(email: email, password: password);
      print("✅ AuthRepo: Sign up successful for $email. Waiting for stream...");
    } on AuthException catch (e) {
      print("❌ AuthRepo: Sign up failed. Supabase message: ${e.message}");
      if (e.message.contains('User already registered')) {
        throw Exception('هذا البريد الإلكتروني مسجل بالفعل.');
      }
      throw Exception('فشل إنشاء الحساب: ${e.message}');
    } catch (e) {
      print("❌ AuthRepo: An unexpected error occurred during sign up: $e");
      throw Exception('حدث خطأ غير متوقع.');
    }
  }

  Future<void> signOut() async {
    try {
      print("AuthRepo: Attempting to sign out.");
      await _client.auth.signOut();
      print("✅ AuthRepo: Sign out successful.");
    } catch (e) {
      print("❌ AuthRepo: An unexpected error occurred during sign out: $e");
      throw Exception('فشل تسجيل الخروج.');
    }
  }

  Future<void> setManagerPassword(String password) async {
    await _client.rpc('set_manager_password', params: {'p_password': password});
  }

  
  Future<bool> verifyManagerPassword(String password) async {
    final result = await _client.rpc(
      'verify_manager_password',
      params: {'p_password': password},
    );
    return result as bool;
  }

  
  Future<bool> isManagerPasswordSet() async {
    final result = await _client.rpc('is_manager_password_set');
    return result as bool;
  }
}
