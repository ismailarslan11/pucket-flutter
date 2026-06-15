import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

typedef WsHandler = void Function(Map<String, dynamic> msg);

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  WsHandler? onMessage;
  void Function()? onError;
  void Function()? onClose;

  bool get isConnected => _channel != null;

  Future<bool> connect(String url) async {
    disconnect();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready.timeout(const Duration(seconds: 8));

      _sub = _channel!.stream.listen(
        (data) {
          try {
            onMessage?.call(jsonDecode(data as String) as Map<String, dynamic>);
          } catch (_) {}
        },
        onError: (_) {
          onError?.call();
          disconnect();
        },
        onDone: () {
          onClose?.call();
          disconnect();
        },
        cancelOnError: true,
      );
      return true;
    } catch (_) {
      disconnect();
      onError?.call();
      return false;
    }
  }

  void send(Map<String, dynamic> msg) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(msg));
    } catch (_) {
      onError?.call();
    }
  }

  void disconnect() {
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }
}

String makeRoomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng = Random();
  return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
}
