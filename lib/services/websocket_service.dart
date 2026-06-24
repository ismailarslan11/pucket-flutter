import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

typedef WsHandler = void Function(Map<String, dynamic> msg);

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  WsHandler? onMessage;
  void Function()? onError;
  void Function()? onClose;
  void Function()? onReconnected;

  String? _lastUrl;
  String? _uid;
  String? _sessionToken;
  String? _roomCode;
  bool _intentionalDisconnect = false;
  bool _reconnecting = false;
  int _reconnectAttempts = 0;

  bool get isConnected => _channel != null;
  bool get isReconnecting => _reconnecting;
  String? get sessionToken => _sessionToken;
  String? get roomCode => _roomCode;

  void setSession({String? uid, String? sessionToken, String? roomCode}) {
    _uid = uid;
    _sessionToken = sessionToken;
    _roomCode = roomCode;
  }

  Future<bool> connect(String url) async {
    _intentionalDisconnect = false;
    _lastUrl = url;
    return _open(url);
  }

  Future<bool> _open(String url) async {
    _cleanupChannel();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready.timeout(const Duration(seconds: 8));

      _sub = _channel!.stream.listen(
        (data) {
          try {
            onMessage?.call(jsonDecode(data as String) as Map<String, dynamic>);
          } catch (_) {}
        },
        onError: (_) => _handleDrop(),
        onDone: () => _handleDrop(),
        cancelOnError: true,
      );

      _startPing();
      _reconnectAttempts = 0;
      _reconnecting = false;
      return true;
    } catch (_) {
      _cleanupChannel();
      onError?.call();
      return false;
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      send({'type': 'ping'});
    });
  }

  void _handleDrop() {
    if (_intentionalDisconnect) {
      onClose?.call();
      return;
    }
    if (_roomCode != null && _uid != null && _sessionToken != null) {
      _tryReconnect();
      return;
    }
    _cleanupChannel();
    onClose?.call();
  }

  void _tryReconnect() {
    if (_intentionalDisconnect || _lastUrl == null) return;
    if (_roomCode == null || _uid == null || _sessionToken == null) {
      _cleanupChannel();
      return;
    }
    if (_reconnectAttempts >= 12) {
      _reconnecting = false;
      _cleanupChannel();
      onClose?.call();
      return;
    }

    _reconnecting = true;
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts.clamp(1, 5));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      final ok = await _open(_lastUrl!);
      if (ok) {
        send({
          'type': 'reconnect',
          'room': _roomCode,
          'uid': _uid,
          'sessionToken': _sessionToken,
        });
        onReconnected?.call();
      } else {
        _tryReconnect();
      }
    });
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
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _cleanupChannel();
    _reconnecting = false;
    _reconnectAttempts = 0;
  }

  void _cleanupChannel() {
    _sub?.cancel();
    _sub = null;
    _pingTimer?.cancel();
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
