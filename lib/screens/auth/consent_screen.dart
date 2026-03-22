import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/auth_dio.dart';
import '../../core/storage/secure_storage.dart';

/// KVKK/GDPR onay ekrani.
/// Kullanici ilk giriste veri isleme iznini onaylamadan devam edemez.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});
  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _privacyAccepted = false;
  bool _dataProcessingAccepted = false;
  bool _isLoading = false;

  bool get _canProceed => _privacyAccepted && _dataProcessingAccepted;

  Future<void> _submitConsent() async {
    if (!_canProceed) return;
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(authDioProvider);
      // Gizlilik politikasi onay
      await dio.post('/privacy/consents', data: {
        'consent_type': 'privacy_policy',
        'version': '1.0',
        'accepted': true,
      });
      // Veri isleme onay
      await dio.post('/privacy/consents', data: {
        'consent_type': 'data_processing',
        'version': '1.0',
        'accepted': true,
      });

      if (mounted) {
        final seen = await SecureStorage.isOnboardingSeen();
        if (mounted) {
          Navigator.pushReplacementNamed(context, seen ? '/module-selection' : '/onboarding');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Onay kaydedilemedi, lutfen tekrar deneyin'),
            backgroundColor: ScadaColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScadaColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Baslik
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: ScadaColors.cyan.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.shield, size: 36, color: ScadaColors.cyan),
                ),
                const SizedBox(height: 16),
                const Text('Veri Koruma & Gizlilik',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('Devam etmek icin asagidaki izinleri onaylayin',
                  style: TextStyle(fontSize: 14, color: ScadaColors.textSecondary)),
                const SizedBox(height: 32),

                // Gizlilik Politikasi
                _buildConsentCard(
                  icon: Icons.policy,
                  title: 'Gizlilik Politikasi',
                  description: 'Kisisel verileriniz (ad, e-posta, departman, egitim ilerlemesi) '
                      'yalnizca hizmet sunumu amaciyla islenir. Verileriniz 3. kisilerle '
                      'pazarlama amaciyla paylasilmaz. KVKK (6698 sayili kanun) kapsaminda '
                      'haklariniz saklitir.',
                  value: _privacyAccepted,
                  onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                ),
                const SizedBox(height: 16),

                // Veri Isleme Onay
                _buildConsentCard(
                  icon: Icons.storage,
                  title: 'Veri Isleme Izni',
                  description: 'Egitim ilerlemeniz, quiz sonuclariniz ve etkinlik kayitlariniz '
                      'organizasyonunuzun yonetim panelinde goruntulenebilir. '
                      'Bu veriler egitim surecinin takibi icin kullanilir.',
                  value: _dataProcessingAccepted,
                  onChanged: (v) => setState(() => _dataProcessingAccepted = v ?? false),
                ),
                const SizedBox(height: 24),

                // KVKK bilgi notu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ScadaColors.cyan.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.15)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline, size: 18, color: ScadaColors.cyan.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    const Expanded(child: Text(
                      'Verilerinizi istediginiz zaman disa aktarabilir veya silme talebinde '
                      'bulunabilirsiniz. Bu islemler Profil > Gizlilik boluumunden yapilabilir.',
                      style: TextStyle(fontSize: 12, color: ScadaColors.textDim),
                    )),
                  ]),
                ),
                const SizedBox(height: 24),

                // Devam butonu
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _canProceed && !_isLoading ? _submitConsent : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScadaColors.cyan,
                      foregroundColor: ScadaColors.bg,
                      disabledBackgroundColor: ScadaColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.bg))
                        : const Text('Onayla ve Devam Et',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsentCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? ScadaColors.green.withValues(alpha: 0.05) : ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? ScadaColors.green.withValues(alpha: 0.3) : ScadaColors.border,
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: ScadaColors.green,
          checkColor: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 20, color: value ? ScadaColors.green : ScadaColors.textDim),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: value ? ScadaColors.green : ScadaColors.textPrimary,
            )),
          ]),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 13, color: ScadaColors.textSecondary, height: 1.4)),
        ])),
      ]),
    );
  }
}
