import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Uygulama açılışında oynatılan Yesa Studio marka videosu.
/// Video bitince (veya emniyet zaman aşımında) [onDone] çağrılır.
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash> {
  VideoPlayerController? _controller;
  bool _done = false;
  Timer? _safety;

  @override
  void initState() {
    super.initState();
    _init();
    // Emniyet: video hiç oynamazsa (bozuk/uzun) uygulama takılı kalmasın.
    _safety = Timer(const Duration(seconds: 6), _finish);
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.asset('assets/video/brand_splash.mp4');
      _controller = c;
      await c.initialize();
      if (!mounted) {
        c.dispose();
        return;
      }
      c.addListener(_watchEnd);
      await c.setVolume(1.0);
      await c.play();
      setState(() {});
    } catch (_) {
      _finish(); // Video açılmazsa doğrudan geç.
    }
  }

  void _watchEnd() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final pos = c.value.position;
    final dur = c.value.duration;
    // Bitişe ~120ms kala geçişi başlat (son karede takılma hissi olmasın).
    if (dur > Duration.zero && pos >= dur - const Duration(milliseconds: 120)) {
      _finish();
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _safety?.cancel();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _safety?.cancel();
    _controller?.removeListener(_watchEnd);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    return Container(
      color: Colors.black,
      child: Center(
        child: ready
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: c.value.size.width,
                    height: c.value.size.height,
                    child: VideoPlayer(c),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
