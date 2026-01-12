import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:hasbni/data/repositories/auth_repository.dart';
import 'package:hasbni/data/repositories/exchange_rate_repository.dart';
import 'package:hasbni/data/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;
  // ignore: unused_field
  final ExchangeRateRepository _exchangeRateRepository; 
  final AuthRepository _authRepository; 

  ProfileCubit()
    : _profileRepository = ProfileRepository(),
      _exchangeRateRepository = ExchangeRateRepository(),
      _authRepository = AuthRepository(),
      super(const ProfileState());

  Future<void> loadProfile() async {
    // Only show loading if we don't have data yet
    if (state.profile == null) {
      emit(state.copyWith(status: ProfileStatus.loading));
    }
    try {
      final profile = await _profileRepository.getCurrentUserProfile();
      emit(
        state.copyWith(
          status: ProfileStatus.success,
          profile: () => profile,
          errorMessage: null,
          successMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> saveSettings({
    required Map<String, dynamic> profileData,
    required List<ExchangeRate> rates,
  }) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      // --- FIX START ---
      // We must merge the rates into the profileData so Laravel receives them 
      // in the $request->exchange_rates array.
      
      final Map<String, dynamic> combinedData = Map.from(profileData);
      
      // Convert the list of ExchangeRate objects to a List of JSON Maps
      combinedData['exchange_rates'] = rates.map((r) => r.toJson()).toList();

      // Send everything to the /profiles endpoint
      await _profileRepository.upsertProfile(combinedData);
      // --- FIX END ---

      // Refresh the profile to get the updated data from server
      final updatedProfile = await _profileRepository.getCurrentUserProfile();

      emit(
        state.copyWith(
          status: ProfileStatus.success,
          profile: () => updatedProfile,
          successMessage: 'تم حفظ الإعدادات بنجاح.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: "فشل حفظ الإعدادات: $e",
        ),
      );
    }
  }

  Future<void> setManagerPassword(String password) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      await _authRepository.setManagerPassword(password);
      emit(
        state.copyWith(
          status: ProfileStatus.success,
          successMessage: 'تم تحديث كلمة مرور المدير بنجاح.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'فشل تحديث كلمة المرور: $e',
        ),
      );
    }
  }
}