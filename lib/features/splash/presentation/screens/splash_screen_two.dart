import 'dart:async';
import 'package:flutter/material.dart';
import 'package:growlit_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:growlit_mobile/theme/colors.dart';

class SplashScreenTwo extends StatefulWidget {
  const SplashScreenTwo({super.key});

  @override
  State<SplashScreenTwo> createState() => _SplashScreenTwoState();
}

class _SplashScreenTwoState extends State<SplashScreenTwo> {
  bool _showHeader = false;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() {
        _showHeader = true;
      });
    });

    Timer(const Duration(milliseconds: 820), () {
      if (!mounted) return;
      setState(() {
        _showButton = true;
      });
    });
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(_buildRoute(const LoginScreen()));
  }

  PageRouteBuilder<void> _buildRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 650),
      reverseTransitionDuration: const Duration(milliseconds: 450),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0.0, 0.04),
          end: Offset.zero,
        ).animate(fade);

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF7F8F1),
              Color(0xFFEAF3BE),
              AppColors.lightGreen,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -60,
                right: -42,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -40,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    AnimatedSlide(
                      offset: _showHeader
                          ? Offset.zero
                          : const Offset(0, -0.25),
                      duration: const Duration(milliseconds: 1040),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: _showHeader ? 1 : 0,
                        duration: const Duration(milliseconds: 1040),
                        curve: Curves.easeOutCubic,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GrowLit',
                                  style: theme.textTheme.displayLarge?.copyWith(
                                    fontSize: 44,
                                    height: 0.95,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Monitor, Automate, Optimize',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.darkGreen.withValues(
                                      alpha: 0.76,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Hero(
                      tag: 'growlit-logo',
                      child: Image.asset(
                        'asset/img/logo.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Spacer(),
                    AnimatedSlide(
                      offset: _showButton ? Offset.zero : const Offset(0, 0.28),
                      duration: const Duration(milliseconds: 980),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: _showButton ? 1 : 0,
                        duration: const Duration(milliseconds: 980),
                        curve: Curves.easeOutCubic,
                        child: SizedBox(
                          width: 155,
                          child: ElevatedButton(
                            onPressed: _goToLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.resedaGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
