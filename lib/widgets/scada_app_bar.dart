import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// OrientPro standart AppBar — tum ekranlarda tutarli gorunum
class ScadaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData titleIcon;
  final Color titleIconColor;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const ScadaAppBar({
    super.key,
    required this.title,
    required this.titleIcon,
    this.titleIconColor = ScadaColors.cyan,
    this.actions,
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.scada.surface,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      title: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: titleIconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(titleIcon, color: titleIconColor, size: 20),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
