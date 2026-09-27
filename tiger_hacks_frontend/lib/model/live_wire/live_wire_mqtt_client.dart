import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:tiger_hacks_frontend/model/live_wire/live_source.dart';

import 'mqtt_client_factory_stub.dart'
    if (dart.library.io) 'mqtt_client_factory_io.dart'
    if (dart.library.js_interop) 'mqtt_client_factory_web.dart'
    as client_factory;

class LiveWireEnvelope {
  const LiveWireEnvelope({required this.topic, required this.payload});

  final String topic;
  final Map<String, dynamic> payload;
}

class LiveWireMqttClient {
  LiveWireMqttClient({String? clientId})
    : _client = _createClient(clientId ?? _newClientId()) {
    _client.onAutoReconnected = _flushPending;
  }

  final StreamController<LiveWireEnvelope> _messages =
      StreamController<LiveWireEnvelope>.broadcast();
  final StreamController<Object> _connectionErrors =
      StreamController<Object>.broadcast();
  final Set<String> _subscriptions = {};
  final Map<String, Map<String, dynamic>> _pendingMeasures = {};
  final Map<String, Map<String, dynamic>> _pendingEmergencies = {};
  MqttClient _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updates;
  Future<void>? _connectFuture;
  Timer? _retryTimer;
  bool _connectedOnce = false;
  bool _disposed = false;

  Stream<LiveWireEnvelope> get messages => _messages.stream;
  Stream<Object> get connectionErrors => _connectionErrors.stream;

  bool get isConnected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;

  static String topicForUser(int userId) => 'live-wire/user/$userId';

  static int? userIdFromTopic(String topic) {
    final match = RegExp(r'^live-wire/user/(\d+)$').firstMatch(topic);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static Map<String, dynamic> measureEnvelope(Map<MeasureType, num> values) => {
    'type': 'measure',
    'values': {for (final entry in values.entries) entry.key.name: entry.value},
  };

  Future<void> connect() {
    if (_disposed || isConnected) return Future<void>.value();
    final currentAttempt = _connectFuture;
    if (currentAttempt != null) return currentAttempt;

    late final Future<void> attempt;
    attempt = _connect().whenComplete(() {
      if (identical(_connectFuture, attempt)) _connectFuture = null;
    });
    _connectFuture = attempt;
    return attempt;
  }

  Future<void> _connect() async {
    try {
      final status = await _client.connect();
      if (_disposed) {
        _client.disconnect();
        return;
      }
      if (status?.state != MqttConnectionState.connected) {
        throw StateError('Could not connect to the LiveWire MQTT broker.');
      }

      _connectedOnce = true;
      _retryTimer?.cancel();
      _updates ??= _client.updates?.listen(
        _handleUpdates,
        onError: _connectionErrors.add,
      );
      for (final topic in _subscriptions) {
        _client.subscribe(topic, MqttQos.atLeastOnce);
      }
      _flushPending();
    } catch (error) {
      if (_disposed) return;
      _connectionErrors.add(error);
      if (!_connectedOnce) {
        try {
          _client.disconnect();
        } catch (_) {
          // The client may not have established a connection.
        }
        _client = _createClient(_newClientId())
          ..onAutoReconnected = _flushPending;
      }
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_disposed || _retryTimer != null) return;
    _retryTimer = Timer(const Duration(seconds: 5), () {
      _retryTimer = null;
      unawaited(connect());
    });
  }

  void subscribe(String topic) {
    if (!_subscriptions.add(topic)) return;
    if (isConnected) _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  void unsubscribe(String topic) {
    if (!_subscriptions.remove(topic)) return;
    if (isConnected) _client.unsubscribe(topic);
  }

  void publishMeasures(int userId, Map<MeasureType, num> values) {
    if (values.isEmpty) return;
    _publishOrQueue(topicForUser(userId), measureEnvelope(values));
  }

  void publishEmergency(int userId) {
    final eventId =
        '$userId-${DateTime.now().microsecondsSinceEpoch}-'
        '${Random().nextInt(1 << 32).toRadixString(16)}';
    _publishOrQueue(topicForUser(userId), {
      'type': 'emergency',
      'event_id': eventId,
    });
  }

  void _publishOrQueue(String topic, Map<String, dynamic> payload) {
    if (_send(topic, payload)) return;
    if (payload['type'] == 'measure') {
      _pendingMeasures[topic] = payload;
    } else if (payload['type'] == 'emergency') {
      _pendingEmergencies[topic] = payload;
    }
    unawaited(connect());
  }

  bool _send(String topic, Map<String, dynamic> payload) {
    if (!isConnected) return false;
    final builder = MqttClientPayloadBuilder()
      ..addUTF8String(jsonEncode(payload));
    try {
      _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      return true;
    } catch (error) {
      _connectionErrors.add(error);
      return false;
    }
  }

  void _flushPending() {
    for (final entry in _pendingEmergencies.entries.toList()) {
      if (!_send(entry.key, entry.value)) return;
      _pendingEmergencies.remove(entry.key);
    }
    for (final entry in _pendingMeasures.entries.toList()) {
      if (!_send(entry.key, entry.value)) return;
      _pendingMeasures.remove(entry.key);
    }
  }

  void _handleUpdates(List<MqttReceivedMessage<MqttMessage>> updates) {
    for (final update in updates) {
      final message = update.payload;
      if (message is! MqttPublishMessage) continue;
      final text = MqttPublishPayload.bytesToStringAsString(
        message.payload.message,
      );
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          _messages.add(
            LiveWireEnvelope(
              topic: update.topic,
              payload: Map<String, dynamic>.from(decoded),
            ),
          );
        }
      } on FormatException {
        _connectionErrors.add(const FormatException('Invalid MQTT JSON.'));
      } on TypeError {
        _connectionErrors.add(
          const FormatException('MQTT payload must be a JSON object.'),
        );
      }
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _retryTimer?.cancel();
    await _updates?.cancel();
    if (isConnected) _client.disconnect();
    await _messages.close();
    await _connectionErrors.close();
  }

  static MqttClient _createClient(String clientId) {
    final client = client_factory.createMqttClient(clientId);
    client.autoReconnect = true;
    client.keepAlivePeriod = 30;
    client.logging(on: false, logPayloads: false);
    return client;
  }

  static String _newClientId() {
    final suffix = Random().nextInt(1 << 32).toRadixString(16);
    return 'livewire-${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }
}
