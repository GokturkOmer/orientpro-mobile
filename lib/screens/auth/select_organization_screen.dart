import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/turkish_string.dart';

/// Birden fazla organizasyona uye olan kullanıcılar icin
/// org secim ekrani. Login sonrasi otomatik acilir.
class SelectOrganizationScreen extends ConsumerStatefulWidget {
  const SelectOrganizationScreen({super.key});
  @override
  ConsumerState<SelectOrganizationScreen> createState() => _SelectOrganizationScreenState();
}

class _SelectOrganizationScreenState extends ConsumerState<SelectOrganizationScreen> {
  String? _selectedOrgId;
  bool _isLoading = false;

  Future<void> _selectOrg(String orgId) async {
    setState(() {
      _selectedOrgId = orgId;
      _isLoading = true;
    });
    final success = await ref.read(authProvider.notifier).selectOrganization(orgId);
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/module-selection');
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final orgs = auth.organizations;

    return Scaffold(
      backgroundColor: context.scada.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: ScadaColors.cyan.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.business, size: 40, color: ScadaColors.cyan),
                ),
                const SizedBox(height: 16),
                Text('OrientPro',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ScadaColors.cyan)),
                const SizedBox(height: 8),
                Text('Organizasyon Seçin',
                  style: TextStyle(fontSize: 16, color: context.scada.textSecondary)),
                const SizedBox(height: 8),
                Text('Birden fazla organizasyona üyesiniz.\nDevam etmek için birini seçin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: context.scada.textDim)),
                const SizedBox(height: 32),

                // Hata mesaji
                if (auth.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: ScadaColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ScadaColors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, size: 18, color: ScadaColors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(auth.error!, style: const TextStyle(color: ScadaColors.red, fontSize: 13))),
                    ]),
                  ),

                // Org listesi
                ...orgs.map((org) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : () => _selectOrg(org.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedOrgId == org.id
                              ? ScadaColors.cyan.withValues(alpha: 0.1)
                              : context.scada.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedOrgId == org.id
                                ? ScadaColors.cyan
                                : context.scada.border,
                            width: _selectedOrgId == org.id ? 2 : 1,
                          ),
                        ),
                        child: Row(children: [
                          // Org logo/ikon
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: ScadaColors.cyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                org.name.isNotEmpty ? org.name[0].toTurkishUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold, color: ScadaColors.cyan,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Org bilgileri
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(org.name,
                                style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600, color: context.scada.textPrimary,
                                )),
                              const SizedBox(height: 4),
                              Text(_roleText(org.role),
                                style: TextStyle(fontSize: 13, color: context.scada.textDim)),
                            ],
                          )),
                          // Loading veya ok ikonu
                          if (_selectedOrgId == org.id && _isLoading)
                            const SizedBox(width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.cyan))
                          else
                            Icon(Icons.arrow_forward_ios, size: 16, color: context.scada.textDim),
                        ]),
                      ),
                    ),
                  ),
                )),

                const SizedBox(height: 16),
                // Geri butonu
                TextButton.icon(
                  onPressed: _isLoading ? null : () {
                    ref.read(authProvider.notifier).logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Farkli hesapla giriş yap'),
                  style: TextButton.styleFrom(foregroundColor: context.scada.textDim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _roleText(String role) {
    const map = {
      'admin': 'Yönetici',
      'facility_manager': 'Tesis Yöneticisi',
      'chief_technician': 'Bas Teknisyen',
      'staff': 'Personel',
    };
    return map[role] ?? role;
  }
}
