import 'package:socket_io_client/socket_io_client.dart' as io;
import 'config.dart';
import 'storage.dart';

/// Realtime client. Connects with the access token and exposes a tiny
/// on/emit surface for trip/order/chat events.
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  bool get connected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null) return;
    final token = await TokenStore.accessToken;
    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    _socket!.connect();
  }

  void on(String event, void Function(dynamic) handler) => _socket?.on(event, handler);
  void off(String event) => _socket?.off(event);
  void emit(String event, [dynamic data]) => _socket?.emit(event, data);

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
