import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final socketProvider = Provider<GameSocket>((ref) => GameSocket());

class GameSocket {
  WebSocketChannel? _channel;
  Stream<dynamic>? get messages => _channel?.stream;
  void connect(String url) {
    _channel?.sink.close();
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  void send(Map<String, Object?> message) =>
      _channel?.sink.add(jsonEncode(message));
  Future<void> close() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
