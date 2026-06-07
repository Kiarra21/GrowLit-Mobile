import 'package:flutter/material.dart';
import 'package:growlit_mobile/services/session_service.dart';
import 'package:growlit_mobile/theme/colors.dart';

import 'account_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key, required this.username, required this.email});

  final String? username;
  final String? email;

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  int _selectedIndex = 0;

  String get _username {
    final value = widget.username?.trim();
    return value == null || value.isEmpty ? 'User' : value;
  }

  String get _email {
    final value = widget.email?.trim();
    return value == null || value.isEmpty ? '-' : value;
  }

  late final List<Widget> _pages = <Widget>[
    DashboardScreen(username: _username),
    const NotificationsScreen(),
    const HistoryScreen(),
    AccountScreen(
      username: _username,
      email: _email,
      onLogoutPressed: _showLogoutDialog,
    ),
  ];

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            width: 280,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkGreen.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8F0D3),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.resedaGreen,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Apakah anda yakin ingin melakukan logout ?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.resedaGreen),
                          foregroundColor: AppColors.resedaGreen,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          SessionService.instance.clearSession();
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.resedaGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _GrowlitBottomNav(
        selectedIndex: _selectedIndex,
        onChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class _GrowlitBottomNav extends StatelessWidget {
  const _GrowlitBottomNav({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF3C4B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                label: 'Beranda',
                icon: Icons.home_rounded,
                selected: selectedIndex == 0,
                onTap: () => onChanged(0),
              ),
              _NavItem(
                label: 'Notifikasi',
                icon: Icons.notifications_rounded,
                selected: selectedIndex == 1,
                onTap: () => onChanged(1),
              ),
              _NavItem(
                label: 'History',
                icon: Icons.history_rounded,
                selected: selectedIndex == 2,
                onTap: () => onChanged(2),
              ),
              _NavItem(
                label: 'Akun',
                icon: Icons.person_rounded,
                selected: selectedIndex == 3,
                onTap: () => onChanged(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.72);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              width: selected ? 22 : 0,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
