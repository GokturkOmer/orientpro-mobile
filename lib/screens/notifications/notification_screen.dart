import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../core/theme/app_theme.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationProvider.notifier).loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final notifs = state.notifications;

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: ScadaColors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.notifications, color: ScadaColors.amber, size: 18)),
          const SizedBox(width: 8),
          Text('Bildirimler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
            icon: const Icon(Icons.done_all, size: 16, color: ScadaColors.cyan),
            label: const Text('Tumu Okundu', style: TextStyle(fontSize: 11, color: ScadaColors.cyan)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: ScadaColors.cyan,
        tooltip: 'AI Asistan',
        child: Icon(Icons.smart_toy, color: context.scada.bg),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : notifs.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_none, size: 64, color: context.scada.textDim),
                  const SizedBox(height: 12),
                  Text('Bildirim yok', style: TextStyle(color: context.scada.textDim)),
                ]))
              : RefreshIndicator(
                  color: ScadaColors.cyan, backgroundColor: context.scada.surface,
                  onRefresh: () async {
                    await ref.read(notificationProvider.notifier).loadNotifications();
                    await ref.read(notificationProvider.notifier).refreshUnreadCount();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    itemCount: notifs.length,
                    itemBuilder: (ctx, i) => _notifCard(context, ref, notifs[i]),
                  ),
                ),
    );
  }

  Widget _notifCard(BuildContext context, WidgetRef ref, AppNotification notif) {
    Color severityColor;
    switch (notif.severity) {
      case 'critical': severityColor = ScadaColors.red; break;
      case 'warning': severityColor = ScadaColors.amber; break;
      default: severityColor = ScadaColors.cyan;
    }
    IconData categoryIcon;
    switch (notif.category) {
      case 'alarm': categoryIcon = Icons.notifications_active; break;
      case 'maintenance': categoryIcon = Icons.build; break;
      case 'tour': categoryIcon = Icons.qr_code_scanner; break;
      case 'report': categoryIcon = Icons.analytics; break;
      case 'system': categoryIcon = Icons.settings; break;
      case 'training': categoryIcon = Icons.school; break;
      default: categoryIcon = Icons.notifications;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: notif.isRead ? context.scada.card : severityColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: notif.isRead ? context.scada.border : severityColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (!notif.isRead) {
            ref.read(notificationProvider.notifier).markAsRead(notif.id);
          }
          _showDetailSheet(context, ref, notif, severityColor, categoryIcon);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(categoryIcon, color: severityColor, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(notif.title, style: TextStyle(fontSize: 13, fontWeight: notif.isRead ? FontWeight.w400 : FontWeight.w600, color: notif.isRead ? context.scada.textSecondary : context.scada.textPrimary))),
                if (!notif.isRead) Container(width: 8, height: 8, decoration: BoxDecoration(color: severityColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: severityColor.withValues(alpha: 0.5), blurRadius: 4)])),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: context.scada.textDim),
              ]),
              const SizedBox(height: 4),
              Text(notif.message, style: TextStyle(fontSize: 11, color: context.scada.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(_sevLabel(notif.severity), style: TextStyle(fontSize: 8, color: severityColor, fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 10, color: context.scada.textDim),
                const SizedBox(width: 3),
                Text(_timeAgo(notif.createdAt), style: TextStyle(fontSize: 10, color: context.scada.textDim)),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref, AppNotification notif, Color severityColor, IconData categoryIcon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.only(top: 80),
        decoration: BoxDecoration(
          color: context.scada.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: context.scada.borderBright)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4,
            decoration: BoxDecoration(color: context.scada.borderBright, borderRadius: BorderRadius.circular(2))),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.scada.border))),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(categoryIcon, color: severityColor, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(notif.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
                const SizedBox(height: 2),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(_sevLabel(notif.severity), style: TextStyle(fontSize: 9, color: severityColor, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: ScadaColors.cyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(_catLabel(notif.category), style: const TextStyle(fontSize: 9, color: ScadaColors.cyan, fontWeight: FontWeight.w600))),
                ]),
              ])),
            ]),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(notif.message, style: TextStyle(fontSize: 14, color: context.scada.textPrimary, height: 1.5)),
              const SizedBox(height: 16),

              _infoRow(Icons.access_time, 'Zaman', _timeAgo(notif.createdAt)),
              if (notif.source != null) _infoRow(Icons.source, 'Kaynak', notif.source!),
              _infoRow(Icons.category, 'Kategori', _catLabel(notif.category)),
              _infoRow(Icons.flag, 'Oncelik', _sevLabel(notif.severity)),

              const SizedBox(height: 20),

              Row(children: [
                Expanded(child: _actionButton(ctx, notif, severityColor)),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Kapat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.scada.textSecondary,
                    side: BorderSide(color: context.scada.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                )),
              ]),
            ]),
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  Widget _actionButton(BuildContext ctx, AppNotification notif, Color color) {
    String label;
    IconData icon;
    VoidCallback action;

    switch (notif.category) {
      case 'alarm':
        label = 'Alarmlara Git';
        icon = Icons.warning_amber;
        action = () { Navigator.pop(ctx); Navigator.pushNamed(ctx, '/alarms'); };
        break;
      case 'maintenance':
        label = 'Ekipmana Git';
        icon = Icons.build;
        action = () { Navigator.pop(ctx); Navigator.pushNamed(ctx, '/equipment'); };
        break;
      case 'tour':
        label = 'Turlara Git';
        icon = Icons.qr_code_scanner;
        action = () { Navigator.pop(ctx); Navigator.pushNamed(ctx, '/tours'); };
        break;
      case 'report':
        label = 'SCADA Git';
        icon = Icons.monitor_heart;
        action = () { Navigator.pop(ctx); Navigator.pushNamed(ctx, '/scada'); };
        break;
      case 'training':
        label = 'Egitime Git';
        icon = Icons.school;
        action = () { Navigator.pop(ctx); Navigator.pushNamed(ctx, '/orientation-dashboard'); };
        break;
      default:
        label = 'Panele Git';
        icon = Icons.dashboard;
        action = () { Navigator.pop(ctx); Navigator.pushNamed(ctx, '/dashboard'); };
    }

    return ElevatedButton.icon(
      onPressed: action,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: context.scada.textDim),
        const SizedBox(width: 8),
        Text('$label:', style: TextStyle(fontSize: 11, color: context.scada.textDim)),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(fontSize: 11, color: context.scada.textSecondary, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  String _sevLabel(String s) { switch (s) { case 'critical': return 'KRITIK'; case 'warning': return 'UYARI'; default: return 'BILGI'; } }
  String _catLabel(String c) { switch (c) { case 'alarm': return 'ALARM'; case 'maintenance': return 'BAKIM'; case 'tour': return 'TUR'; case 'report': return 'RAPOR'; case 'system': return 'SISTEM'; case 'training': return 'EGITIM'; default: return 'DIGER'; } }
  String _timeAgo(DateTime dt) { final d = DateTime.now().difference(dt); if (d.inMinutes < 1) return 'simdi'; if (d.inMinutes < 60) return '${d.inMinutes} dk once'; if (d.inHours < 24) return '${d.inHours} saat once'; return '${d.inDays} gun once'; }
}
