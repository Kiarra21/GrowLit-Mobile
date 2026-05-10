import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:growlit_mobile/firebase_options.dart';
import 'package:growlit_mobile/features/splash/presentation/screens/splash_screen_one.dart';
import 'package:growlit_mobile/services/history_service.dart';
import 'package:growlit_mobile/services/local_notification_service.dart';
import 'package:growlit_mobile/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    debugPrint('Firebase not configured for this platform.');
  } on FirebaseException catch (error) {
    debugPrint('Firebase initialization skipped: ${error.message}');
  }

  try {
    await GrowlitLocalNotificationService.instance.initialize();
  } catch (error) {
    debugPrint('Local notifications initialization skipped: $error');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _historyTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startFiveSecondHistoryTimer();
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startFiveSecondHistoryTimer();
    }
  }

  void _startFiveSecondHistoryTimer() {
    _historyTimer?.cancel();

    _historyTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveHistorySnapshot();
    });
  }

  Future<void> _saveHistorySnapshot() async {
    try {
      await HistoryService.instance.saveDailyHistory();
    } catch (error) {
      debugPrint('Five-second history save skipped: $error');
    }
  }

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
