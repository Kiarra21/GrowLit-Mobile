import 'package:flutter/foundation.dart';
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

  /// Schedule daily history task pada jam 00:17 WIB (test)
  Future<void> scheduleDailyHistory() async {
    try {
      await Workmanager().registerPeriodicTask(
        'saveDailyHistory',
        'saveDailyHistory',
        frequency: const Duration(hours: 24),
        initialDelay: _calculateInitialDelay(),
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
      await Workmanager().cancelByTag('saveDailyHistory');
      if (kDebugMode) {
        debugPrint('[BackgroundTaskService] Daily history task cancelled');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[BackgroundTaskService] Cancel error: $error');
      }
    }
  }

  /// Hitung waktu tunggu sampai jam 00:17 WIB (test)
  Duration _calculateInitialDelay() {
    final now = DateTime.now();
    final targetTime = DateTime(now.year, now.month, now.day, 0, 17);

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
