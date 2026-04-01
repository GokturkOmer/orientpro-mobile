import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../core/theme/app_theme.dart';

/// Reusable bildirim bell icon — unread badge ile.
/// Herhangi bir AppBar actions listesine eklenebilir.
class NotifBell extends ConsumerWidget {
  const NotifBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).whenOrNull(data: (d) => d) ?? 0;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 22, color: ScadaColors.amber),
          tooltip: 'Bildirimler',
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ScadaColors.red,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: ScadaColors.red.withValues(alpha: 0.5), blurRadius: 4)],
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}
