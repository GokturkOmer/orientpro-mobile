import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/auth_dio.dart';

class _ApprovalItem {
  final String id;
  final String title;
  final String author;
  final String createdAt;
  final String? type;

  _ApprovalItem({required this.id, required this.title, required this.author, required this.createdAt, this.type});

  factory _ApprovalItem.fromJson(Map<String, dynamic> json) {
    return _ApprovalItem(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Isimsiz Icerik',
      author: json['author_name'] ?? json['author'] ?? 'Bilinmeyen',
      createdAt: json['created_at'] ?? '',
      type: json['content_type'] ?? json['type'],
    );
  }
}

class ContentApprovalScreen extends ConsumerStatefulWidget {
  const ContentApprovalScreen({super.key});

  @override
  ConsumerState<ContentApprovalScreen> createState() => _ContentApprovalScreenState();
}

class _ContentApprovalScreenState extends ConsumerState<ContentApprovalScreen> {
  List<_ApprovalItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingItems();
  }

  Future<void> _loadPendingItems() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = ref.read(authDioProvider);
      final response = await dio.get('/content-approval/pending');
      final data = response.data as List;
      setState(() {
        _items = data.map((d) => _ApprovalItem.fromJson(d)).toList();
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.response?.data?['detail'] ?? 'Veriler yuklenemedi';
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Beklenmeyen hata'; });
    }
  }

  Future<void> _reviewItem(String itemId, String status, {String? notes}) async {
    try {
      final dio = ref.read(authDioProvider);
      await dio.post('/content-approval/$itemId/review', data: {
        'status': status,
        'notes': notes ?? '',
      });
      setState(() {
        _items.removeWhere((item) => item.id == itemId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'approved' ? 'Icerik onaylandi' : 'Icerik reddedildi'),
            backgroundColor: status == 'approved' ? ScadaColors.green : ScadaColors.red,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['detail'] ?? 'Islem basarisiz'),
            backgroundColor: ScadaColors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(String itemId, String title) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.scada.borderBright),
        ),
        title: Text('Icerigi Reddet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"$title" icerigi reddedilecek.', style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
            SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: TextStyle(fontSize: 13, color: context.scada.textPrimary),
              decoration: InputDecoration(
                labelText: 'Red sebebi (opsiyonel)',
                labelStyle: TextStyle(fontSize: 12, color: context.scada.textDim),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Iptal', style: TextStyle(color: context.scada.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reviewItem(itemId, 'rejected', notes: notesController.text.trim());
            },
            child: const Text('Reddet', style: TextStyle(color: ScadaColors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.fact_check, color: ScadaColors.amber, size: 20),
          ),
          SizedBox(width: 8),
          Text('Icerik Onaylari', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
        actions: [
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ScadaColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_items.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ScadaColors.amber)),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.amber))
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.error_outline, size: 48, color: ScadaColors.red.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(fontSize: 12, color: ScadaColors.red)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _loadPendingItems, child: const Text('Tekrar Dene', style: TextStyle(color: ScadaColors.amber))),
                  ]),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle_outline, size: 48, color: ScadaColors.green.withValues(alpha: 0.5)),
                        SizedBox(height: 12),
                        Text('Onay bekleyen icerik yok', style: TextStyle(fontSize: 13, color: context.scada.textSecondary)),
                      ]),
                    )
                  : RefreshIndicator(
                      color: ScadaColors.amber,
                      onRefresh: _loadPendingItems,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: _items.length,
                        itemBuilder: (context, index) => _buildApprovalCard(_items[index]),
                      ),
                    ),
    );
  }

  Widget _buildApprovalCard(_ApprovalItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.scada.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ScadaColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description, color: ScadaColors.amber, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.person_outline, size: 12, color: context.scada.textDim),
                  SizedBox(width: 4),
                  Text(item.author, style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
                  if (item.createdAt.isNotEmpty) ...[
                    SizedBox(width: 12),
                    Icon(Icons.access_time, size: 12, color: context.scada.textDim),
                    SizedBox(width: 4),
                    Text(_formatDate(item.createdAt), style: TextStyle(fontSize: 11, color: context.scada.textDim)),
                  ],
                ]),
              ]),
            ),
          ]),
          if (item.type != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ScadaColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(item.type!, style: const TextStyle(fontSize: 9, color: ScadaColors.cyan)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showRejectDialog(item.id, item.title),
                icon: const Icon(Icons.close, size: 16, color: ScadaColors.red),
                label: const Text('Reddet', style: TextStyle(fontSize: 12, color: ScadaColors.red)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: ScadaColors.red.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _reviewItem(item.id, 'approved'),
                icon: const Icon(Icons.check, size: 16, color: ScadaColors.green),
                label: const Text('Onayla', style: TextStyle(fontSize: 12, color: ScadaColors.green)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: ScadaColors.green.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
