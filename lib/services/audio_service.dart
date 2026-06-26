import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'settings_service.dart';

enum MusicTrack { menu, game, none }

class AudioService extends ChangeNotifier {
  AudioService(this.settings);

  final SettingsService settings;
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  MusicTrack _currentTrack = MusicTrack.none;

  Future<void> playShot() => _playSfx('sounds/shot.wav');
  Future<void> playHit() => _playSfx('sounds/hit.wav');
  Future<void> playWin() => _playSfx('sounds/win.wav');
  Future<void> playLose() => _playSfx('sounds/lose.wav');

  Future<void> playMenuMusic() => _playMusic(MusicTrack.menu, 'sounds/menu.wav');

  Future<void> playGameMusic() => _playMusic(MusicTrack.game, 'sounds/game.wav');

  Future<void> _playMusic(MusicTrack track, String asset) async {
    if (!settings.musicOn) return;
    if (_currentTrack == track) return;
    try {
      await _music.stop();
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(settings.musicVolume * (track == MusicTrack.game ? 0.85 : 1.0));
      await _music.play(AssetSource(asset));
      _currentTrack = track;
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
    _currentTrack = MusicTrack.none;
  }

  Future<void> stopMenuMusic() => stopMusic();

  Future<void> _playSfx(String asset) async {
    if (!settings.sfxOn) return;
    try {
      await _sfx.setVolume(settings.sfxVolume);
      await _sfx.play(AssetSource(asset));
    } catch (_) {}
  }

  void onSettingsChanged() {
    _music.setVolume(settings.musicVolume);
    if (!settings.musicOn) {
      stopMusic();
    }
  }

  @override
  void dispose() {
    _sfx.dispose();
    _music.dispose();
    super.dispose();
  }
}
