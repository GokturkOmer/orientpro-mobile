import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/training_provider.dart';
import '../../core/theme/app_theme.dart';

class TrainingRoutesScreen extends ConsumerStatefulWidget {
  const TrainingRoutesScreen({super.key});

  @override
  ConsumerState<TrainingRoutesScreen> createState() => _TrainingRoutesScreenState();
}

class _TrainingRoutesScreenState extends ConsumerState<TrainingRoutesScreen> {
  String? _departmentId;
  String? _departmentName;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _departmentId = args?['departmentId'];
      _departmentName = args?['departmentName'];
      Future.microtask(() {
        ref.read(trainingProvider.notifier).loadRoutes(departmentId: _departmentId);
      });
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final training = ref.watch(trainingProvider);
    final isLoading = training.isLoading && training.routes.isEmpty;

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _departmentName ?? 'Egitim Rotalari',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : training.routes.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.route, size: 48, color: ScadaColors.textDim),
                    const SizedBox(height: 12),
                    const Text('Henuz egitim rotasi bulunmuyor', style: TextStyle(color: ScadaColors.textSecondary, fontSize: 13)),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: training.routes.length,
                  itemBuilder: (context, index) {
                    final route = training.routes[index];
                    return _buildRouteCard(route);
                  },
                ),
    );
  }

  Widget _buildRouteCard(route) {
    final difficultyColor = route.difficulty == 'beginner'
        ? ScadaColors.green
        : route.difficulty == 'intermediate'
            ? ScadaColors.amber
            : ScadaColors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.pushNamed(context, '/route-detail', arguments: route.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(route.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
              ),
              if (route.isMandatory)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ScadaColors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Zorunlu', style: TextStyle(fontSize: 9, color: ScadaColors.red, fontWeight: FontWeight.w600)),
                ),
            ]),
            if (route.description != null) ...[
              const SizedBox(height: 6),
              Text(route.description!, style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(route.difficultyText, style: TextStyle(fontSize: 9, color: difficultyColor, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.timer_outlined, size: 12, color: ScadaColors.textDim),
              const SizedBox(width: 3),
              Text('${route.estimatedMinutes} dk', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
              const SizedBox(width: 8),
              Icon(Icons.check_circle_outline, size: 12, color: ScadaColors.textDim),
              const SizedBox(width: 3),
              Text('Gecme: %${route.passingScore}', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 12, color: ScadaColors.textDim),
            ]),
          ]),
        ),
      ),
    );
  }
}
