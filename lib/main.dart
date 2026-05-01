import 'package:flutter/material.dart';
import 'package:growlit_mobile/features/splash/presentation/screens/splash_screen_one.dart';
import 'package:growlit_mobile/theme/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowLit',
      theme: appTheme,
      home: const SplashScreenOne(),
      debugShowCheckedModeBanner: false,
    );
  }
}
