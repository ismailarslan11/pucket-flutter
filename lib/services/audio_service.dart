import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'settings_service.dart';

class AudioService extends ChangeNotifier {
  AudioService(this.settings);

  final SettingsService settings;
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  bool _musicPlaying = false;

  Future<void> playShot() => _playSfx('sounds/shot.wav');
  Future<void> playHit() => _playSfx('sounds/hit.wav');
  Future<void> playWin() => _playSfx('sounds/win.wav');
  Future<void> playLose() => _playSfx('sounds/lose.wav');

  Future<void> playMenuMusic() async {
    if (!settings.musicOn || _musicPlaying) return;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(settings.musicVolume);
      await _music.play(AssetSource('sounds/menu.wav'));
      _musicPlaying = true;
    } catch (_) {}
  }

  Future<void> stopMenuMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
    _musicPlaying = false;
  }

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
      stopMenuMusic();
    }
  }

  @override
  void dispose() {
    _sfx.dispose();
    _music.dispose();
    super.dispose();
  }
}
