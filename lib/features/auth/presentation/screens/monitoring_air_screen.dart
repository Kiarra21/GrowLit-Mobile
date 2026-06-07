import 'package:flutter/material.dart';
import 'package:growlit_mobile/services/iot_mqtt_service.dart';
import 'package:growlit_mobile/theme/colors.dart';

class MonitoringAirScreen extends StatefulWidget {
  const MonitoringAirScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<MonitoringAirScreen> createState() => _MonitoringAirScreenState();
}

class _MonitoringAirScreenState extends State<MonitoringAirScreen> {
  static const double _minWaterHeightCm = 2.0;
  static const double _maxWaterHeightCm = 2.5;

  final GrowlitMqttService _mqttService = GrowlitMqttService.instance;

  double _heightProgress(double height) {
    return (height / _maxWaterHeightCm).clamp(0.0, 1.0);
  }

  String _status(double height) {
    if (height < _minWaterHeightCm) return 'Kurang';
    if (height > _maxWaterHeightCm) return 'Berlebih';
    return 'Normal';
  }

  Color _statusColor(String status) {
    if (status == 'Normal') return AppColors.fernGreen;
    return const Color(0xFFC06A2C);
  }

  String _statusDescription(String status) {
    if (status == 'Kurang') {
      return 'Tinggi air di bawah 2 cm, pompa akan menyala otomatis.';
    }
    if (status == 'Berlebih') {
      return 'Tinggi air sudah melewati batas normal 2.5 cm. Pompa akan tetap mati.';
    }
    return 'Tinggi air berada di rentang normal 2 sampai 2.5 cm.';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GrowlitSensorData>(
      stream: _mqttService.sensorStream,
      initialData:
          _mqttService.latestSensorData ?? GrowlitSensorData.placeholder(),
      builder: (context, snapshot) {
        final sensorData = snapshot.data ?? GrowlitSensorData.placeholder();
        final status = _status(sensorData.distance);
        final statusColor = _statusColor(status);

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MonitoringHeader(
                      title: 'Tinggi Air',
                      subtitle: 'Monitoring tinggi air hidroponik',
                      icon: Icons.water_drop_rounded,
                      onBack: widget.onBack,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          _SensorGauge(
                            value:
                                '${sensorData.distance.toStringAsFixed(1)} cm',
                            subtitle: status.toLowerCase(),
                            progress: _heightProgress(sensorData.distance),
                            icon: Icons.water_drop_rounded,
                          ),
                          const SizedBox(height: 18),
                          _StatusPanel(
                            title: 'Status Air : $status',
                            description: _statusDescription(status),
                            color: statusColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Setelan Otomatis',
                      children: const [
                        _RuleTile(
                          icon: Icons.water_drop_rounded,
                          title: 'Pompa menyala',
                          subtitle: 'Jika tinggi air < 2 cm',
                        ),
                        SizedBox(height: 10),
                        _RuleTile(
                          icon: Icons.format_color_reset_rounded,
                          title: 'Pompa mati',
                          subtitle: 'Jika tinggi air >= 2 cm',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.darkGreen.withValues(alpha: 0.11),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class _MonitoringHeader extends StatelessWidget {
  const _MonitoringHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.darkGreen,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.resedaGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.darkGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.darkGreen.withValues(alpha: 0.68),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SensorGauge extends StatelessWidget {
  const _SensorGauge({
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.icon,
  });

  final String value;
  final String subtitle;
  final double progress;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 188,
      height: 188,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 4,
            child: Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB9B9B9).withValues(alpha: 0.22),
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
          SizedBox(
            width: 142,
            height: 142,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 14,
              backgroundColor: const Color(0xFFD8D8D8),
              valueColor: const AlwaysStoppedAnimation(AppColors.resedaGreen),
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.35, -0.35),
                radius: 1.0,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF7FAF1),
                  Color(0xFFE7E7E7),
                ],
                stops: [0.0, 0.8, 1.0],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.resedaGreen, size: 22),
                const SizedBox(height: 6),
                FittedBox(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.darkGreen.withValues(alpha: 0.62),
                    fontSize: 11,
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

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.title,
    required this.description,
    required this.color,
  });

  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.darkGreen.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.resedaGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.resedaGreen, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.darkGreen.withValues(alpha: 0.66),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
