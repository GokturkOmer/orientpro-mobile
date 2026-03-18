import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

/// Uygulama baslatildiginda gosterilen splash ekrani.
/// Kaydedilmis token varsa otomatik giris yapar, yoksa login ekranina yonlendirir.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final success = await ref.read(authProvider.notifier).tryAutoLogin();
    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/module-selection');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScadaColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: ScadaColors.cyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.precision_manufacturing, size: 40, color: ScadaColors.cyan),
            ),
            const SizedBox(height: 20),
            const Text('OrientPro', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ScadaColors.cyan, letterSpacing: 2)),
            const SizedBox(height: 24),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.cyan)),
          ],
        ),
      ),
    );
  }
}
