import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Bolum baslik widget'i — her ekranda tutarli SCADA tarzinda baslik
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: context.scada.textDim),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: context.scada.textSecondary,
            letterSpacing: 1,
          ),
        ),
      ),
      ?trailing,
    ]);
  }
}
