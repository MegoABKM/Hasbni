// lib/presentation/cubits/profile/profile_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:hasbni/data/repositories/auth_repository.dart';
import 'package:hasbni/data/repositories/exchange_rate_repository.dart';
import 'package:hasbni/data/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;
  final ExchangeRateRepository _exchangeRateRepository;
  final AuthRepository _authRepository; // Add this

  ProfileCubit()
    : _profileRepository = ProfileRepository(),
      _exchangeRateRepository = ExchangeRateRepository(),
      _authRepository = AuthRepository(),
      super(const ProfileState());

  Future<void> loadProfile() async {
    // Only show full-screen loading if there's no profile data yet.
    if (state.profile == null) {
      emit(state.copyWith(status: ProfileStatus.loading));
    }
    try {
      final profile = await _profileRepository.getCurrentUserProfile();
      emit(
        state.copyWith(
          status: ProfileStatus.success,
          profile: () => profile,
          // Clear any previous messages
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

  // --- NEW CONSOLIDATED FUNCTION ---
  /// Saves all settings (profile and rates) in a single atomic operation.
  Future<void> saveSettings({
    required Map<String, dynamic> profileData,
    required List<ExchangeRate> rates,
  }) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      // Perform both updates within one logical step for the user.
      await _profileRepository.upsertProfile(profileData);
      await _exchangeRateRepository.upsertExchangeRates(rates);

      // Reload the profile to get the fresh data.
      final updatedProfile = await _profileRepository.getCurrentUserProfile();

      // Emit a final success state with the updated profile and a success message.
      emit(
        state.copyWith(
          status: ProfileStatus.success,
          profile: () => updatedProfile,
          successMessage: 'تم حفظ الإعدادات بنجاح.',
        ),
      );
    } catch (e) {
      // If anything fails, emit a failure state.
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
  // --- END OF NEW FUNCTION ---

  // The old separate functions are no longer needed.
  // Future<void> saveProfile(...)
  // Future<void> updateExchangeRates(...)
}
