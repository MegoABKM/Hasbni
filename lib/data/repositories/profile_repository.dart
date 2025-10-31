
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

  
  
  Future<void> upsertProfile(Map<String, dynamic> profileData) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final dataToUpsert = {
        'id': userId, 
        ...profileData,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _client.from(_tableName).upsert(dataToUpsert);
    } catch (e) {
      print('Error upserting profile: $e');
      rethrow;
    }
  }

  
}
