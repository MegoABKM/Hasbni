// lib/data/repositories/profile_repository.dart
import 'package:hasbni/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String _tableName = 'profiles';

  Future<Profile?> getCurrentUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await _client
          .from(_tableName)
          .select('*, exchange_rates(*)')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        return null;
      }
      return Profile.fromJson(data);
    } catch (e) {
      print('Error fetching profile with rates: $e');
      rethrow;
    }
  }

  // --- NEW UNIFIED FUNCTION ---
  /// Creates or updates a user's profile.
  Future<void> upsertProfile(Map<String, dynamic> profileData) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final dataToUpsert = {
        'id': userId, // The primary key to check for conflict
        ...profileData,
        'updated_at': DateTime.now().toIso8601String(),
      };
      // Upsert will create if 'id' doesn't exist, or update if it does.
      await _client.from(_tableName).upsert(dataToUpsert);
    } catch (e) {
      print('Error upserting profile: $e');
      rethrow;
    }
  }

  // --- END NEW FUNCTION ---
}
