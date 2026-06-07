import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:growlit_mobile/services/iot_mqtt_service.dart';
import 'package:growlit_mobile/theme/colors.dart';
import 'monitoring_air_screen.dart';
import 'monitoring_cahaya_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.username});

  final String? username;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum _DashboardSubView { main, air, cahaya }

class _DashboardScreenState extends State<DashboardScreen> {
  final GrowlitMqttService _mqttService = GrowlitMqttService.instance;
  int _lastNotifiedCount = 0;
  _DashboardSubView _currentView = _DashboardSubView.main;

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
    final username = widget.username?.trim().isEmpty ?? true
        ? 'User'
        : widget.username!.trim();

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
        _mqttService.isDeviceOnline,
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

            if (_currentView == _DashboardSubView.air) {
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  setState(() => _currentView = _DashboardSubView.main);
                },
                child: MonitoringAirScreen(
                  onBack: () =>
                      setState(() => _currentView = _DashboardSubView.main),
                ),
              );
            }
            if (_currentView == _DashboardSubView.cahaya) {
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  setState(() => _currentView = _DashboardSubView.main);
                },
                child: MonitoringCahayaScreen(
                  onBack: () =>
                      setState(() => _currentView = _DashboardSubView.main),
                ),
              );
            }

            return PopScope(
              canPop: true,
              child: Scaffold(
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Halo, $username !',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                      'Pantau kondisi tanamanmu dimanapun secara real-time.',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.darkGreen
                                                .withValues(alpha: 0.72),
                                            fontSize: 15,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: Container(
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ConnectionBanner(
                            isBrokerConnected: _mqttService.isConnected.value,
                            isDeviceOnline: _mqttService.isDeviceOnline.value,
                            message: _mqttService.lastError.value,
                          ),
                          const SizedBox(height: 18),
                          _MetricCard(
                            title: 'Tinggi Air',
                            value:
                                '${sensorData.distance.toStringAsFixed(1)} cm',
                            subtitle: sensorData.pumpOn
                                ? 'pompa menyala'
                                : 'pompa mati',
                            progress: _distanceProgress(sensorData.distance),
                            onTap: () {
                              setState(() {
                                _currentView = _DashboardSubView.air;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          _MetricCard(
                            title: 'Intensitas Cahaya',
                            value: '${sensorData.ldr.toStringAsFixed(1)} lx',
                            subtitle: sensorData.lampOn
                                ? 'lampu menyala'
                                : 'lampu mati',
                            progress: _ldrProgress(sensorData.ldr),
                            onTap: () {
                              setState(() {
                                _currentView = _DashboardSubView.cahaya;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
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
    const maxWaterHeightCm = 2.5;
    final normalized = distance / maxWaterHeightCm;
    return normalized.clamp(0.0, 1.0);
  }

  double _ldrProgress(double ldr) {
    const fullLux = 20.0;
    final normalized = ldr / fullLux;
    return normalized.clamp(0.0, 1.0);
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({
    required this.isBrokerConnected,
    required this.isDeviceOnline,
    required this.message,
  });

  final bool isBrokerConnected;
  final bool isDeviceOnline;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final isOnline = isBrokerConnected && isDeviceOnline;
    final background = isOnline
        ? const Color(0xFFE7F4D6)
        : const Color(0xFFFDEBD7);
    final accent = isOnline ? AppColors.resedaGreen : const Color(0xFFC06A2C);
    final label = isOnline
        ? 'Alat IoT online'
        : isBrokerConnected
        ? 'Alat IoT offline'
        : 'MQTT belum tersambung';
    final detail = isOnline
        ? 'Data sensor masuk dari alat IoT.'
        : isBrokerConnected
        ? (message ??
              'Alat IoT tidak merespons.')
        : message;

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
            isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
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
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
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
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
