import 'package:mqtt_client/mqtt_server_client.dart';

MqttServerClient createMqttClient(String clientId) {
  final client = MqttServerClient.withPort('broker.emqx.io', clientId, 8883);
  client.secure = true;
  return client;
}
