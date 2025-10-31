

import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class SoundService {
  
  
  static final SoundService _instance = SoundService._internal();

  
  factory SoundService() {
    return _instance;
  }

  
  SoundService._internal();
  

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.ambient,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.sonification,
            usage: AndroidAudioUsage.notification,
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientMayDuck,
        ),
      );

      await _audioPlayer.setAsset('assets/sounds/beep.wav');

      _isInitialized = true;
      print("✅ SoundService initialized successfully.");
      return true;
    } catch (e) {
      print("❌ Error initializing SoundService: $e");
      _isInitialized = false;
      return false;
    }
  }

  Future<void> playBeep() async {
    if (!_isInitialized) {
      print("⚠️ SoundService was not ready. Re-initializing...");
      final success = await initialize();
      if (!success) {
        print("❌ Could not re-initialize sound service. Aborting play.");
        return;
      }
    }

    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (e) {
      print("❌ Error playing beep sound: $e");
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
