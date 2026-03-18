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
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          route?.title ?? 'Rota Detayi',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary),
        ),
      ),
      body: training.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : route == null
              ? const Center(child: Text('Rota bulunamadi', style: TextStyle(color: ScadaColors.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  children: [
                    // Route info card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ScadaColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ScadaColors.border),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (route.departmentName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(route.departmentName!, style: const TextStyle(fontSize: 11, color: ScadaColors.purple, fontWeight: FontWeight.w600)),
                          ),
                        Text(route.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
                        if (route.description != null) ...[
                          const SizedBox(height: 6),
                          Text(route.description!, style: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary)),
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
                      const Icon(Icons.menu_book, size: 14, color: ScadaColors.textDim),
                      const SizedBox(width: 6),
                      Text('MODULLER (${route.modules?.length ?? 0})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
                    ]),
                    const SizedBox(height: 12),

                    // Module list
                    if (route.modules != null && route.modules!.isNotEmpty)
                      ...route.modules!.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final module = entry.value;
                        return _buildModuleItem(idx + 1, module);
                      })
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.menu_book, size: 40, color: ScadaColors.textDim),
                            const SizedBox(height: 8),
                            const Text('Henuz modul eklenmemis', style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary)),
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

  Widget _buildModuleItem(int index, module) {
    final typeIcon = module.moduleType == 'video'
        ? Icons.play_circle_fill
        : module.moduleType == 'practice'
            ? Icons.build
            : module.moduleType == 'assessment'
                ? Icons.assignment
                : Icons.menu_book;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: ScadaColors.cyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text('$index', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ScadaColors.cyan))),
        ),
        title: Text(module.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
        subtitle: Row(children: [
          Icon(typeIcon, size: 11, color: ScadaColors.textDim),
          const SizedBox(width: 3),
          Text(module.typeText, style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
          const SizedBox(width: 8),
          Icon(Icons.timer_outlined, size: 11, color: ScadaColors.textDim),
          const SizedBox(width: 3),
          Text('${module.estimatedMinutes} dk', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
        ]),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: ScadaColors.textDim),
        onTap: () => Navigator.pushNamed(context, '/module-detail', arguments: module.id),
      ),
    );
  }
}
