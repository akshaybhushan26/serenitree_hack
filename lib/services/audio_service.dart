import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final Map<String, AudioPlayer> _players = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      ));

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing audio session: $e');
    }
  }

  Future<AudioPlayer?> getPlayer(String id) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_players.containsKey(id)) {
      try {
        final player = AudioPlayer();
        _players[id] = player;
      } catch (e) {
        debugPrint('Error creating audio player: $e');
        return null;
      }
    }

    return _players[id];
  }

  Future<void> disposePlayer(String id) async {
    final player = _players[id];
    if (player != null) {
      await player.dispose();
      _players.remove(id);
    }
  }

  Future<void> disposeAll() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }

  Future<void> playAsset(String id, String assetPath) async {
    final player = await getPlayer(id);
    if (player != null) {
      try {
        await player.setAsset(assetPath);
        await player.play();
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
    }
  }

  Future<void> stop(String id) async {
    final player = _players[id];
    if (player != null) {
      await player.stop();
    }
  }

  Future<void> pause(String id) async {
    final player = _players[id];
    if (player != null) {
      await player.pause();
    }
  }

  Future<void> resume(String id) async {
    final player = _players[id];
    if (player != null) {
      await player.play();
    }
  }
}
