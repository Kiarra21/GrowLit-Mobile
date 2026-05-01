import 'dart:async';
import 'package:flutter/material.dart';
import 'package:growlit_mobile/features/splash/presentation/screens/splash_screen_two.dart';
import 'package:growlit_mobile/theme/colors.dart';

class SplashScreenOne extends StatefulWidget {
  const SplashScreenOne({super.key});

  @override
  State<SplashScreenOne> createState() => _SplashScreenOneState();
}

class _SplashScreenOneState extends State<SplashScreenOne> {
  double _blobProgress = 0;
  double _blobScale = 0.42;
  double _blobOpacity = 1;
  double _logoOpacity = 0;
  double _logoScale = 0.92;
  bool _leaveSoon = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 120), () {
      setState(() {
        _blobProgress = 1;
      });
    });

    Timer(const Duration(milliseconds: 920), () {
      if (!mounted) return;
      setState(() {
        _blobScale = 0.94;
      });
    });

    Timer(const Duration(milliseconds: 1680), () {
      if (!mounted) return;
      setState(() {
        _blobOpacity = 0;
        _logoOpacity = 1;
        _logoScale = 1;
      });
    });

    Timer(const Duration(milliseconds: 2440), () {
      if (!mounted) return;
      setState(() {
        _leaveSoon = true;
      });
    });

    Timer(const Duration(milliseconds: 2790), () {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(_buildRoute(const SplashScreenTwo()));
    });
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF7F7F7),
              Color(0xFFEFEFEF),
              Colors.white,
              Color(0xFFF0F0F0),
            ],
            stops: [0.0, 0.25, 0.55, 0.78, 1.0],
          ),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 920),
              curve: Curves.easeOutCubic,
              alignment: Alignment(
                0,
                0.72 - (0.72 * Curves.easeOutCubic.transform(_blobProgress)),
              ),
              child: AnimatedScale(
                scale: _blobScale,
                duration: const Duration(milliseconds: 920),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: _blobOpacity,
                  duration: const Duration(milliseconds: 620),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: 98,
                    height: 98,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lightGreen.withValues(alpha: 0.28),
                          blurRadius: 30,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: AnimatedOpacity(
                opacity: _logoOpacity,
                duration: const Duration(milliseconds: 760),
                curve: Curves.easeOutCubic,
                child: AnimatedScale(
                  scale: _logoScale,
                  duration: const Duration(milliseconds: 760),
                  curve: Curves.easeOutBack,
                  child: Hero(
                    tag: 'growlit-logo',
                    child: Image.asset(
                      'asset/img/logo.png',
                      width: 116,
                      height: 116,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _leaveSoon ? 0.04 : 0,
              duration: const Duration(milliseconds: 360),
              child: const SizedBox.expand(),
            ),
          ],
        ),
      ),
    );
  }
}
