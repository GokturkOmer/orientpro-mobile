import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tour_provider.dart';
import '../../core/theme/app_theme.dart';

class TourListScreen extends ConsumerWidget {
  const TourListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(tourRoutesProvider);

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: ScadaColors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.qr_code_scanner, color: ScadaColors.green, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('QR Tur Sistemi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.smart_toy, color: Color(0xFF0a0e1a)),
        tooltip: 'AI Asistan',
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: ScadaColors.cyan)),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error, size: 48, color: ScadaColors.red),
          const SizedBox(height: 8),
          Text('Hata: $e', textAlign: TextAlign.center, style: const TextStyle(color: ScadaColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ref.invalidate(tourRoutesProvider), child: const Text('Tekrar Dene')),
        ])),
        data: (routes) {
          if (routes.isEmpty) {
            return const Center(child: Text('Henuz tur rotasi tanimlanmamis', style: TextStyle(color: ScadaColors.textDim)));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              // Stats bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: ScadaColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ScadaColors.border),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _statBadge('${routes.length}', 'Rota', ScadaColors.cyan),
                  Container(width: 1, height: 30, color: ScadaColors.border),
                  _statBadge('${routes.fold<int>(0, (s, r) => s + r.checkpointCount)}', 'Nokta', ScadaColors.green),
                  Container(width: 1, height: 30, color: ScadaColors.border),
                  _statBadge('${routes.fold<int>(0, (s, r) => s + r.estimatedMinutes)}', 'Dakika', ScadaColors.amber),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Icon(Icons.route, size: 14, color: ScadaColors.textDim),
                const SizedBox(width: 6),
                const Text('AKTIF ROTALAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
              ]),
              const SizedBox(height: 10),
              ...routes.map((route) => _routeCard(context, route)),
            ],
          );
        },
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
    ]);
  }

  Widget _routeCard(BuildContext context, dynamic route) {
    IconData deptIcon;
    Color deptColor;
    switch (route.department) {
      case 'Elektrik':
        deptIcon = Icons.bolt;
        deptColor = ScadaColors.amber;
        break;
      default:
        deptIcon = Icons.build;
        deptColor = ScadaColors.cyan;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.pushNamed(context, '/tour-detail', arguments: route.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: deptColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(deptIcon, color: deptColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(route.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.pin_drop, size: 12, color: ScadaColors.textDim),
                const SizedBox(width: 3),
                Text('${route.checkpointCount} nokta', style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                const SizedBox(width: 12),
                Icon(Icons.timer, size: 12, color: ScadaColors.textDim),
                const SizedBox(width: 3),
                Text('~${route.estimatedMinutes} dk', style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: deptColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text(route.department ?? '', style: TextStyle(fontSize: 9, color: deptColor, fontWeight: FontWeight.w600)),
                ),
              ]),
            ])),
            Icon(Icons.chevron_right, color: ScadaColors.textDim, size: 18),
          ]),
        ),
      ),
    );
  }
}
