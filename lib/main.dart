import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:growlit_mobile/firebase_options.dart';
import 'package:growlit_mobile/features/splash/presentation/screens/splash_screen_one.dart';
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
