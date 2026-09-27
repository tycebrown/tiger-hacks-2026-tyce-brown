import 'dart:async';

import 'package:tiger_hacks_frontend/model/live_wire/live_source.dart';
import 'package:tiger_hacks_frontend/model/live_wire/live_wire_mqtt_client.dart';

class DeviceStreamedLiveSource implements LiveSource {
  DeviceStreamedLiveSource({required this.userId});

  final int userId;
  final Map<MeasureType, num> _latestValues = {};
  final StreamController<int> _bpSys = StreamController<int>.broadcast();
  final StreamController<int> _bpDia = StreamController<int>.broadcast();
  final StreamController<int> _heartRate = StreamController<int>.broadcast();
  final StreamController<int> _respRate = StreamController<int>.broadcast();
  final StreamController<double> _temperature =
      StreamController<double>.broadcast();
  final StreamController<double> _bloodOx =
      StreamController<double>.broadcast();
  final StreamController<void> _emergencies =
      StreamController<void>.broadcast();
  final Set<String> _seenEmergencyIds = {};
  StreamSubscription<LiveWireEnvelope>? _mqttSubscription;
  LiveWireMqttClient? _client;

  Stream<void> get emergencies => _emergencies.stream;

  @override
  Map<MeasureType, num> get latestValues => Map.unmodifiable(_latestValues);

  @override
  Stream<int> get bpSysStream => _bpSys.stream;

  @override
  Stream<int> get bpDiaStream => _bpDia.stream;

  @override
  Stream<int> get heartRateStream => _heartRate.stream;

  @override
  Stream<int> get respRateStream => _respRate.stream;

  @override
  Stream<double> get tempStream => _temperature.stream;

  @override
  Stream<double> get bloodOxStream => _bloodOx.stream;

  void attach(LiveWireMqttClient client) {
    if (identical(_client, client)) return;
    _client?.unsubscribe(LiveWireMqttClient.topicForUser(userId));
    unawaited(_mqttSubscription?.cancel());
    _client = client;
    _mqttSubscription = client.messages
        .where(
          (message) => message.topic == LiveWireMqttClient.topicForUser(userId),
        )
        .listen(_handleMessage);
    client.subscribe(LiveWireMqttClient.topicForUser(userId));
  }

  void _handleMessage(LiveWireEnvelope message) {
    switch (message.payload['type']) {
      case 'measure':
        addMeasureValues(message.payload['values']);
      case 'emergency':
        final eventId = message.payload['event_id'];
        if (eventId is String && !_seenEmergencyIds.add(eventId)) return;
        if (_seenEmergencyIds.length > 128) {
          _seenEmergencyIds.remove(_seenEmergencyIds.first);
        }
        _emergencies.add(null);
    }
  }

  void addMeasureValues(Object? values) {
    if (values is! Map) return;
    for (final entry in values.entries) {
      if (entry.key is! String || entry.value is! num) continue;
      final MeasureType measure;
      try {
        measure = MeasureType.values.byName(entry.key as String);
      } on ArgumentError {
        continue;
      }
      final value = entry.value as num;
      _latestValues[measure] = value;
      switch (measure) {
        case MeasureType.bpSys:
          _bpSys.add(value.round());
        case MeasureType.bpDia:
          _bpDia.add(value.round());
        case MeasureType.heartRate:
          _heartRate.add(value.round());
        case MeasureType.respRate:
          _respRate.add(value.round());
        case MeasureType.temperature:
          _temperature.add(value.toDouble());
        case MeasureType.bloodOx:
          _bloodOx.add(value.toDouble());
      }
    }
  }

  @override
  bool hasDevice(MeasureType measureType) =>
      _latestValues.containsKey(measureType);

  @override
  bool isSimulated(MeasureType measureType) => false;

  Future<void> dispose() async {
    _client?.unsubscribe(LiveWireMqttClient.topicForUser(userId));
    await _mqttSubscription?.cancel();
    await Future.wait([
      _bpSys.close(),
      _bpDia.close(),
      _heartRate.close(),
      _respRate.close(),
      _temperature.close(),
      _bloodOx.close(),
      _emergencies.close(),
    ]);
  }
}
