import 'package:flutter/foundation.dart';

/// Lokal bildirim servisi — mikro-öğrenme kartlari icin.
/// Web'de calismaz, sadece mobil (Android/iOS) icin.
/// FCM entegrasyonu sonraki fazda eklenecek.
class LocalNotificationService {
  static bool _initialized = false;

  /// Servisi baslat
  static Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      _initialized = true;
      return;
    }

    // Mobil platform icin flutter_local_notifications
    // APK build'de aktif edilecek
    try {
      // Dynamic import ile platform-specific kodu yükle
      debugPrint('LocalNotificationService: mobil bildirim hazir');
      _initialized = true;
    } catch (e) {
      debugPrint('LocalNotificationService init hatasi: $e');
    }
  }

  /// Vardiya bazli bildirim saatleri
  static Map<String, List<Map<String, int>>> get shiftSchedules => {
    'A': [
      {'hour': 6, 'minute': 30},
      {'hour': 10, 'minute': 0},
      {'hour': 13, 'minute': 30},
    ],
    'B': [
      {'hour': 14, 'minute': 30},
      {'hour': 18, 'minute': 0},
      {'hour': 21, 'minute': 30},
    ],
    'C': [
      {'hour': 22, 'minute': 30},
      {'hour': 2, 'minute': 0},
      {'hour': 5, 'minute': 30},
    ],
  };

  /// Bildirim zamanla (simdilik backend tarafinda yapiliyor)
  static Future<void> scheduleShiftNotifications({
    required String shiftType,
    required String moduleTitle,
  }) async {
    if (kIsWeb) return;
    debugPrint('Shift $shiftType notifications scheduled for $moduleTitle');
    // Gercek local notification APK build'de aktif edilecek
    // Simdilik backend TrainingReminder tablosu ile bildirimler yonetiliyor
  }

  /// Tum bildirimleri iptal et
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
  }
}
