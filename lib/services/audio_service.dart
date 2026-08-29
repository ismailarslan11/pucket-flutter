import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'settings_service.dart';

enum MusicTrack { menu, game, none }

class AudioService extends ChangeNotifier with WidgetsBindingObserver {
  AudioService(this.settings) {
    settings.addListener(_onSettingsUpdate);
    // Uygulama arka plana geçince müzik sussun, geri gelince devam etsin.
    WidgetsBinding.instance.addObserver(this);
  }

  final SettingsService settings;
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  MusicTrack _currentTrack = MusicTrack.none;
  // Bulunulan ekranın olması gereken parçası — müzik ayardan kapalı olsa bile
  // hatırlanır ki tekrar açılınca doğru parça başlasın.
  MusicTrack _desiredTrack = MusicTrack.none;
  String _desiredAsset = '';
  bool _pausedByLifecycle = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _resumeAfterBackground();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _pauseForBackground();
    }
  }

  /// Arka plana/masaüstüne dönünce çalan müziği duraklat (durdurma değil —
  /// kaldığı yeri korur ki geri dönünce aynı yerden devam etsin).
  void _pauseForBackground() {
    if (_currentTrack == MusicTrack.none || _pausedByLifecycle) return;
    _pausedByLifecycle = true;
    _music.pause().catchError((_) {});
  }

  void _resumeAfterBackground() {
    if (!_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    // Kullanıcı arka plandayken müziği kapattıysa devam ettirme.
    if (!settings.musicOn || _currentTrack == MusicTrack.none) return;
    _music.resume().catchError((_) {});
  }

  Future<void> playShot() => _playSfx('sounds/shot.wav');
  Future<void> playHit() => _playSfx('sounds/hit.wav');
  Future<void> playWin() => _playSfx('sounds/win.wav');
  Future<void> playLose() => _playSfx('sounds/lose.wav');

  Future<void> playMenuMusic() => _playMusic(MusicTrack.menu, 'sounds/anasayfamuzik.mp3');

  Future<void> playGameMusic() => _playMusic(MusicTrack.game, 'sounds/muzik.mp3');

  Future<void> _playMusic(MusicTrack track, String asset) async {
    // Ekranın istenen parçasını her zaman hatırla (müzik kapalıyken bile),
    // ki ayardan tekrar açılınca doğru parça başlasın.
    _desiredTrack = track;
    _desiredAsset = asset;
    if (!settings.musicOn) return;
    // Arka plandayken duraklatılmış aynı parça yeniden istenirse (ör.
    // menüye dönüş) durdurma sayacını temizle, akış aşağıda ele alınır.
    _pausedByLifecycle = false;
    if (_currentTrack == track) {
      // Aynı parça: arka planda duraklatılmışsa sadece devam ettir.
      _music.resume().catchError((_) {});
      return;
    }
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
    _desiredTrack = MusicTrack.none;
    _desiredAsset = '';
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
      // Ayardan kapatıldı: parçayı durdur ama ekranın istenen parçasını unutma
      // (stopMusic desired'ı sıfırlardı; burada sadece çalmayı kes).
      _music.stop().catchError((_) {});
      _currentTrack = MusicTrack.none;
      return;
    }
    // Ayardan tekrar açıldı: bu ekranın parçasını yeniden başlat.
    if (_desiredTrack != MusicTrack.none && _currentTrack != _desiredTrack) {
      _playMusic(_desiredTrack, _desiredAsset);
    }
  }

  void _onSettingsUpdate() => onSettingsChanged();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    settings.removeListener(_onSettingsUpdate);
    _sfx.dispose();
    _music.dispose();
    super.dispose();
  }
}
