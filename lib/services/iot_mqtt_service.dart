import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:growlit_mobile/services/local_notification_service.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GrowlitNotificationItem {
  const GrowlitNotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
  });

  final String title;
  final String message;
  final String time;
  final IconData icon;
}

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

  Map<String, dynamic> toJson() {
    return {
      'ldr': ldr,
      'jarak': distance,
      'lampu': lampOn,
      'pompa': pumpOn,
      'receivedAt': receivedAt,
    };
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
    : _client = MqttServerClient.withPort(_brokerHost, _clientId, _brokerPort) {
    // Prefer MQTT over secure WebSocket on mobile networks.
    _client.useWebSocket = true;
    // For WSS, provide a wss:// URI and keep secure=false.
    // In mqtt_client, secure=true is for TLS TCP and disables websocket mode.
    _client.secure = false;
    _client.websocketProtocols = const ['mqtt'];

    // ✅ Accept semua certificate (untuk development)
    _client.onBadCertificate = (dynamic cert) => true;

    _client.logging(on: kDebugMode);
    _client.setProtocolV311();
    _client.connectTimeoutPeriod =
        20000; // increase timeout for mobile networks
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
        .authenticateAs(_brokerUser, _brokerPassword); // credentials
  }

  // ✅ HiveMQ Cloud settings (sama seperti ESP32)
  static const String _brokerHost =
      'wss://a9bb0e5dfc5b4a7e90e4631d05616ee8.s1.eu.hivemq.cloud/mqtt';
  static const int _brokerPort = 8884; // MQTT over secure WebSocket
  static const String _brokerUser = 'growlit';
  static const String _brokerPassword = 'Growlit123';
  static final String _clientId =
      'GrowLit_Flutter_${DateTime.now().millisecondsSinceEpoch}';

  static const String sensorTopic = 'growlit/sensor';
  static const String controlTopic = 'growlit/control';

  static final GrowlitMqttService instance = GrowlitMqttService._();

  final MqttServerClient _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>?
  _updatesSubscription;

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  final ValueNotifier<List<GrowlitNotificationItem>> notifications =
      ValueNotifier<List<GrowlitNotificationItem>>(<GrowlitNotificationItem>[]);
  final StreamController<GrowlitSensorData> _sensorController =
      StreamController<GrowlitSensorData>.broadcast();

  GrowlitSensorData? _latestSensorData;
  bool _connecting = false;
  bool? _lastLampOn;
  bool? _lastPumpOn;

  Stream<GrowlitSensorData> get sensorStream => _sensorController.stream;
  GrowlitSensorData? get latestSensorData => _latestSensorData;

  Future<void> connect() async {
    final currentState = _client.connectionStatus?.state;
    if (kDebugMode) {
      debugPrint(
        'GrowlitMqttService: connect() called; '
        'state=$currentState',
      );
    }

    if (currentState == MqttConnectionState.connected) {
      return;
    }
    if (currentState == MqttConnectionState.connecting) return;
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
      _ensureUpdatesSubscription();
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
    _updatesSubscription = null;
    _sensorController.close();
    isConnected.dispose();
    lastError.dispose();
    notifications.dispose();
    _client.disconnect();
  }

  void _ensureUpdatesSubscription() {
    if (_updatesSubscription != null) {
      return;
    }
    _updatesSubscription = _client.updates!.listen(_handleUpdates);
  }

  Future<void> _updateFirestore(GrowlitSensorData data) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final payload = data.toJson();

      await firestore.collection('status').doc('terkini').set(payload);
    } catch (e) {
      if (kDebugMode) {
        print('Gagal menyimpan status ke Firestore: $e');
      }
    }
  }

  void _handleUpdates(List<MqttReceivedMessage<MqttMessage>> event) {
    for (final message in event) {
      final MqttPublishMessage pubMess = message.payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(
        pubMess.payload.message,
      );

      if (kDebugMode) {
        debugPrint('MQTT received topic=${message.topic}: $payload');
      }

      if (message.topic == sensorTopic) {
        try {
          final data = GrowlitSensorData.fromJson(jsonDecode(payload));
          _sensorController.add(data);
          _latestSensorData = data;

          // Perbarui status di Firestore
          _updateFirestore(data);

          // Cek perubahan status untuk notifikasi
          _recordNotifications(data);
        } catch (error) {
          lastError.value = 'Payload MQTT tidak valid: $error';
        }
      }
    }
  }

  void _recordNotifications(GrowlitSensorData sensorData) {
    final items = <GrowlitNotificationItem>[];

    if (sensorData.pumpOn && _lastPumpOn != true) {
      items.add(
        GrowlitNotificationItem(
          title: 'Pompa Menyala',
          message: 'Pompa aktif otomatis karena kondisi air terdeteksi rendah.',
          time: _formatTime(sensorData.receivedAt),
          icon: Icons.water_drop_rounded,
        ),
      );
    }

    if (sensorData.lampOn && _lastLampOn != true) {
      items.add(
        GrowlitNotificationItem(
          title: 'Lampu Menyala',
          message: 'Lampu aktif otomatis karena intensitas cahaya rendah.',
          time: _formatTime(sensorData.receivedAt),
          icon: Icons.light_mode_rounded,
        ),
      );
    }

    _lastPumpOn = sensorData.pumpOn;
    _lastLampOn = sensorData.lampOn;

    if (items.isEmpty) return;

    notifications.value = <GrowlitNotificationItem>[
      ...items.reversed,
      ...notifications.value,
    ];

    for (final item in items) {
      unawaited(
        GrowlitLocalNotificationService.instance.showAlert(
          title: item.title,
          body: item.message,
          payload: item.title,
        ),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _handleConnected() {
    if (kDebugMode) debugPrint('MQTT: Connected!');
    _ensureUpdatesSubscription();
    isConnected.value = true;
    lastError.value = null;
  }

  void _handleDisconnected() {
    if (kDebugMode) {
      final status = _client.connectionStatus;
      debugPrint('MQTT: Disconnected. status=$status');
    }
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
    _ensureUpdatesSubscription();
  }

  void _handleSubscribed(String topic) {
    if (kDebugMode) debugPrint('MQTT: Subscribed to $topic');
  }

  void _handleFailedConnectionAttempt(int attempt) {
    isConnected.value = false;
    lastError.value =
        'MQTT gagal tersambung ke HiveMQ Cloud (percobaan $attempt).';
    if (kDebugMode) debugPrint(lastError.value);
  }
}
