import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../env.dart';

typedef JobEventCallback = void Function(Map<String, dynamic> data);

/// Maintains a persistent Socket.IO connection while the app is in the
/// foreground. Delivers real-time job events: assigned, cancelled, completed,
/// route updated.
class SocketService {
  IO.Socket? _socket;

  JobEventCallback? onJobAssigned;
  JobEventCallback? onJobCancelled;
  JobEventCallback? onJobCompleted;
  JobEventCallback? onRouteUpdated;

  bool _connected = false;
  bool get isConnected => _connected;

  void connect(String accessToken) {
    if (_socket != null && _connected) return;

    _socket = IO.io(
      AppEnv.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/ws')
          .setAuth({'token': accessToken})
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(double.infinity.toInt())
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      debugPrint('[Socket] Connected to ${AppEnv.wsUrl}');
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      debugPrint('[Socket] Disconnected');
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] Connect error: $err');
    });

    _socket!.on('job:assigned', (data) {
      debugPrint('[Socket] job:assigned $data');
      final map = _toMap(data);
      onJobAssigned?.call(map);
    });

    _socket!.on('job:cancelled', (data) {
      debugPrint('[Socket] job:cancelled $data');
      final map = _toMap(data);
      onJobCancelled?.call(map);
    });

    _socket!.on('job:completed', (data) {
      debugPrint('[Socket] job:completed $data');
      final map = _toMap(data);
      onJobCompleted?.call(map);
    });

    _socket!.on('route:updated', (data) {
      debugPrint('[Socket] route:updated $data');
      final map = _toMap(data);
      onRouteUpdated?.call(map);
    });
  }

  /// Update the access token (e.g., after silent refresh).
  void updateToken(String newToken) {
    if (_socket == null) return;
    _socket!.auth = {'token': newToken};
    if (!_connected) {
      _socket!.connect();
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }
}
