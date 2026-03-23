import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/training.dart';
import 'module_card_widget.dart';

/// Displays the route detail view: route info card + module list.
/// Used in the right panel of ContentManagerScreen.
class RouteDetailWidget extends ConsumerWidget {
  final TrainingRoute route;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPdfUpload;
  final VoidCallback onAddModule;

  const RouteDetailWidget({
    super.key,
    required this.route,
    required this.onEdit,
    required this.onDelete,
    required this.onPdfUpload,
    required this.onAddModule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficultyColor = route.difficulty == 'beginner'
        ? ScadaColors.green
        : route.difficulty == 'intermediate'
            ? ScadaColors.amber
            : ScadaColors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route info card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ScadaColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ScadaColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        route.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary),
                      ),
                    ),
                    if (route.isMandatory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ScadaColors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Zorunlu', style: TextStyle(fontSize: 10, color: ScadaColors.red, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),

                if (route.description != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    route.description!,
                    style: const TextStyle(fontSize: 13, color: ScadaColors.textSecondary, height: 1.5),
                  ),
                ],

                const SizedBox(height: 14),

                // Meta info
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (route.departmentName != null)
                      _buildMetaChip(Icons.business, route.departmentName!, ScadaColors.purple),
                    _buildMetaChip(Icons.signal_cellular_alt, route.difficultyText, difficultyColor),
                    _buildMetaChip(Icons.timer_outlined, '${route.estimatedMinutes} dk', ScadaColors.cyan),
                    _buildMetaChip(Icons.check_circle_outline, 'Gecme: %${route.passingScore}', ScadaColors.green),
                    if (route.certificateEnabled)
                      _buildMetaChip(Icons.workspace_premium, 'Sertifika', ScadaColors.amber),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Duzenle', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScadaColors.cyan.withValues(alpha: 0.12),
                        foregroundColor: ScadaColors.cyan,
                        side: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 14),
                      label: const Text('Sil', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScadaColors.red.withValues(alpha: 0.12),
                        foregroundColor: ScadaColors.red,
                        side: BorderSide(color: ScadaColors.red.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: onPdfUpload,
                      icon: const Icon(Icons.upload_file, size: 14),
                      label: const Text('PDF Yukle', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScadaColors.red.withValues(alpha: 0.12),
                        foregroundColor: ScadaColors.red,
                        side: BorderSide(color: ScadaColors.red.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onAddModule,
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Modul Ekle', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScadaColors.green.withValues(alpha: 0.12),
                        foregroundColor: ScadaColors.green,
                        side: BorderSide(color: ScadaColors.green.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Modules section
          Row(
            children: [
              const Icon(Icons.view_module, size: 16, color: ScadaColors.cyan),
              const SizedBox(width: 8),
              Text(
                'Moduller (${route.modules?.length ?? 0})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (route.modules == null || route.modules!.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ScadaColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ScadaColors.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined, size: 32, color: ScadaColors.textDim),
                    const SizedBox(height: 8),
                    const Text('Henuz modul eklenmemis', style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            ...route.modules!.map((module) => ModuleCardWidget(
              module: module,
              onTap: () {
                Navigator.pushNamed(context, '/admin/module-editor', arguments: {'routeId': module.routeId, 'moduleId': module.id});
              },
            )),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
