import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tekrarlayan durum/oncelik renk ve ikon hesaplamalarini merkezlestirir.
class StatusHelper {
  StatusHelper._();

  // ===== ONCELIK RENKLERI =====

  /// Genel oncelik rengi — announcement, shift, work order'da kullanilir.
  /// Kabul edilen degerler: critical/urgent, high, normal, low
  static Color priorityColor(String priority) {
    switch (priority) {
      case 'critical':
      case 'urgent':
        return ScadaColors.red;
      case 'high':
        return ScadaColors.amber;
      case 'normal':
        return ScadaColors.cyan;
      case 'low':
        return ScadaColors.textSecondary;
      default:
        return ScadaColors.green;
    }
  }

  // ===== GENEL DURUM RENKLERI =====

  /// Egitim ilerleme durumu rengi: not_started, in_progress, completed
  static Color trainingStatusColor(String status) {
    switch (status) {
      case 'completed':
        return ScadaColors.green;
      case 'in_progress':
        return ScadaColors.amber;
      default:
        return ScadaColors.textDim;
    }
  }

  /// Egitim ilerleme durumu ikonu
  static IconData trainingStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  /// Vardiya/gorev durumu rengi: pending, in_progress, completed, cancelled
  static Color taskStatusColor(String status) {
    switch (status) {
      case 'pending':
        return ScadaColors.amber;
      case 'in_progress':
        return ScadaColors.cyan;
      case 'completed':
        return ScadaColors.green;
      case 'cancelled':
        return ScadaColors.textDim;
      default:
        return ScadaColors.textSecondary;
    }
  }

  /// Is emri durumu rengi: open, assigned, in_progress, completed
  static Color workOrderStatusColor(String status) {
    switch (status) {
      case 'open':
        return ScadaColors.red;
      case 'assigned':
        return ScadaColors.amber;
      case 'in_progress':
        return ScadaColors.cyan;
      case 'completed':
        return ScadaColors.green;
      default:
        return ScadaColors.textDim;
    }
  }

  /// Is emri durumu ikonu
  static IconData workOrderStatusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.error_outline;
      case 'assigned':
        return Icons.person_add;
      case 'in_progress':
        return Icons.engineering;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  // ===== QUIZ DURUM =====

  /// Quiz sonucu durumunu hesaplar.
  /// [passed] ve [percent] quiz result'tan gelir; null ise cozulmemis.
  static ({String text, Color color, IconData icon}) quizStatus({
    required bool? passed,
    double? percent,
  }) {
    if (passed == null) {
      return (text: 'Cozulmedi', color: ScadaColors.textDim, icon: Icons.radio_button_unchecked);
    }
    if (passed) {
      return (text: 'Gecti (%${percent?.toInt() ?? 0})', color: ScadaColors.green, icon: Icons.check_circle);
    }
    return (text: 'Kaldi (%${percent?.toInt() ?? 0})', color: ScadaColors.red, icon: Icons.cancel);
  }

  // ===== MODUL TIPI IKONU =====

  static IconData moduleTypeIcon(String moduleType) {
    switch (moduleType) {
      case 'video':
        return Icons.play_circle_outline;
      case 'practice':
        return Icons.build;
      case 'assessment':
        return Icons.quiz;
      default:
        return Icons.menu_book;
    }
  }
}
