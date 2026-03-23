import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/training.dart';

/// Displays an individual module card with type icon, title, meta info.
/// Used inside RouteDetailWidget and ContentManagerScreen.
class ModuleCardWidget extends StatelessWidget {
  final TrainingModule module;
  final VoidCallback? onTap;

  const ModuleCardWidget({
    super.key,
    required this.module,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = _moduleTypeColor(module.moduleType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.scada.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(_moduleTypeIcon(module.moduleType), size: 16, color: typeColor),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary),
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(module.typeText, style: TextStyle(fontSize: 9, color: typeColor, fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.timer_outlined, size: 11, color: context.scada.textDim),
                        SizedBox(width: 3),
                        Text('${module.estimatedMinutes} dk', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
                        if (module.quizzes != null && module.quizzes!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.quiz, size: 11, color: ScadaColors.amber),
                          SizedBox(width: 3),
                          Text('${module.quizzes!.length} quiz', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 12, color: context.scada.textDim),
            ],
          ),
        ),
      ),
    );
  }

  static Color _moduleTypeColor(String type) {
    switch (type) {
      case 'lesson':
        return ScadaColors.cyan;
      case 'video':
        return ScadaColors.purple;
      case 'practice':
        return ScadaColors.green;
      case 'assessment':
        return ScadaColors.amber;
      default:
        return ScadaColors.textSecondary;
    }
  }

  static IconData _moduleTypeIcon(String type) {
    switch (type) {
      case 'lesson':
        return Icons.menu_book;
      case 'video':
        return Icons.play_circle_outline;
      case 'practice':
        return Icons.build_outlined;
      case 'assessment':
        return Icons.assignment;
      default:
        return Icons.article;
    }
  }
}
