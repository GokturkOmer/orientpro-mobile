import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_helper.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _dio.close();
    super.dispose();
  }

  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscure = true;
  String? _error;
  String? _success;

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'E-posta adresinizi girin');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
      setState(() { _codeSent = true; _isLoading = false; _success = 'Sifirlama kodu e-posta adresinize gonderildi'; });
    } on DioException catch (e) {
      setState(() { _isLoading = false; _error = ErrorHelper.getMessage(e); });
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Bir hata olustu'; });
    }
  }

  Future<void> _resetPassword() async {
    if (_codeController.text.trim().length != 6) {
      setState(() => _error = '6 haneli dogrulama kodunu girin');
      return;
    }
    if (_newPasswordController.text.length < 8) {
      setState(() => _error = 'Yeni sifre en az 8 karakter olmali');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final resp = await _dio.post('/auth/reset-password', data: {
        'email': _emailController.text.trim(),
        'code': _codeController.text.trim(),
        'new_password': _newPasswordController.text,
      });
      setState(() { _isLoading = false; _success = resp.data['detail']; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      setState(() { _isLoading = false; _error = ErrorHelper.getMessage(e); });
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Bir hata olustu'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(backgroundColor: context.scada.surface, title: Text('Sifremi Sifirla', style: TextStyle(fontSize: 16))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.scada.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.scada.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Icon(Icons.lock_reset, size: 48, color: ScadaColors.cyan),
              const SizedBox(height: 16),
              Text(
                _codeSent ? 'Kodu girin ve yeni sifrenizi belirleyin' : 'E-posta adresinizi girin',
                style: TextStyle(color: context.scada.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // E-posta alani (her zaman gorunur)
              TextField(
                controller: _emailController,
                enabled: !_codeSent,
                style: TextStyle(color: context.scada.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  labelStyle: TextStyle(color: context.scada.textDim, fontSize: 13),
                  prefixIcon: Icon(Icons.email_outlined, size: 18, color: context.scada.textDim),
                  filled: true, fillColor: context.scada.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              if (_codeSent) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _codeController,
                  style: TextStyle(color: context.scada.textPrimary, fontSize: 20, letterSpacing: 8),
                  decoration: InputDecoration(
                    labelText: '6 Haneli Kod',
                    labelStyle: TextStyle(color: context.scada.textDim, fontSize: 13),
                    prefixIcon: Icon(Icons.pin, size: 18, color: context.scada.textDim),
                    filled: true, fillColor: context.scada.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscure,
                  style: TextStyle(color: context.scada.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Yeni Sifre',
                    labelStyle: TextStyle(color: context.scada.textDim, fontSize: 13),
                    prefixIcon: Icon(Icons.lock_outline, size: 18, color: context.scada.textDim),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18, color: context.scada.textDim),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    filled: true, fillColor: context.scada.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
                  ),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ScadaColors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ScadaColors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: ScadaColors.red, fontSize: 12)),
                ),
              ],

              if (_success != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ScadaColors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ScadaColors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(_success!, style: const TextStyle(color: ScadaColors.green, fontSize: 12)),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_codeSent ? _resetPassword : _sendCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.cyan.withValues(alpha: 0.15),
                    foregroundColor: ScadaColors.cyan,
                    side: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.cyan))
                    : Text(_codeSent ? 'Sifreyi Sifirla' : 'Kod Gonder', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
