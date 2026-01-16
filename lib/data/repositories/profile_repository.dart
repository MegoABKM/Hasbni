import 'package:hasbni/core/constants/api_constants.dart';
import 'package:hasbni/core/services/api_services.dart';
import 'package:hasbni/core/services/database_service.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:hasbni/data/models/profile_model.dart';
import 'package:sqflite/sqflite.dart';

class ProfileRepository {
  final ApiService _api = ApiService();
  final DatabaseService _db = DatabaseService();

  Future<Profile?> getCurrentUserProfile() async {
    try {
      // 1. Try Online First
      final data = await _api.get(ApiConstants.profiles);
      final profile = Profile.fromJson(data);
      
      // 2. Save to Local DB for next time
      await _saveProfileLocally(profile);
      
      return profile;
    } catch (e) {
      print("⚠️ Offline Mode: Fetching profile locally... ($e)");
      // 3. Fallback to Local DB
      final localProfile = await _getLocalProfile();
      
      if (localProfile != null) {
        return localProfile;
      } else {
        // 4. Default Profile for Guest/Fresh Install
        print("⚠️ No local profile found. Returning default Guest Profile.");
        return const Profile(
          id: 0,
          shopName: 'متجر تجريبي',
          address: 'وضع غير متصل',
          phoneNumber: '',
          city: '',
          exchangeRates: [], // Empty list implies only USD
          hasManagerPassword: false,
        );
      }
    }
  }

   Future<void> upsertProfile(Map<String, dynamic> profileData) async {
    // 1. CONSTRUCT PROFILE OBJECT FROM DATA
    // We need to construct a Profile object to save it locally manually
    List<ExchangeRate> rates = [];
    if (profileData['exchange_rates'] != null) {
      rates = (profileData['exchange_rates'] as List)
          .map((r) => ExchangeRate.fromJson(r))
          .toList();
    }
    
    final profileToSave = Profile(
      id: 1, // Singleton ID
      shopName: profileData['shop_name'],
      address: profileData['address'],
      phoneNumber: profileData['phone_number'],
      city: profileData['city'],
      exchangeRates: rates,
      hasManagerPassword: false, // Default, updated via other endpoints
    );

    // 2. SAVE LOCALLY FIRST (This fixes the saving issue)
    print("💾 Saving profile locally...");
    await _saveProfileLocally(profileToSave);

    // 3. TRY SYNCING TO SERVER (Background try)
    try {
      if (!ApiService.isOfflineMode) {
         await _api.post(ApiConstants.profiles, profileData);
         print("✅ Profile synced to server.");
      }
    } catch (e) {
      print("⚠️ Could not sync profile to server (Offline): $e");
      // We don't throw error here, because we successfully saved locally!
    }
  }

  // --- Local Database Helpers ---

  Future<void> _saveProfileLocally(Profile profile) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Save Profile Info
      await txn.insert('profiles', {
        'id': 1, // Singleton
        'shop_name': profile.shopName,
        'address': profile.address,
        'phone_number': profile.phoneNumber,
        'city': profile.city,
        'has_manager_password': profile.hasManagerPassword ? 1 : 0,
      }, conflictAlgorithm:ConflictAlgorithm.replace);

      // Save Exchange Rates
      await txn.delete('exchange_rates'); // Clear old rates
      for (var rate in profile.exchangeRates) {
        await txn.insert('exchange_rates', {
          'currency_code': rate.currencyCode,
          'rate_to_usd': rate.rateToUsd,
        });
      }
    });
  }

  Future<Profile?> _getLocalProfile() async {
    final db = await _db.database;
    
    final profileMaps = await db.query('profiles', where: 'id = 1');
    if (profileMaps.isEmpty) return null;
    
    final pRow = profileMaps.first;
    
    final ratesMaps = await db.query('exchange_rates');
    final rates = ratesMaps.map((r) => ExchangeRate(
      id: null, 
      currencyCode: r['currency_code'] as String,
      rateToUsd: (r['rate_to_usd'] as num).toDouble(),
    )).toList();

    return Profile(
      id: pRow['id'] as int,
      shopName: pRow['shop_name'] as String,
      address: pRow['address'] as String?,
      phoneNumber: pRow['phone_number'] as String?,
      city: pRow['city'] as String?,
      hasManagerPassword: (pRow['has_manager_password'] as int) == 1,
      exchangeRates: rates,
    );
  }
}