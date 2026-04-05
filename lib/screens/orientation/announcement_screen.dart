import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/training_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/announcement.dart';
import '../../core/auth/role_helper.dart';
import '../../core/utils/status_helper.dart';
import '../../core/utils/turkish_string.dart';

class AnnouncementScreen extends ConsumerStatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  ConsumerState<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends ConsumerState<AnnouncementScreen> {
  String _searchQuery = '';
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.user != null) {
        ref.read(announcementProvider.notifier).loadAnnouncements(auth.user!.id, department: auth.user!.department);
        ref.read(announcementProvider.notifier).loadUnreadCount(auth.user!.id, department: auth.user!.department);
        ref.read(trainingProvider.notifier).loadDepartments();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final auth = ref.read(authProvider);
      if (auth.user != null) {
        ref.read(announcementProvider.notifier).loadMoreAnnouncements(auth.user!.id, department: auth.user!.department);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final annState = ref.watch(announcementProvider);
    final auth = ref.watch(authProvider);
    final isAdmin = RoleHelper.isAdmin(auth.user?.role);

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
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
          Text('Duyuru Panosu', style: TextStyle(color: context.scada.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                  Icon(Icons.campaign_outlined, size: 48, color: context.scada.textDim),
                  const SizedBox(height: 12),
                  Text('Henuz duyuru yok', style: TextStyle(color: context.scada.textSecondary, fontSize: 13)),
                ]))
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Duyuru ara...',
                        hintStyle: TextStyle(color: context.scada.textDim, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: context.scada.textDim, size: 20),
                        filled: true,
                        fillColor: context.scada.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.scada.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.scada.border)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: TextStyle(color: context.scada.textPrimary, fontSize: 13),
                      onChanged: (v) => setState(() => _searchQuery = v.toTurkishLowerCase()),
                    ),
                  ),
                  Expanded(
                    child: Builder(builder: (_) {
                      final filtered = _searchQuery.isEmpty
                          ? annState.announcements
                          : annState.announcements.where((a) =>
                              a.title.toTurkishLowerCase().contains(_searchQuery) ||
                              a.body.toTurkishLowerCase().contains(_searchQuery) ||
                              (a.targetDepartment?.toTurkishLowerCase().contains(_searchQuery) ?? false)
                            ).toList();
                      if (filtered.isEmpty) {
                        return Center(child: Text('Sonuç bulunamadi', style: TextStyle(color: context.scada.textDim, fontSize: 13)));
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: filtered.length + (annState.isLoadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= filtered.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: ScadaColors.amber, strokeWidth: 2)));
                          }
                          return _buildAnnouncementCard(filtered[i], isAdmin);
                        },
                      );
                    }),
                  ),
                ]),
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
    final priorityColor = StatusHelper.priorityColor(ann.priority);
    final isRead = ann.isRead ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? context.scada.card : context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRead ? context.scada.border : priorityColor.withValues(alpha: 0.5),
          width: isRead ? 1 : 1.5,
        ),
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
            Text(ann.timeAgo, style: TextStyle(color: context.scada.textDim, fontSize: 11)),
            // Admin menu
            if (isAdmin) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: context.scada.textDim),
                color: context.scada.surface,
                padding: EdgeInsets.zero,
                onSelected: (val) {
                  if (val == 'edit') _showEditDialog(context, ann);
                  if (val == 'delete') _confirmDelete(ann);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [
                    Icon(Icons.edit, size: 16, color: ScadaColors.cyan),
                    SizedBox(width: 8),
                    Text('Düzenle', style: TextStyle(fontSize: 12)),
                  ])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [
                    Icon(Icons.delete, size: 16, color: ScadaColors.red),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(fontSize: 12, color: ScadaColors.red)),
                  ])),
                ],
              ),
            ],
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (!isRead) ...[
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(ann.title, style: TextStyle(
                  color: isRead ? context.scada.textSecondary : context.scada.textPrimary,
                  fontSize: 15,
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                )),
              ),
            ]),
            const SizedBox(height: 6),
            Text(ann.body, style: TextStyle(color: context.scada.textSecondary, fontSize: 13, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
          ]),
        ),
        // Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: context.scada.border))),
          child: Row(children: [
            if (isAdmin && ann.readCount != null) ...[
              Icon(Icons.visibility, color: context.scada.textDim, size: 14),
              const SizedBox(width: 4),
              Text('${ann.readCount} kisi okudu', style: TextStyle(color: context.scada.textDim, fontSize: 11)),
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

  Future<void> _markAsRead(Announcement ann) async {
    final ok = await ref.read(announcementProvider.notifier).markAsRead(ann.id);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duyuru okundu olarak isaretlendi'), backgroundColor: ScadaColors.green),
      );
    }
  }

  void _confirmDelete(Announcement ann) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.scada.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.scada.borderBright),
        ),
        title: Text('Duyuru Sil', style: TextStyle(color: context.scada.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('"${ann.title}" silinsin mi?', style: TextStyle(color: context.scada.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Iptal', style: TextStyle(color: context.scada.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ref.read(announcementProvider.notifier).deleteAnnouncement(ann.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Duyuru silindi' : 'Silme başarısız'),
                    backgroundColor: ok ? ScadaColors.green : ScadaColors.red,
                  ),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: ScadaColors.red)),
          ),
        ],
      ),
    );
  }

  /// Birlestirilmis duyuru dialog — existing != null ise edit, null ise create
  void _showAnnouncementDialog(BuildContext context, {Announcement? existing}) {
    final isEdit = existing != null;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final bodyController = TextEditingController(text: existing?.body ?? '');
    String priority = existing?.priority ?? 'normal';
    bool isPinned = existing?.isPinned ?? false;
    String? targetDepartment = existing?.targetDepartment;

    final departments = ref.read(trainingProvider).departments;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.scada.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.scada.borderBright),
          ),
          title: Row(children: [
            Icon(isEdit ? Icons.edit : Icons.campaign, color: isEdit ? ScadaColors.cyan : ScadaColors.amber, size: 18),
            const SizedBox(width: 8),
            Text(isEdit ? 'Duyuru Düzenle' : 'Yeni Duyuru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
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
                decoration: const InputDecoration(labelText: 'İçerik'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Oncelik'),
                dropdownColor: context.scada.surface,
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'high', child: Text('Yuksek')),
                  DropdownMenuItem(value: 'critical', child: Text('Kritik')),
                ],
                onChanged: (v) => setDialogState(() => priority = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: targetDepartment,
                decoration: const InputDecoration(labelText: 'Hedef Departman'),
                dropdownColor: context.scada.surface,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tum Sirket')),
                  ...departments.map((d) => DropdownMenuItem(value: d.name, child: Text(d.name))),
                ],
                onChanged: (v) => setDialogState(() => targetDepartment = v),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Iptal', style: TextStyle(color: context.scada.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || bodyController.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Baslik ve içerik zorunlu'), backgroundColor: ScadaColors.red),
                  );
                  return;
                }
                Navigator.pop(ctx);
                bool ok;
                if (isEdit) {
                  ok = await ref.read(announcementProvider.notifier).updateAnnouncement(existing.id, {
                    'title': titleController.text,
                    'body': bodyController.text,
                    'priority': priority,
                    'is_pinned': isPinned,
                    'target_department': targetDepartment,
                  });
                } else {
                  final auth = ref.read(authProvider);
                  ok = await ref.read(announcementProvider.notifier).createAnnouncement(
                    title: titleController.text,
                    body: bodyController.text,
                    createdBy: auth.user!.id,
                    priority: priority,
                    isPinned: isPinned,
                    targetDepartment: targetDepartment,
                  );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? (isEdit ? 'Duyuru güncellendi' : 'Duyuru oluşturuldu')
                          : (isEdit ? 'Güncelleme başarısız' : 'Duyuru oluşturulamadı')),
                      backgroundColor: ok ? ScadaColors.green : ScadaColors.red,
                    ),
                  );
                }
              },
              child: Text(isEdit ? 'Kaydet' : 'Yayinla'),
            ),
          ],
        ),
      ),
    );
  }

  // Eski metodlari yeni birlestirilen metoda yonlendir
  void _showEditDialog(BuildContext context, Announcement ann) => _showAnnouncementDialog(context, existing: ann);
  void _showCreateDialog(BuildContext context) => _showAnnouncementDialog(context);
}
