import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../env.dart';

/// Publishes the vehicle GPS position every 5 seconds via MQTT.
/// Only active while the driver has an active job.
/// Buffers up to 10 positions during disconnection and replays on reconnect.
class MqttService {
  MqttServerClient? _client;
  Timer? _publishTimer;
  Timer? _reconnectTimer;

  String? _vehicleId;
  String? _driverId;
  String? _jobId;
  String? _token;

  bool _isPublishing = false;
  bool _isConnected = false;

  final List<Map<String, dynamic>> _positionBuffer = [];
  static const int _maxBufferSize = 10;

  // Reconnect backoff
  int _reconnectDelaySeconds = 1;
  static const int _maxReconnectDelay = 30;

  /// Connect to MQTT broker and begin publishing.
  Future<void> connect({
    required String vehicleId,
    required String driverId,
    required String jobId,
    required String token,
  }) async {
    _vehicleId = vehicleId;
    _driverId = driverId;
    _jobId = jobId;
    _token = token;

    await _connect();
  }

  Future<void> _connect() async {
    try {
      _client = MqttServerClient(AppEnv.mqttBroker, _vehicleId ?? 'vehicle');
      _client!.port = 8883;
      _client!.secure = true;
      _client!.keepAlivePeriod = 60;
      _client!.autoReconnect = false; // We handle reconnect manually
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.logging(on: kDebugMode);

      final connMsg = MqttConnectMessage()
          .withClientIdentifier(_vehicleId ?? 'vehicle')
          .authenticateAs(_driverId ?? 'driver', _token ?? '')
          .withWillQos(MqttQos.atLeastOnce)
          .startClean();

      _client!.connectionMessage = connMsg;
      await _client!.connect();
    } catch (e) {
      debugPrint('[MQTT] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onConnected() {
    debugPrint('[MQTT] Connected');
    _isConnected = true;
    _reconnectDelaySeconds = 1; // reset backoff

    // Replay buffered positions
    if (_positionBuffer.isNotEmpty) {
      debugPrint('[MQTT] Replaying ${_positionBuffer.length} buffered positions');
      for (final payload in List.from(_positionBuffer)) {
        _publish(jsonEncode(payload));
      }
      _positionBuffer.clear();
    }
  }

  void _onDisconnected() {
    debugPrint('[MQTT] Disconnected');
    _isConnected = false;
    if (_isPublishing) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    debugPrint('[MQTT] Reconnecting in ${_reconnectDelaySeconds}s');
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelaySeconds), () {
      if (_isPublishing) _connect();
    });
    // Exponential backoff
    _reconnectDelaySeconds =
        (_reconnectDelaySeconds * 2).clamp(1, _maxReconnectDelay);
  }

  /// Start publishing GPS every 5 seconds.
  void startPublishing() {
    if (_isPublishing) return;
    _isPublishing = true;
    debugPrint('[MQTT] Starting GPS publishing for job $_jobId');

    _publishTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _publishCurrentPosition(),
    );
  }

  Future<void> _publishCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final payload = {
        'vehicle_id': _vehicleId,
        'driver_id': _driverId,
        'job_id': _jobId,
        'lat': position.latitude,
        'lng': position.longitude,
        'speed_kmh': (position.speed * 3.6).roundToDouble(),
        'heading_degrees': position.heading,
        'accuracy_m': position.accuracy,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      if (_isConnected) {
        _publish(jsonEncode(payload));
      } else {
        // Buffer when disconnected
        if (_positionBuffer.length >= _maxBufferSize) {
          _positionBuffer.removeAt(0); // drop oldest
        }
        _positionBuffer.add(payload);
        debugPrint('[MQTT] Buffered position (${_positionBuffer.length}/$_maxBufferSize)');
      }
    } catch (e) {
      debugPrint('[MQTT] Failed to get position: $e');
    }
  }

  void _publish(String jsonPayload) {
    if (_client == null ||
        _client!.connectionStatus?.state != MqttConnectionState.connected) {
      return;
    }
    try {
      final topic = 'vehicle/$_vehicleId/location';
      final builder = MqttClientPayloadBuilder()..addString(jsonPayload);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('[MQTT] Published to $topic');
    } catch (e) {
      debugPrint('[MQTT] Publish error: $e');
    }
  }

  /// Stop publishing GPS — call when job completes or app backgrounds.
  void stopPublishing() {
    debugPrint('[MQTT] Stopping GPS publishing');
    _isPublishing = false;
    _publishTimer?.cancel();
    _publishTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _positionBuffer.clear();
  }

  /// Fully disconnect from broker.
  void disconnect() {
    stopPublishing();
    try {
      _client?.disconnect();
    } catch (_) {}
    _client = null;
    _isConnected = false;
  }

  bool get isPublishing => _isPublishing;
  bool get isConnected => _isConnected;
}
