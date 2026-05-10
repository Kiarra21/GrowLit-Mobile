import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  HistoryService._();

  static final HistoryService instance = HistoryService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _lastSavedDateKey = 'history_last_saved_date';

  /// Menyimpan data status terkini ke koleksi history
  /// Fungsi ini membaca dari 'status/terkini' dan menyimpannya ke 'history'
  Future<void> saveDailyHistory() async {
    try {
      if (kDebugMode) {
        debugPrint('[HistoryService] Mulai menyimpan history harian...');
      }

      // 1. Ambil data status terkini
      final statusRef = _firestore.collection('status').doc('terkini');
      final statusDoc = await statusRef.get();

      if (!statusDoc.exists) {
        if (kDebugMode) {
          debugPrint(
            '[HistoryService] Dokumen "status/terkini" tidak ditemukan.',
          );
        }
        return;
      }

      final latestStatus = statusDoc.data();
      if (kDebugMode) {
        debugPrint(
          '[HistoryService] Data terkini berhasil dibaca: $latestStatus',
        );
      }

      // 2. Buat data history dengan timestamp server
      final historyData = {
        ...?latestStatus,
        'recordedAt': FieldValue.serverTimestamp(),
      };

      // 3. Simpan ke koleksi 'history'
      final historyRef = await _firestore
          .collection('history')
          .add(historyData);

      if (kDebugMode) {
        debugPrint(
          '[HistoryService] Data berhasil disimpan ke history dengan ID: ${historyRef.id}',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSavedDateKey, _dateKey(DateTime.now()));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[HistoryService] Error: $error');
      }
      rethrow;
    }
  }

  Future<void> saveDailyHistoryIfDue() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final lastSavedDate = prefs.getString(_lastSavedDateKey);
    final todayKey = _dateKey(now);

    if (lastSavedDate == todayKey) {
      return;
    }

    if (now.isBefore(DateTime(now.year, now.month, now.day, 23, 59))) {
      return;
    }

    await saveDailyHistory();
  }

  String _dateKey(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }
}
