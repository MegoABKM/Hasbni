
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:hasbni/data/repositories/auth_repository.dart';
import 'package:hasbni/data/repositories/exchange_rate_repository.dart';
import 'package:hasbni/data/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;
  final ExchangeRateRepository _exchangeRateRepository;
  final AuthRepository _authRepository; 

  ProfileCubit()
    : _profileRepository = ProfileRepository(),
      _exchangeRateRepository = ExchangeRateRepository(),
      _authRepository = AuthRepository(),
      super(const ProfileState());

  Future<void> loadProfile() async {
    
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
      
      await _profileRepository.upsertProfile(profileData);
      await _exchangeRateRepository.upsertExchangeRates(rates);

      
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
