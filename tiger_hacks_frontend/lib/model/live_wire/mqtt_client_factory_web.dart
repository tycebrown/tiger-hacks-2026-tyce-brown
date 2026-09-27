import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClient(String clientId) =>
    MqttBrowserClient.withPort('wss://broker.emqx.io/mqtt', clientId, 8084);
