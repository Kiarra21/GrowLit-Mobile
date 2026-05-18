import 'package:flutter/material.dart';
import 'package:growlit_mobile/services/iot_mqtt_service.dart';
import 'package:growlit_mobile/theme/colors.dart';

class MonitoringAirScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MonitoringAirScreen({super.key, required this.onBack});

  @override
  State<MonitoringAirScreen> createState() => _MonitoringAirScreenState();
}

class _MonitoringAirScreenState extends State<MonitoringAirScreen> {
  final GrowlitMqttService _mqttService = GrowlitMqttService.instance;

  double _distanceProgress(double distance) {
    final normalized = 1 - (distance / 40);
    return normalized.clamp(0.0, 1.0);
  }

  String _getStatus(double distance) {
    if (distance >= 30) return 'Rendah';
    if (distance <= 10) return 'Tinggi';
    return 'Normal';
  }

  Color _getStatusColor(String status) {
    if (status == 'Rendah') return Colors.red;
    if (status == 'Tinggi') return Colors.blue;
    return AppColors.fernGreen;
  }

  String _getStatusDescription(String status) {
    if (status == 'Rendah') {
      return 'Ketersediaan air berada di bawah batas optimal, sistem akan mengaktifkan pompa.';
    } else if (status == 'Tinggi') {
      return 'Ketersediaan air telah mencapai batas maksimal, sistem mematikan pompa.';
    } else {
      return 'Ketersediaan air berada dalam batas optimal, sirkulasi berjalan dengan baik.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GrowlitSensorData>(
      stream: _mqttService.sensorStream,
      initialData: _mqttService.latestSensorData ?? GrowlitSensorData.placeholder(),
      builder: (context, snapshot) {
        final sensorData = snapshot.data ?? GrowlitSensorData.placeholder();
        final progress = _distanceProgress(sensorData.distance);
        final status = _getStatus(sensorData.distance);
        final statusColor = _getStatusColor(status);
        final statusDesc = _getStatusDescription(status);

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
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.darkGreen,
                            ),
                            onPressed: widget.onBack,
                          ),
                        ),
                        Text(
                          'Monitoring Air',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppColors.darkGreen,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.darkGreen.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              decoration: BoxDecoration(
                                color: AppColors.resedaGreen,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _AirGauge(
                                  value: '${sensorData.distance.toStringAsFixed(0)} cm',
                                  subtitle: status.toLowerCase(),
                                  progress: progress,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Status Air : $status',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              statusDesc,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.darkMoss.withValues(alpha: 0.7),
                                    height: 1.3,
                                    fontSize: 15,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            Divider(
                              color: AppColors.darkGreen.withValues(alpha: 0.3),
                              thickness: 1,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Setelan Otomatis',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.darkMoss,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _ControlButton(
                                    icon: Icons.water_drop,
                                    label: '> 30cm',
                                    isActive: true,
                                    onTap: () {
                                      _mqttService.publishCommand('pump_on');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _ControlButton(
                                    icon: Icons.format_color_reset_rounded,
                                    label: '< 10cm',
                                    isActive: false,
                                    onTap: () {
                                      _mqttService.publishCommand('pump_off');
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AirGauge extends StatelessWidget {
  const _AirGauge({
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
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base untuk membuat shadow tanpa bocor ke tengah (warna sama dengan background)
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.resedaGreen,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 20,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE8E8E8)),
            ),
          ),
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 20,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation(AppColors.darkMoss), // Make progress dark like the mockup
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.resedaGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
