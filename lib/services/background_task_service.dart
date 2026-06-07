import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:growlit_mobile/firebase_options.dart';
import 'package:workmanager/workmanager.dart';
import 'history_service.dart';

/// Background task callback untuk workmanager
/// Ini akan dipanggil sesuai schedule yang ditentukan
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (kDebugMode) {
        debugPrint('[BackgroundTask] Executing task: $task');
      }

      if (task == 'saveDailyHistory') {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        // Eksekusi fungsi untuk menyimpan history
        await HistoryService.instance.saveDailyHistoryIfDue();
      }

      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[BackgroundTask] Error: $error');
      }
      return false;
    }
  });
}

class BackgroundTaskService {
  BackgroundTaskService._();

  static final BackgroundTaskService instance = BackgroundTaskService._();

  /// Initialize background task scheduler
  /// Harus dipanggil di main() sebelum runApp()
  Future<void> initialize() async {
    try {
      await Workmanager().initialize(callbackDispatcher);

      if (kDebugMode) {
        debugPrint('[BackgroundTaskService] Initialized successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[BackgroundTaskService] Initialization error: $error');
      }
    }
  }

  /// Schedule daily history task mendekati akhir hari.
  Future<void> scheduleDailyHistory() async {
    try {
      await Workmanager().registerPeriodicTask(
        'saveDailyHistory',
        'saveDailyHistory',
        frequency: const Duration(hours: 24),
        initialDelay: _calculateInitialDelay(),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        tag: 'saveDailyHistory',
      );

      if (kDebugMode) {
        debugPrint('[BackgroundTaskService] Daily history task scheduled');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[BackgroundTaskService] Schedule error: $error');
      }
    }
  }

  /// Cancel scheduled task
  Future<void> cancelDailyHistory() async {
    try {
      await Workmanager().cancelByUniqueName('saveDailyHistory');
      if (kDebugMode) {
        debugPrint('[BackgroundTaskService] Daily history task cancelled');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[BackgroundTaskService] Cancel error: $error');
      }
    }
  }

  /// Hitung waktu tunggu sampai jam 23:59.
  Duration _calculateInitialDelay() {
    final now = DateTime.now();
    final targetTime = DateTime(now.year, now.month, now.day, 23, 59);

    Duration delay;
    if (now.isAfter(targetTime)) {
      delay = targetTime.add(const Duration(days: 1)).difference(now);
    } else {
      delay = targetTime.difference(now);
    }

    if (kDebugMode) {
      debugPrint(
        '[BackgroundTaskService] Initial delay: ${delay.inHours}h ${delay.inMinutes % 60}m',
      );
    }

    return delay;
  }
}
