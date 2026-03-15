import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tour.dart';
import '../../providers/tour_provider.dart';
import '../../core/theme/app_theme.dart';

class TourDetailScreen extends ConsumerStatefulWidget {
  final int routeId;
  const TourDetailScreen({super.key, required this.routeId});
  @override
  ConsumerState<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends ConsumerState<TourDetailScreen> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(tourRouteDetailProvider(widget.routeId));

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(backgroundColor: ScadaColors.surface, title: const Text('Tur Detayi', style: TextStyle(fontSize: 15))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.smart_toy, color: Color(0xFF0a0e1a)),
        tooltip: 'AI Asistan',
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: ScadaColors.cyan)),
        error: (e, _) => Center(child: Text('Hata: $e', style: const TextStyle(color: ScadaColors.red))),
        data: (data) {
          final checkpoints = (data['checkpoints'] as List).map((e) => TourCheckpoint.fromJson(e)).toList();
          final photoCount = checkpoints.where((c) => c.photoRequired).length;

          return Column(children: [
            // Route info header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ScadaColors.surface,
                border: Border(bottom: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.3))),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data['name'] ?? '', style: const TextStyle(color: ScadaColors.cyan, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                if (data['description'] != null)
                  Text(data['description'], style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 12),
                Row(children: [
                  _infoBadge(Icons.pin_drop, '${checkpoints.length} nokta', ScadaColors.cyan),
                  const SizedBox(width: 10),
                  _infoBadge(Icons.timer, '~${data['estimated_minutes']} dk', ScadaColors.amber),
                  if (photoCount > 0) ...[
                    const SizedBox(width: 10),
                    _infoBadge(Icons.camera_alt, '$photoCount foto', ScadaColors.purple),
                  ],
                ]),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Icon(Icons.checklist, size: 14, color: ScadaColors.textDim),
                const SizedBox(width: 6),
                const Text('KONTROL NOKTALARI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: checkpoints.length,
                itemBuilder: (ctx, i) {
                  final cp = checkpoints[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Column(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: ScadaColors.cyan.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: Center(child: Text('${cp.orderIndex}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ScadaColors.cyan))),
                        ),
                        if (i < checkpoints.length - 1)
                          Container(width: 2, height: 40, color: ScadaColors.border),
                      ]),
                      const SizedBox(width: 10),
                      Expanded(child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: ScadaColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ScadaColors.border),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(cp.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary))),
                            if (cp.photoRequired) Icon(Icons.camera_alt, size: 13, color: ScadaColors.amber.withValues(alpha: 0.7)),
                          ]),
                          if (cp.location != null) ...[
                            const SizedBox(height: 2),
                            Text(cp.location!, style: const TextStyle(fontSize: 10, color: ScadaColors.textDim)),
                          ],
                          if (cp.checkItems.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ...cp.checkItems.take(2).map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(children: [
                                Icon(Icons.check_box_outline_blank, size: 11, color: ScadaColors.textDim),
                                const SizedBox(width: 4),
                                Expanded(child: Text(item, style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary))),
                              ]),
                            )),
                            if (cp.checkItems.length > 2)
                              Text('+${cp.checkItems.length - 2} daha...', style: const TextStyle(fontSize: 9, color: ScadaColors.textDim)),
                          ],
                        ]),
                      )),
                    ]),
                  );
                },
              ),
            ),

            // Start button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ScadaColors.surface,
                border: Border(top: BorderSide(color: ScadaColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isStarting ? null : _startTour,
                  icon: _isStarting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.cyan))
                    : const Icon(Icons.play_arrow),
                  label: Text(_isStarting ? 'Baslatiliyor...' : 'Turu Baslat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.cyan.withValues(alpha: 0.15),
                    foregroundColor: ScadaColors.cyan,
                    side: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _startTour() async {
    setState(() => _isStarting = true);
    try {
      final session = await TourService.startSession(widget.routeId, 'c0a8f1d9-b501-4f38-84be-5cf4aab47cda');
      if (mounted) Navigator.pushReplacementNamed(context, '/active-tour', arguments: session.id);
    } catch (e) {
      setState(() => _isStarting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: ScadaColors.red));
    }
  }
}
