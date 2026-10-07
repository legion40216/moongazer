import 'package:just_audio/just_audio.dart';

/// Manages playback of mngazer.wav (the Neil Armstrong "one small step" quote).
///
/// • Plays automatically once on first launch.
/// • Can be toggled on/off by the user in settings.
/// • Respects audio focus / interruptions (just_audio handles this).
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  AudioPlayer? _player;
  bool _initialized = false;

  /// Call once – typically from [main.dart] after Flutter engine is ready.
  Future<void> init() async {
    if (_initialized) return;
    try {
      _player = AudioPlayer();
      await _player!.setAsset('assets/audio/mngazer.wav');
      _initialized = true;
    } catch (e) {
      // Audio is optional – silently continue if unavailable
      _player = null;
    }
  }

  /// Play from the beginning.
  Future<void> play() async {
    if (_player == null) return;
    try {
      await _player!.seek(Duration.zero);
      await _player!.play();
    } catch (_) {}
  }

  /// Stop playback.
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _initialized = false;
  }
}
