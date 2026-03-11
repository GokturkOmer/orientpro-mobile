import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController(text: 'admin@orientpro.com');
  final _passwordController = TextEditingController(text: 'OrientPro2026!');
  bool _obscure = true;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    final success = await ref.read(authProvider.notifier).login(
      _emailController.text,
      _passwordController.text,
    );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/module-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: ScadaColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with glow
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: ScadaColors.cyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: ScadaColors.cyan.withOpacity(0.3 + _pulseCtrl.value * 0.2)),
                    boxShadow: [BoxShadow(color: ScadaColors.cyan.withOpacity(_pulseCtrl.value * 0.15), blurRadius: 24)],
                  ),
                  child: const Icon(Icons.precision_manufacturing, size: 40, color: ScadaColors.cyan),
                ),
              ),
              const SizedBox(height: 20),
              const Text('OrientPro', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ScadaColors.cyan, letterSpacing: 2)),
              const SizedBox(height: 4),
              const Text('SCADA & Tesis Yonetim Sistemi', style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary, letterSpacing: 1)),
              const SizedBox(height: 8),
              // Version badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: ScadaColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ScadaColors.border),
                ),
                child: const Text('v2.0', style: TextStyle(fontSize: 10, color: ScadaColors.textDim, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 40),

              // Login card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ScadaColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ScadaColors.border),
                ),
                child: Column(children: [
                  Row(children: [
                    Icon(Icons.login, size: 14, color: ScadaColors.textDim),
                    const SizedBox(width: 6),
                    const Text('SISTEM GIRISI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ScadaColors.textSecondary, letterSpacing: 1)),
                  ]),
                  const SizedBox(height: 16),

                  // Email field
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      labelStyle: const TextStyle(color: ScadaColors.textDim, fontSize: 13),
                      prefixIcon: const Icon(Icons.email_outlined, size: 18, color: ScadaColors.textDim),
                      filled: true,
                      fillColor: ScadaColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ScadaColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ScadaColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.cyan.withOpacity(0.5))),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // Password field
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Sifre',
                      labelStyle: const TextStyle(color: ScadaColors.textDim, fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline, size: 18, color: ScadaColors.textDim),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18, color: ScadaColors.textDim),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      filled: true,
                      fillColor: ScadaColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ScadaColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ScadaColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.cyan.withOpacity(0.5))),
                    ),
                    obscureText: _obscure,
                  ),
                  const SizedBox(height: 8),

                  if (auth.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: ScadaColors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ScadaColors.red.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, size: 14, color: ScadaColors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(auth.error!, style: const TextStyle(color: ScadaColors.red, fontSize: 12))),
                      ]),
                    ),
                  const SizedBox(height: 16),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScadaColors.cyan.withOpacity(0.15),
                        foregroundColor: ScadaColors.cyan,
                        side: BorderSide(color: ScadaColors.cyan.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: auth.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.cyan))
                        : const Text('Giris Yap', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 24),
              // Footer
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: ScadaColors.green.withOpacity(0.6), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('Sistem aktif', style: TextStyle(fontSize: 10, color: ScadaColors.textDim)),
                const SizedBox(width: 16),
                const Text('|', style: TextStyle(color: ScadaColors.textDim, fontSize: 10)),
                const SizedBox(width: 16),
                const Text('v2.0 Beta', style: TextStyle(fontSize: 10, color: ScadaColors.textDim)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
