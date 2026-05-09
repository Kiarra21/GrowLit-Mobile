import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:growlit_mobile/services/iot_mqtt_service.dart';
import 'package:growlit_mobile/theme/colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GrowlitMqttService _mqttService = GrowlitMqttService.instance;
  int _lastNotifiedCount = 0;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      if (kDebugMode) {
        debugPrint('Dashboard: starting MQTT connect()');
      }
      try {
        await _mqttService.connect();
      } catch (_) {
        // Connection state is surfaced in the UI through the service notifiers.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mqttService = GrowlitMqttService.instance;
    final notificationCount = mqttService.notifications.value.length;

    if (notificationCount > _lastNotifiedCount) {
      _lastNotifiedCount = notificationCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final latest = mqttService.notifications.value.firstOrNull;
        if (latest == null) return;

        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('${latest.title}: ${latest.message}'),
              duration: const Duration(seconds: 3),
              backgroundColor: AppColors.resedaGreen,
            ),
          );
      });
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _mqttService.isConnected,
        _mqttService.lastError,
        mqttService.notifications,
      ]),
      builder: (context, _) {
        return StreamBuilder<GrowlitSensorData>(
          stream: _mqttService.sensorStream,
          initialData:
              _mqttService.latestSensorData ?? GrowlitSensorData.placeholder(),
          builder: (context, snapshot) {
            final sensorData = snapshot.data ?? GrowlitSensorData.placeholder();

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Container(
                constraints: const BoxConstraints.expand(),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF7FAF1),
                      Color(0xFFEAF5C8),
                      Color(0xFFCBEA77),
                    ],
                    stops: [0.0, 0.38, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, User !',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        color: AppColors.darkGreen,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Data kebun masuk dari MQTT HiveMQ Cloud',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.darkGreen.withValues(
                                          alpha: 0.72,
                                        ),
                                        fontSize: 15,
                                      ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.resedaGreen,
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ConnectionBanner(
                          isConnected: _mqttService.isConnected.value,
                          message: _mqttService.lastError.value,
                        ),
                        const SizedBox(height: 18),
                        _MetricCard(
                          title: 'Ketersediaan Air',
                          value: '${sensorData.distance.toStringAsFixed(1)} cm',
                          subtitle: sensorData.pumpOn
                              ? 'pompa menyala'
                              : 'pompa mati',
                          progress: _distanceProgress(sensorData.distance),
                        ),
                        const SizedBox(height: 14),
                        _MetricCard(
                          title: 'Intensitas Cahaya',
                          value: sensorData.ldr.toString(),
                          subtitle: sensorData.lampOn
                              ? 'lampu menyala'
                              : 'lampu mati',
                          progress: _ldrProgress(sensorData.ldr),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _distanceProgress(double distance) {
    final normalized = 1 - (distance / 20);
    return normalized.clamp(0.0, 1.0);
  }

  double _ldrProgress(int ldr) {
    final normalized = ldr / 4095;
    return normalized.clamp(0.0, 1.0);
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.isConnected, required this.message});

  final bool isConnected;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final background = isConnected
        ? const Color(0xFFE7F4D6)
        : const Color(0xFFFDEBD7);
    final accent = isConnected
        ? AppColors.resedaGreen
        : const Color(0xFFC06A2C);
    final label = isConnected ? 'MQTT tersambung' : 'MQTT belum tersambung';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.darkGreen.withValues(alpha: 0.72),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
  });

  final String title;
  final String value;
  final String subtitle;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.11),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Icon(Icons.circle, color: AppColors.lightGreen, size: 14),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: _Semi3DDiagram(
              value: value,
              subtitle: subtitle,
              progress: progress,
            ),
          ),
        ],
      ),
    );
  }
}

class _Semi3DDiagram extends StatelessWidget {
  const _Semi3DDiagram({
    required this.value,
    required this.subtitle,
    required this.progress,
  });

  final String value;
  final String subtitle;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 176,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 4,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB9B9B9).withValues(alpha: 0.25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 142,
            height: 142,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkGreen.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 128,
            height: 128,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 14,
              backgroundColor: const Color(0xFFD8D8D8),
              valueColor: const AlwaysStoppedAnimation(AppColors.resedaGreen),
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.35, -0.35),
                radius: 1.0,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF7FAF1),
                  Color(0xFFE7E7E7),
                ],
                stops: [0.0, 0.8, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.85),
                  blurRadius: 6,
                  offset: const Offset(-2, -2),
                ),
                BoxShadow(
                  color: AppColors.darkGreen.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.darkGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.darkGreen.withValues(alpha: 0.62),
                          fontSize: 10.5,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

