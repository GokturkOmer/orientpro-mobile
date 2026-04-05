import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _orgNameController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _isOrgRegistration = false;
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _orgNameController.dispose();
    super.dispose();
  }

  String? _validateInputs() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return 'Tum alanlari doldurun';
    }
    if (_isOrgRegistration && _orgNameController.text.trim().isEmpty) {
      return 'Kurum adini girin';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Gecerli bir e-posta adresi girin';
    }
    if (password.length < 8) {
      return 'Şifre en az 8 karakter olmali';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Şifre en az 1 buyuk harf icermeli';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Şifre en az 1 kucuk harf icermeli';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Şifre en az 1 rakam icermeli';
    }
    if (password != confirm) {
      return 'Şifreler eslesmiyor';
    }
    return null;
  }

  Future<void> _register() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      setState(() => _localError = validationError);
      return;
    }
    setState(() => _localError = null);

    final Map<String, dynamic> result;
    if (_isOrgRegistration) {
      result = await ref.read(authProvider.notifier).registerOrganization(
        _emailController.text.trim(),
        _nameController.text.trim(),
        _passwordController.text,
        _orgNameController.text.trim(),
      );
    } else {
      result = await ref.read(authProvider.notifier).register(
        _emailController.text.trim(),
        _nameController.text.trim(),
        _passwordController.text,
      );
    }

    if (result['success'] == true && mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/verify-email',
        arguments: {'email': _emailController.text.trim()},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final error = _localError ?? auth.error;

    return Scaffold(
      backgroundColor: context.scada.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: ScadaColors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: ScadaColors.green.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.person_add, size: 32, color: ScadaColors.green),
              ),
              const SizedBox(height: 16),
              Text('Hesap Oluştur', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
              const SizedBox(height: 4),
              Text('OrientPro platformuna kayıt olun', style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
              const SizedBox(height: 32),

              // Form card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.scada.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.scada.border),
                ),
                child: Column(children: [
                  // Kayıt tipi toggle
                  Container(
                    decoration: BoxDecoration(
                      color: context.scada.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Expanded(child: GestureDetector(
                        onTap: () => setState(() => _isOrgRegistration = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isOrgRegistration ? ScadaColors.cyan.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: !_isOrgRegistration ? Border.all(color: ScadaColors.cyan.withValues(alpha: 0.4)) : null,
                          ),
                          child: Center(child: Text('Bireysel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: !_isOrgRegistration ? ScadaColors.cyan : context.scada.textDim))),
                        ),
                      )),
                      Expanded(child: GestureDetector(
                        onTap: () => setState(() => _isOrgRegistration = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isOrgRegistration ? ScadaColors.green.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: _isOrgRegistration ? Border.all(color: ScadaColors.green.withValues(alpha: 0.4)) : null,
                          ),
                          child: Center(child: Text('Kurum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: _isOrgRegistration ? ScadaColors.green : context.scada.textDim))),
                        ),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Kurum adi (sadece kurum kaydi modunda)
                  if (_isOrgRegistration) ...[
                    _buildField(_orgNameController, 'Kurum Adi', Icons.business, TextInputType.text),
                    const SizedBox(height: 14),
                  ],

                  // Ad Soyad
                  _buildField(_nameController, 'Ad Soyad', Icons.person_outline, TextInputType.name),
                  const SizedBox(height: 14),

                  // E-posta
                  _buildField(_emailController, 'E-posta', Icons.email_outlined, TextInputType.emailAddress),
                  const SizedBox(height: 14),

                  // Şifre
                  _buildPasswordField(_passwordController, 'Şifre', _obscure, () => setState(() => _obscure = !_obscure)),
                  const SizedBox(height: 14),

                  // Şifre Tekrar
                  _buildPasswordField(_confirmController, 'Şifre Tekrar', _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                  const SizedBox(height: 8),

                  // Şifre kuralları
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.scada.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Şifre kuralları:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.scada.textDim)),
                      const SizedBox(height: 4),
                      _buildRule('En az 8 karakter'),
                      _buildRule('En az 1 buyuk harf'),
                      _buildRule('En az 1 kucuk harf'),
                      _buildRule('En az 1 rakam'),
                    ]),
                  ),

                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: ScadaColors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ScadaColors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, size: 14, color: ScadaColors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(error, style: const TextStyle(color: ScadaColors.red, fontSize: 12))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Kayıt butonu
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScadaColors.green.withValues(alpha: 0.15),
                        foregroundColor: ScadaColors.green,
                        side: BorderSide(color: ScadaColors.green.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: auth.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.green))
                        : const Text('Kayıt Ol', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // Login linki
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Zaten hesabınız var mi?', style: TextStyle(fontSize: 12, color: context.scada.textDim)),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Giriş Yap', style: TextStyle(fontSize: 12, color: ScadaColors.cyan, fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, TextInputType type) {
    return TextField(
      controller: controller,
      style: TextStyle(color: context.scada.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.scada.textDim, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: context.scada.textDim),
        filled: true, fillColor: context.scada.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.5))),
      ),
      keyboardType: type,
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: controller,
      style: TextStyle(color: context.scada.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.scada.textDim, fontSize: 13),
        prefixIcon: Icon(Icons.lock_outline, size: 18, color: context.scada.textDim),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18, color: context.scada.textDim),
          onPressed: toggle,
        ),
        filled: true, fillColor: context.scada.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.5))),
      ),
      obscureText: obscure,
    );
  }

  Widget _buildRule(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: [
        Icon(Icons.check_circle_outline, size: 10, color: context.scada.textDim),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 9, color: context.scada.textDim)),
      ]),
    );
  }
}
