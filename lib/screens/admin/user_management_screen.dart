import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';
import '../../core/theme/app_theme.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).loadUsers());
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Uyelik Yonetimi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ScadaColors.cyan,
        onPressed: () => _showCreateUserSheet(context),
        child: const Icon(Icons.person_add, color: ScadaColors.bg),
      ),
      body: admin.isLoading && admin.users.isEmpty
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : admin.error != null && admin.users.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, size: 48, color: ScadaColors.red),
                    const SizedBox(height: 12),
                    Text(admin.error!, style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.read(adminProvider.notifier).loadUsers(),
                      child: const Text('Tekrar Dene'),
                    ),
                  ]),
                )
              : admin.users.isEmpty
                  ? const Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.people_outline, size: 48, color: ScadaColors.textDim),
                        SizedBox(height: 12),
                        Text('Henuz kullanici yok', style: TextStyle(color: ScadaColors.textSecondary, fontSize: 13)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: admin.users.length,
                      itemBuilder: (context, index) {
                        final user = admin.users[index];
                        return _buildUserCard(user);
                      },
                    ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final roleColor = _getRoleColor(user.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.border),
      ),
      child: InkWell(
        onTap: () => _showUserDetailSheet(user),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: roleColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
                const SizedBox(height: 2),
                Text(user.email, style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(user.roleText, style: TextStyle(fontSize: 9, color: roleColor, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),
                  if (user.department != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ScadaColors.purple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(user.departmentText, style: const TextStyle(fontSize: 9, color: ScadaColors.purple, fontWeight: FontWeight.w600)),
                    ),
                ]),
              ]),
            ),
            // Active toggle
            Switch(
              value: user.isActive,
              activeThumbColor: ScadaColors.green,
              onChanged: (_) => ref.read(adminProvider.notifier).toggleUserActive(user.id),
            ),
          ]),
        ),
      ),
    );
  }

  void _showUserDetailSheet(dynamic user) {
    final limitCtrl = TextEditingController(text: user.sharedUploadLimit.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: ScadaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.person, color: ScadaColors.cyan, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(user.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary))),
            ]),
            const SizedBox(height: 4),
            Text(user.email, style: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary)),
            Text('${user.roleText} - ${user.departmentText}', style: const TextStyle(fontSize: 12, color: ScadaColors.textDim)),
            const Divider(color: ScadaColors.border, height: 24),

            const Text('Paylasilan Icerik Limiti', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Bu kullanicinin paylasilan kutuphanede yukleyebilecegi maksimum icerik sayisi.', style: TextStyle(fontSize: 11, color: ScadaColors.textDim)),
            const SizedBox(height: 10),
            Row(children: [
              SizedBox(
                width: 80,
                child: TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: ScadaColors.textPrimary, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: ScadaColors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ScadaColors.cyan)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.cyan,
                    foregroundColor: ScadaColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final newLimit = int.tryParse(limitCtrl.text) ?? 5;
                    final success = await ref.read(adminProvider.notifier).updateUserLimit(user.id, newLimit);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Limit guncellendi: $newLimit' : 'Hata olustu'),
                          backgroundColor: success ? ScadaColors.green : ScadaColors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Limiti Guncelle', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ]),
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    if (role == 'admin') return ScadaColors.red;
    if (role.endsWith('_mudur')) return ScadaColors.amber;
    if (role.endsWith('_sefi')) return ScadaColors.cyan;
    return ScadaColors.green;
  }

  void _showCreateUserSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedRole = 'hk_staff';
    String selectedDept = 'hk';

    const roles = {
      'admin': 'Admin',
      'teknik_mudur': 'Teknik Mudur',
      'resepsiyon_mudur': 'Resepsiyon Muduru',
      'hk_mudur': 'HK Muduru',
      'guvenlik_mudur': 'Guvenlik Muduru',
      'mutfak_mudur': 'Mutfak Muduru',
      'fb_mudur': 'Yiyecek Icecek Muduru',
      'spa_mudur': 'SPA Muduru',
      'elektrik_sefi': 'Elektrik Sefi',
      'mekanik_sefi': 'Mekanik Sefi',
      'tesisat_sefi': 'Tesisat Sefi',
      'elektrikci': 'Elektrikci',
      'mekanikci': 'Mekanikci',
      'tesisatci': 'Tesisatci',
      'teknik_staff': 'Teknik Personel',
      'hk_staff': 'HK Personeli',
      'resepsiyon_staff': 'Resepsiyon Personeli',
      'guvenlik_staff': 'Guvenlik Personeli',
      'mutfak_staff': 'Mutfak Personeli',
      'fb_staff': 'Yiyecek Icecek Personeli',
      'spa_staff': 'SPA Personeli',
    };

    const departments = {
      'yonetim': 'Yonetim',
      'teknik': 'Teknik Servis',
      'hk': 'Kat Hizmetleri',
      'on_buro': 'Resepsiyon',
      'fb': 'Yiyecek & Icecek',
      'guvenlik': 'Guvenlik',
      'mutfak': 'Mutfak',
      'spa': 'SPA & Wellness',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ScadaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ScadaColors.cyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add, color: ScadaColors.cyan, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Yeni Uyelik Olustur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
                  ]),
                  const SizedBox(height: 20),

                  // Ad Soyad
                  _buildFormField(
                    controller: nameCtrl,
                    label: 'Ad Soyad',
                    icon: Icons.person,
                    validator: (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
                  ),
                  const SizedBox(height: 12),

                  // Email
                  _buildFormField(
                    controller: emailCtrl,
                    label: 'E-posta',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Zorunlu alan';
                      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(v)) return 'Gecerli bir e-posta girin (ornek@domain.com)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Sifre
                  _buildFormField(
                    controller: passwordCtrl,
                    label: 'Sifre',
                    icon: Icons.lock,
                    obscure: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Zorunlu alan';
                      if (v.length < 8) return 'En az 8 karakter';
                      if (!v.contains(RegExp(r'[A-Z]'))) return 'En az 1 buyuk harf';
                      if (!v.contains(RegExp(r'[0-9]'))) return 'En az 1 rakam';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Rol
                  _buildDropdown(
                    label: 'Rol',
                    icon: Icons.badge,
                    value: selectedRole,
                    items: roles,
                    onChanged: (v) => setSheetState(() => selectedRole = v!),
                  ),
                  const SizedBox(height: 12),

                  // Departman
                  _buildDropdown(
                    label: 'Departman',
                    icon: Icons.business,
                    value: selectedDept,
                    items: departments,
                    onChanged: (v) => setSheetState(() => selectedDept = v!),
                  ),
                  const SizedBox(height: 12),

                  // Telefon
                  _buildFormField(
                    controller: phoneCtrl,
                    label: 'Telefon (opsiyonel)',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: Consumer(builder: (ctx, ref, _) {
                      final isSaving = ref.watch(adminProvider).isSaving;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ScadaColors.cyan,
                          foregroundColor: ScadaColors.bg,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                final success = await ref.read(adminProvider.notifier).createUser(
                                      email: emailCtrl.text.trim(),
                                      password: passwordCtrl.text,
                                      fullName: nameCtrl.text.trim(),
                                      role: selectedRole,
                                      department: selectedDept,
                                      phone: phoneCtrl.text.trim(),
                                    );
                                if (success && ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kullanici basariyla olusturuldu'),
                                      backgroundColor: ScadaColors.green,
                                    ),
                                  );
                                } else if (ctx.mounted) {
                                  final error = ref.read(adminProvider).error;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(error ?? 'Hata olustu'),
                                      backgroundColor: ScadaColors.red,
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: ScadaColors.bg))
                            : const Text('Olustur', style: TextStyle(fontWeight: FontWeight.w600)),
                      );
                    }),
                  ),
                ]),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: ScadaColors.textDim),
        filled: true,
        fillColor: ScadaColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ScadaColors.cyan)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      dropdownColor: ScadaColors.surface,
      style: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: ScadaColors.textDim),
        filled: true,
        fillColor: ScadaColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ScadaColors.cyan)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
    );
  }
}
