import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/announcement.dart';
import '../../core/auth/role_helper.dart';

class AnnouncementScreen extends ConsumerStatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  ConsumerState<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends ConsumerState<AnnouncementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.user != null) {
        ref.read(announcementProvider.notifier).loadAnnouncements(auth.user!.id, department: auth.user!.department);
        ref.read(announcementProvider.notifier).loadUnreadCount(auth.user!.id, department: auth.user!.department);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final annState = ref.watch(announcementProvider);
    final auth = ref.watch(authProvider);
    final isAdmin = RoleHelper.isAdmin(auth.user?.role);

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ScadaColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.campaign, color: ScadaColors.amber, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('Duyuru Panosu', style: TextStyle(color: ScadaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          if (annState.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: ScadaColors.red, borderRadius: BorderRadius.circular(10)),
              child: Text('${annState.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
      ),
      body: annState.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.amber))
          : annState.announcements.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.campaign_outlined, size: 48, color: ScadaColors.textDim),
                  const SizedBox(height: 12),
                  const Text('Henuz duyuru yok', style: TextStyle(color: ScadaColors.textSecondary, fontSize: 13)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: annState.announcements.length,
                  itemBuilder: (_, i) => _buildAnnouncementCard(annState.announcements[i], isAdmin),
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Duyuru'),
            )
          : null,
    );
  }

  Widget _buildAnnouncementCard(Announcement ann, bool isAdmin) {
    final priorityColor = _priorityColor(ann.priority);
    final isRead = ann.isRead ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isRead ? ScadaColors.border : priorityColor.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(children: [
            if (ann.isPinned) ...[
              Icon(Icons.push_pin, color: priorityColor, size: 14),
              const SizedBox(width: 4),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(ann.priorityText, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            if (ann.targetDepartment != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ScadaColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(ann.targetDepartment!, style: const TextStyle(color: ScadaColors.purple, fontSize: 10)),
              ),
            ],
            const Spacer(),
            Text(ann.timeAgo, style: const TextStyle(color: ScadaColors.textDim, fontSize: 11)),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ann.title, style: const TextStyle(
              color: ScadaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 6),
            Text(ann.body, style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 13, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
          ]),
        ),
        // Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: ScadaColors.border))),
          child: Row(children: [
            if (isAdmin && ann.readCount != null) ...[
              const Icon(Icons.visibility, color: ScadaColors.textDim, size: 14),
              const SizedBox(width: 4),
              Text('${ann.readCount} kisi okudu', style: const TextStyle(color: ScadaColors.textDim, fontSize: 11)),
            ],
            const Spacer(),
            if (!isRead)
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Okudum', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScadaColors.green.withValues(alpha: 0.15),
                  foregroundColor: ScadaColors.green,
                  side: BorderSide(color: ScadaColors.green.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () => _markAsRead(ann),
              )
            else
              Row(children: [
                const Icon(Icons.check_circle, color: ScadaColors.green, size: 16),
                const SizedBox(width: 4),
                const Text('Okundu', style: TextStyle(color: ScadaColors.green, fontSize: 12)),
              ]),
          ]),
        ),
      ]),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'critical': return ScadaColors.red;
      case 'high': return ScadaColors.amber;
      default: return ScadaColors.green;
    }
  }

  Future<void> _markAsRead(Announcement ann) async {
    final auth = ref.read(authProvider);
    final ok = await ref.read(announcementProvider.notifier).markAsRead(ann.id, auth.user!.id);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duyuru okundu olarak isaretlendi'), backgroundColor: ScadaColors.green),
      );
    }
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String priority = 'normal';
    bool isPinned = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ScadaColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ScadaColors.borderBright),
          ),
          title: const Row(children: [
            Icon(Icons.campaign, color: ScadaColors.amber, size: 18),
            SizedBox(width: 8),
            Text('Yeni Duyuru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Baslik'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Icerik'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Oncelik'),
                dropdownColor: ScadaColors.surface,
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'high', child: Text('Yuksek')),
                  DropdownMenuItem(value: 'critical', child: Text('Kritik')),
                ],
                onChanged: (v) => setDialogState(() => priority = v!),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Sabitle', style: TextStyle(fontSize: 14)),
                value: isPinned,
                activeThumbColor: ScadaColors.cyan,
                onChanged: (v) => setDialogState(() => isPinned = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal', style: TextStyle(color: ScadaColors.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || bodyController.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Baslik ve icerik zorunlu'), backgroundColor: ScadaColors.red),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final auth = ref.read(authProvider);
                final ok = await ref.read(announcementProvider.notifier).createAnnouncement(
                  title: titleController.text,
                  body: bodyController.text,
                  createdBy: auth.user!.id,
                  priority: priority,
                  isPinned: isPinned,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Duyuru olusturuldu' : 'Duyuru olusturulamadi'),
                      backgroundColor: ok ? ScadaColors.green : ScadaColors.red,
                    ),
                  );
                }
              },
              child: const Text('Yayinla'),
            ),
          ],
        ),
      ),
    );
  }
}
