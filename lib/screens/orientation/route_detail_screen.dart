import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/training_provider.dart';
import '../../core/theme/app_theme.dart';

class RouteDetailScreen extends ConsumerStatefulWidget {
  const RouteDetailScreen({super.key});

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final routeId = ModalRoute.of(context)?.settings.arguments as String?;
      if (routeId != null) {
        Future.microtask(() {
          ref.read(trainingProvider.notifier).loadRouteDetail(routeId);
        });
      }
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final training = ref.watch(trainingProvider);
    final route = training.selectedRoute;

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          route?.title ?? 'Rota Detayi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.scada.textPrimary),
        ),
      ),
      body: training.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : route == null
              ? Center(child: Text('Rota bulunamadi', style: TextStyle(color: context.scada.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  children: [
                    // Route info card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.scada.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.scada.border),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (route.departmentName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(route.departmentName!, style: const TextStyle(fontSize: 11, color: ScadaColors.purple, fontWeight: FontWeight.w600)),
                          ),
                        Text(route.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
                        if (route.description != null) ...[
                          const SizedBox(height: 6),
                          Text(route.description!, style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
                        ],
                        const SizedBox(height: 12),
                        Row(children: [
                          _infoChip(Icons.timer, '${route.estimatedMinutes} dk', ScadaColors.cyan),
                          const SizedBox(width: 8),
                          _infoChip(Icons.speed, route.difficultyText, ScadaColors.amber),
                          const SizedBox(width: 8),
                          _infoChip(Icons.check, 'Gecme: %${route.passingScore}', ScadaColors.green),
                        ]),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    // Modules header
                    Row(children: [
                      Icon(Icons.menu_book, size: 14, color: context.scada.textDim),
                      const SizedBox(width: 6),
                      Text('MODULLER (${route.modules?.length ?? 0})', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.scada.textSecondary, letterSpacing: 1)),
                    ]),
                    const SizedBox(height: 12),

                    // Module timeline (siralama: ilk modül acik, sonrakiler icin oncekini tamamla)
                    if (route.modules != null && route.modules!.isNotEmpty)
                      ...route.modules!.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final module = entry.value;
                        final isLast = idx == route.modules!.length - 1;
                        // Ilk modül her zaman acik, sonrakiler onceki modullere bagli
                        final isLocked = idx > 0; // Gercek tamamlanma durumu backend'den gelmeli
                        return _buildTimelineItem(idx + 1, module, isLast, isLocked: isLocked);
                      })
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.menu_book, size: 40, color: context.scada.textDim),
                            const SizedBox(height: 8),
                            Text('Henuz modül eklenmemis', style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
                          ]),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildTimelineItem(int index, dynamic module, bool isLast, {bool isLocked = false}) {
    // Modül durumunu belirle: tamamlanan içerikleri kontrol et
    final contents = module.contents as List? ?? [];
    final quizzes = module.quizzes as List? ?? [];
    final totalItems = contents.length + quizzes.length;

    // Basit durum tahmini: içerik ve quiz varsa
    // Gercek tamamlanma durumu backend'den gelmeli, simdilik index bazli gösterim
    _ModuleStatus status = _ModuleStatus.notStarted;
    if (totalItems == 0) {
      status = _ModuleStatus.notStarted;
    }

    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    switch (status) {
      case _ModuleStatus.completed:
        statusColor = ScadaColors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Tamamlandi';
      case _ModuleStatus.inProgress:
        statusColor = ScadaColors.orange;
        statusIcon = Icons.play_circle;
        statusText = 'Devam Ediyor';
      case _ModuleStatus.notStarted:
        statusColor = context.scada.textDim;
        statusIcon = Icons.radio_button_unchecked;
        statusText = 'Baslanmadi';
    }

    final typeIcon = module.moduleType == 'video'
        ? Icons.play_circle_fill
        : module.moduleType == 'practice'
            ? Icons.build
            : module.moduleType == 'assessment'
                ? Icons.assignment
                : Icons.menu_book;

    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Timeline sol kismi — nokta ve cizgi
        SizedBox(
          width: 40,
          child: Column(children: [
            // Durum noktasi
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Center(child: Icon(statusIcon, size: 14, color: statusColor)),
            ),
            // Dikey cizgi (son eleman degilse)
            if (!isLast)
              Expanded(
                child: Container(
                  width: 2,
                  color: context.scada.border,
                ),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        // Modül karti
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.scada.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: InkWell(
              onTap: isLocked
                  ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Onceki modülü tamamlayin: Modül ${index - 1}'),
                      backgroundColor: ScadaColors.orange,
                      duration: const Duration(seconds: 2),
                    ))
                  : () => Navigator.pushNamed(context, '/module-detail', arguments: module.id),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: ScadaColors.cyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Text('$index', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ScadaColors.cyan))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(module.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary))),
                    Icon(Icons.arrow_forward_ios, size: 12, color: context.scada.textDim),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(typeIcon, size: 11, color: context.scada.textDim),
                    const SizedBox(width: 3),
                    Text(module.typeText, style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
                    const SizedBox(width: 10),
                    Icon(Icons.timer_outlined, size: 11, color: context.scada.textDim),
                    const SizedBox(width: 3),
                    Text('${module.estimatedMinutes} dk', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
                    const Spacer(),
                    if (isLocked)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.lock, size: 11, color: context.scada.textDim),
                        const SizedBox(width: 3),
                        Text('Kilitli', style: TextStyle(fontSize: 9, color: context.scada.textDim, fontWeight: FontWeight.w500)),
                      ])
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(statusText, style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.w500)),
                      ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ]),
    ));
  }
}

enum _ModuleStatus { completed, inProgress, notStarted }

