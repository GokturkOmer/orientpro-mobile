import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/auth_dio.dart';
import '../../core/theme/app_theme.dart';

class SuperAdminCreateOrgScreen extends ConsumerStatefulWidget {
  const SuperAdminCreateOrgScreen({super.key});

  @override
  ConsumerState<SuperAdminCreateOrgScreen> createState() => _SuperAdminCreateOrgScreenState();
}

class _SuperAdminCreateOrgScreenState extends ConsumerState<SuperAdminCreateOrgScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();

  String _sector = 'otel';
  String _planType = 'trial';
  int _maxUsers = 10;
  final List<String> _modules = ['orientation'];

  bool _isLoading = false;
  Map<String, dynamic>? _result;

  final _sectors = ['otel', 'hastane', 'fabrika', 'restoran', 'diger'];
  final _plans = ['trial', 'starter', 'pro', 'enterprise'];
  final _availableModules = ['orientation', 'scada', 'rag', 'chatbot', 'maintenance'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(authDioProvider);
      final res = await dio.post('/super-admin/organizations', data: {
        'org_name': _orgNameCtrl.text.trim(),
        'sector': _sector,
        'plan_type': _planType,
        'max_users': _maxUsers,
        'allowed_modules': _modules,
        'admin_full_name': _adminNameCtrl.text.trim(),
        'admin_email': _adminEmailCtrl.text.trim(),
      });
      setState(() { _result = res.data; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: ScadaColors.red),
        );
      }
    }
  }

  void _reset() {
    setState(() { _result = null; });
    _orgNameCtrl.clear();
    _adminNameCtrl.clear();
    _adminEmailCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _SuccessView(_result!, _reset);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionLabel('ISLETME BILGILERI'),
          const SizedBox(height: 12),
          _Field(controller: _orgNameCtrl, label: 'İşletme Adi', hint: 'Otel ABC', validator: (v) => (v?.trim().length ?? 0) < 2 ? 'En az 2 karakter' : null),
          const SizedBox(height: 12),
          _DropdownField('Sektor', _sector, _sectors, (v) => setState(() => _sector = v!)),
          const SizedBox(height: 12),
          _DropdownField('Plan', _planType, _plans, (v) => setState(() => _planType = v!)),
          const SizedBox(height: 12),
          // Kullanici limiti
          Row(children: [
            Expanded(child: Text('Kullanici Limiti', style: TextStyle(fontSize: 13, color: context.scada.textSecondary))),
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () { if (_maxUsers > 1) setState(() => _maxUsers--); }),
            Text('$_maxUsers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _maxUsers++)),
          ]),
          const SizedBox(height: 12),
          // Modul secimi
          Text('Moduller', style: TextStyle(fontSize: 13, color: context.scada.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: _availableModules.map((m) {
              final selected = _modules.contains(m);
              return FilterChip(
                label: Text(m, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) { _modules.add(m); }
                    else { _modules.remove(m); }
                  });
                },
                selectedColor: ScadaColors.red.withValues(alpha: 0.15),
                checkmarkColor: ScadaColors.red,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          _SectionLabel('ADMIN KULLANICI'),
          const SizedBox(height: 12),
          _Field(controller: _adminNameCtrl, label: 'Ad Soyad', hint: 'Ahmet Yilmaz', validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Ad giriniz' : null),
          const SizedBox(height: 12),
          _Field(
            controller: _adminEmailCtrl,
            label: 'E-posta',
            hint: 'admin@isletme.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'E-posta giriniz';
              if (!v.contains('@')) return 'Gecerli e-posta giriniz';
              return null;
            },
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.add_business),
              label: Text(_isLoading ? 'Oluşturuluyor...' : 'Musteri Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ScadaColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    super.dispose();
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.scada.textSecondary, letterSpacing: 1));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _Field({required this.controller, required this.label, required this.hint, this.keyboardType, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;
  const _DropdownField(this.label, this.value, this.items, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
    );
  }
}

class _SuccessView extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onReset;
  const _SuccessView(this.result, this.onReset);

  @override
  Widget build(BuildContext context) {
    final org = result['organization'] as Map? ?? {};
    final admin = result['admin'] as Map? ?? {};

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: ScadaColors.green, size: 64),
          const SizedBox(height: 16),
          const Text('Musteri Oluşturuldu!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ScadaColors.green)),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.scada.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.scada.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoRow('İşletme', org['name'] ?? ''),
              _InfoRow('Slug', org['slug'] ?? ''),
              _InfoRow('Plan', org['plan_type'] ?? ''),
              const Divider(height: 20),
              _InfoRow('Admin E-posta', admin['email'] ?? ''),
              _InfoRow('Admin Ad', admin['full_name'] ?? ''),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ScadaColors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ScadaColors.amber.withValues(alpha: 0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.warning_amber_rounded, color: ScadaColors.amber, size: 16),
                    SizedBox(width: 6),
                    Text('Gecici Şifre — Sadece Bir Kez Gosterilir', style: TextStyle(fontSize: 11, color: ScadaColors.amber, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  SelectableText(
                    admin['temp_password'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'monospace', letterSpacing: 2),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.add_business),
              label: const Text('Yeni Musteri Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ScadaColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: context.scada.textSecondary))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary))),
      ]),
    );
  }
}
