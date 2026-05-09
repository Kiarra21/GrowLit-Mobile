import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class GrowlitSensorData {
  const GrowlitSensorData({
    required this.ldr,
    required this.distance,
    required this.lampOn,
    required this.pumpOn,
    required this.receivedAt,
  });

  final int ldr;
  final double distance;
  final bool lampOn;
  final bool pumpOn;
  final DateTime receivedAt;

  factory GrowlitSensorData.fromJson(Map<String, dynamic> json) {
    return GrowlitSensorData(
      ldr: (json['ldr'] as num?)?.toInt() ?? 0,
      distance: (json['jarak'] as num?)?.toDouble() ?? 0,
      lampOn: json['lampu'] == true,
      pumpOn: json['pompa'] == true,
      receivedAt: DateTime.now(),
    );
  }

  static GrowlitSensorData placeholder() {
    return GrowlitSensorData(
      ldr: 0,
      distance: 0,
      lampOn: false,
      pumpOn: false,
      receivedAt: DateTime.now(),
    );
  }
}

class GrowlitMqttService {
  GrowlitMqttService._()
    : _client = MqttServerClient.withPort(
    _brokerHost,
    _clientId,
    _brokerPort,
    ) {
    // Use MQTT over TCP/TLS (port 8883) to match ESP32 connection
    _client.useWebSocket = false;
    _client.secure = true; // TLS over WebSocket

    // ✅ Accept semua certificate (untuk development)
    _client.onBadCertificate = (dynamic cert) => true;

    _client.logging(on: kDebugMode);
    _client.setProtocolV311();
    _client.connectTimeoutPeriod = 20000; // increase timeout for mobile networks
    _client.keepAlivePeriod = 30;
    _client.autoReconnect = true;
    _client.resubscribeOnAutoReconnect = true;
    _client.onConnected = _handleConnected;
    _client.onDisconnected = _handleDisconnected;
    _client.onAutoReconnect = _handleAutoReconnect;
    _client.onAutoReconnected = _handleAutoReconnected;
    _client.onSubscribed = _handleSubscribed;
    _client.onFailedConnectionAttempt = _handleFailedConnectionAttempt;
    _client.connectionMessage = MqttConnectMessage()
      .withClientIdentifier(_clientId)
      .startClean()
      .withWillQos(MqttQos.atLeastOnce)
      .authenticateAs(_brokerUser, _brokerPassword); // credentials

    _updatesSubscription = _client.updates?.listen(_handleUpdates);
  }

  // ✅ HiveMQ Cloud settings (sama seperti ESP32)
  static const String _brokerHost =
      'a9bb0e5dfc5b4a7e90e4631d05616ee8.s1.eu.hivemq.cloud';
  static const int _brokerPort = 8883; // MQTT over TLS
  static const String _brokerUser = 'growlit';
  static const String _brokerPassword = 'Growlit123';
  static final String _clientId = 'GrowLit_Flutter_${DateTime.now().millisecondsSinceEpoch}';

  static const String sensorTopic = 'growlit/sensor';
  static const String controlTopic = 'growlit/control';

  static final GrowlitMqttService instance = GrowlitMqttService._();

  final MqttServerClient _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>?
      _updatesSubscription;

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  final StreamController<GrowlitSensorData> _sensorController =
      StreamController<GrowlitSensorData>.broadcast();

  GrowlitSensorData? _latestSensorData;
  bool _connecting = false;

  Stream<GrowlitSensorData> get sensorStream => _sensorController.stream;
  GrowlitSensorData? get latestSensorData => _latestSensorData;

  Future<void> connect() async {
    if (kDebugMode) {
      debugPrint(
        'GrowlitMqttService: connect() called; '
        'state=${_client.connectionStatus?.state}',
      );
    }

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      return;
    }
    if (_connecting) return;

    _connecting = true;
    lastError.value = null;

    try {
      await _client.connect();

      final state = _client.connectionStatus?.state;
      final returnCode = _client.connectionStatus?.returnCode;
      if (kDebugMode) {
        debugPrint('MQTT connection status: $state, returnCode: $returnCode');
      }

      if (state != MqttConnectionState.connected) {
        final msg = 'MQTT connection failed: $state (returnCode=$returnCode)';
        isConnected.value = false;
        lastError.value = msg;
        if (kDebugMode) debugPrint(msg);
        _client.disconnect();
        throw StateError(msg);
      }

      _client.subscribe(sensorTopic, MqttQos.atLeastOnce);
      isConnected.value = true;
    } on Exception catch (e) {
      isConnected.value = false;
      final status = _client.connectionStatus;
      final msg = 'MQTT exception: ${e.toString()} (status=$status)';
      lastError.value = msg;
      if (kDebugMode) debugPrint(msg);
      _client.disconnect();
      rethrow;
    } catch (error) {
      isConnected.value = false;
      final status = _client.connectionStatus;
      final msg = 'Tidak bisa connect MQTT: $error (status=$status)';
      lastError.value = msg;
      if (kDebugMode) debugPrint(msg);
      _client.disconnect();
      rethrow;
    } finally {
      _connecting = false;
    }
  }

  void publishCommand(String command) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      lastError.value = 'MQTT belum tersambung.';
      return;
    }
    final builder = MqttClientPayloadBuilder()..addString(command);
    _client.publishMessage(controlTopic, MqttQos.atLeastOnce, builder.payload!);
  }

  void dispose() {
    _updatesSubscription?.cancel();
    _sensorController.close();
    isConnected.dispose();
    lastError.dispose();
    _client.disconnect();
  }

  void _handleUpdates(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final event in events) {
      final message = event.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        message.payload.message,
      );
      if (kDebugMode) debugPrint('MQTT received: $payload');

      try {
        final decoded = jsonDecode(payload) as Map<String, dynamic>;
        final sensorData = GrowlitSensorData.fromJson(decoded);
        _latestSensorData = sensorData;
        _sensorController.add(sensorData);
      } catch (error) {
        lastError.value = 'Payload MQTT tidak valid: $error';
      }
    }
  }

  void _handleConnected() {
    if (kDebugMode) debugPrint('MQTT: Connected!');
    isConnected.value = true;
    lastError.value = null;
  }

  void _handleDisconnected() {
    if (kDebugMode) debugPrint('MQTT: Disconnected.');
    isConnected.value = false;
  }

  void _handleAutoReconnect() {
    if (kDebugMode) debugPrint('MQTT: Auto reconnecting...');
    isConnected.value = false;
  }

  void _handleAutoReconnected() {
    if (kDebugMode) debugPrint('MQTT: Auto reconnected!');
    isConnected.value = true;
    _client.subscribe(sensorTopic, MqttQos.atLeastOnce);
  }

  void _handleSubscribed(String topic) {
    if (kDebugMode) debugPrint('MQTT: Subscribed to $topic');
  }

  void _handleFailedConnectionAttempt(int attempt) {
    isConnected.value = false;
    lastError.value = 'MQTT gagal tersambung ke HiveMQ Cloud (percobaan $attempt).';
    if (kDebugMode) debugPrint(lastError.value);
  }
}