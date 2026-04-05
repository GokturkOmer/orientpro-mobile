import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_helper.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});
  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  final _dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));
  @override
  void dispose() {
    _codeController.dispose();
    _dio.close();
    super.dispose();
  }

  bool _isLoading = false;
  bool _resending = false;
  String? _error;
  String? _success;

  Future<void> _verify() async {
    if (_codeController.text.trim().length != 6) {
      setState(() => _error = '6 haneli dogrulama kodunu girin');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await _dio.post('/auth/verify-email', data: {
        'email': widget.email,
        'code': _codeController.text.trim(),
      });
      setState(() { _isLoading = false; _success = 'E-posta dogrulandi! Giris yapabilirsiniz.'; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } on DioException catch (e) {
      setState(() { _isLoading = false; _error = ErrorHelper.getMessage(e); });
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Bir hata olustu'; });
    }
  }

  Future<void> _resendCode() async {
    setState(() { _resending = true; _error = null; });
    try {
      await _dio.post('/auth/resend-verification', data: {'email': widget.email});
      setState(() { _resending = false; _success = 'Yeni kod gonderildi'; });
    } on DioException catch (e) {
      setState(() { _resending = false; _error = ErrorHelper.getMessage(e); });
    } catch (e) {
      setState(() { _resending = false; _error = 'Bir hata olustu'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(backgroundColor: context.scada.surface, title: Text('E-posta Dogrulama', style: TextStyle(fontSize: 16))),
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
              const Icon(Icons.mark_email_read, size: 48, color: ScadaColors.green),
              const SizedBox(height: 16),
              Text('E-posta Dogrulama', style: TextStyle(color: context.scada.textPrimary, fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                '${widget.email} adresine 6 haneli bir dogrulama kodu gonderdik.',
                style: TextStyle(color: context.scada.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _codeController,
                style: TextStyle(color: context.scada.textPrimary, fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  labelText: 'Dogrulama Kodu',
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
                  onPressed: _isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.green.withValues(alpha: 0.15),
                    foregroundColor: ScadaColors.green,
                    side: BorderSide(color: ScadaColors.green.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.green))
                    : const Text('Dogrula', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _resending ? null : _resendCode,
                child: _resending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.cyan))
                  : const Text('Kodu tekrar gonder', style: TextStyle(fontSize: 13, color: ScadaColors.cyan)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
