import 'package:flutter/material.dart';
import 'package:growlit_mobile/theme/colors.dart';

class NotificationItem {
  const NotificationItem({
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

const List<NotificationItem> _kTodayNotifications = [
  NotificationItem(
    title: 'Pengairan Otomatis',
    message: 'Pompa dinyalakan karena ketinggian air rendah',
    time: '08:12',
    icon: Icons.water_drop_rounded,
  ),
  NotificationItem(
    title: 'Pencahayaan',
    message: 'Lampu LED dinyalakan karena intensitas cahaya rendah',
    time: '07:45',
    icon: Icons.light_mode_rounded,
  ),
  NotificationItem(
    title: 'Pengairan',
    message: 'Pengisian selesai, pompa dimatikan',
    time: '06:30',
    icon: Icons.check_circle_outline,
  ),
];

const List<NotificationItem> _kYesterdayNotifications = [
  NotificationItem(
    title: 'Pencahayaan',
    message: 'Intensitas cahaya tinggi — lampu dimatikan',
    time: '18:20',
    icon: Icons.light_mode_rounded,
  ),
  NotificationItem(
    title: 'Pengairan Otomatis',
    message: 'Pompa menyala (jadwal berkala)',
    time: '12:05',
    icon: Icons.water_drop_rounded,
  ),
];

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9F3),
              Color(0xFFEAF3BE),
              AppColors.lightGreen,
            ],
            stops: [0.0, 0.36, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Notifikasi',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.darkGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionLabel(title: 'Hari ini'),
                const SizedBox(height: 10),
                ..._kTodayNotifications.map((n) => _NotificationTile(item: n)),
                const SizedBox(height: 18),
                _SectionLabel(title: 'Kemarin'),
                const SizedBox(height: 10),
                ..._kYesterdayNotifications.map(
                  (n) => _NotificationTile(item: n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.darkGreen.withValues(alpha: 0.72),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: AppColors.resedaGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkGreen.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.time,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.darkGreen.withValues(alpha: 0.56),
            ),
          ),
        ],
      ),
    );
  }
}
