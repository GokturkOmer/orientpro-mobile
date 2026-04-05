import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/turkish_string.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/scada_app_bar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/section_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static final _phoneRegex = RegExp(r'^0?5\d{9}$');

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null; // Bos olabilir
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!_phoneRegex.hasMatch(cleaned)) {
      return 'Gecerli bir telefon numarasi girin (05xx xxx xxxx)';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.user != null) {
        ref.read(profileProvider.notifier).loadProfile(auth.user!.id);
        ref.read(profileProvider.notifier).loadSummary(auth.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final summary = profileState.summary;
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: ScadaAppBar(
        title: 'Profil Karti',
        titleIcon: Icons.person,
        titleIconColor: ScadaColors.orange,
        actions: [
          if (profile != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: ScadaColors.cyan),
              onPressed: () => _showEditDialog(profile),
            ),
        ],
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.orange))
          : profile == null
              ? Center(child: Text('Profil yuklenemedi', style: TextStyle(color: context.scada.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  children: [
                    // Profile header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ScadaColors.orange.withValues(alpha: 0.08), ScadaColors.purple.withValues(alpha: 0.08)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ScadaColors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: ScadaColors.orange.withValues(alpha: 0.15),
                          child: Text(
                            (profile.fullName ?? '?')[0].toTurkishUpperCase(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: ScadaColors.orange),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(profile.fullName ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
                          const SizedBox(height: 2),
                          Text(profile.roleText, style: const TextStyle(fontSize: 12, color: ScadaColors.orange)),
                          if (profile.department != null)
                            Text(profile.department!, style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
                          if (profile.positionTitle != null)
                            Text(profile.positionTitle!, style: TextStyle(fontSize: 11, color: context.scada.textDim)),
                        ])),
                      ]),
                    ),

                    // Summary stats
                    if (summary != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        StatCard(label: 'Egitim', value: '${summary.completedTrainings}', color: ScadaColors.green, borderRadius: 8),
                        const SizedBox(width: 8),
                        StatCard(label: 'Belge', value: '${summary.documentCount}', color: ScadaColors.cyan, borderRadius: 8),
                        const SizedBox(width: 8),
                        StatCard(label: 'Form', value: '${summary.formCount}', color: ScadaColors.purple, borderRadius: 8),
                      ]),
                    ],

                    // Contact info
                    const SizedBox(height: 16),
                    const SectionHeader(title: 'ILETISIM BILGILERI', icon: Icons.contact_phone),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      _buildInfoRow(Icons.email, 'E-posta', profile.email ?? '-'),
                      _buildInfoRow(Icons.phone, 'Telefon', profile.phone ?? '-'),
                      _buildInfoRow(Icons.home, 'Adres', profile.address ?? '-'),
                    ]),

                    // Emergency contact
                    const SizedBox(height: 16),
                    const SectionHeader(title: 'ACIL DURUM KISI', icon: Icons.emergency),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      _buildInfoRow(Icons.person, 'Ad Soyad', profile.emergencyName ?? '-'),
                      _buildInfoRow(Icons.phone, 'Telefon', profile.emergencyPhone ?? '-'),
                      _buildInfoRow(Icons.family_restroom, 'Yakinlik', profile.emergencyRelation ?? '-'),
                    ]),

                    // Personal info
                    const SizedBox(height: 16),
                    const SectionHeader(title: 'KISISEL BILGILER', icon: Icons.badge),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      _buildInfoRow(Icons.cake, 'Dogum Tarihi', profile.birthDate ?? '-'),
                      _buildInfoRow(Icons.bloodtype, 'Kan Grubu', profile.bloodType ?? '-'),
                      _buildInfoRow(Icons.credit_card, 'TC Kimlik', profile.nationalId ?? '-'),
                      _buildInfoRow(Icons.schedule, 'Vardiya', profile.shiftTypeText),
                      _buildInfoRow(Icons.calendar_today, 'Ise Giris', profile.hireDate ?? '-'),
                    ]),

                    // Skills
                    if (profile.skills.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const SectionHeader(title: 'YETENEKLER', icon: Icons.star),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: profile.skills.map<Widget>((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ScadaColors.cyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: ScadaColors.cyan.withValues(alpha: 0.3)),
                          ),
                          child: Text(s.toString(), style: const TextStyle(fontSize: 11, color: ScadaColors.cyan)),
                        )).toList(),
                      ),
                    ],

                    // Certifications
                    if (profile.certifications.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const SectionHeader(title: 'SERTIFIKALAR', icon: Icons.verified),
                      const SizedBox(height: 8),
                      ...profile.certifications.map<Widget>((c) {
                        final cert = c is Map ? c : {};
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.scada.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.scada.border),
                          ),
                          child: Row(children: [
                            const Icon(Icons.workspace_premium, size: 18, color: ScadaColors.amber),
                            const SizedBox(width: 8),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(cert['name']?.toString() ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.scada.textPrimary)),
                              if (cert['date'] != null)
                                Text(cert['date'].toString(), style: TextStyle(fontSize: 10, color: context.scada.textDim)),
                            ])),
                          ]),
                        );
                      }),
                    ],

                    // Bio
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const SectionHeader(title: 'HAKKINDA', icon: Icons.info_outline),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.scada.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.scada.border),
                        ),
                        child: Text(profile.bio!, style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
                      ),
                    ],

                    // Abonelik Yonetimi (sadece admin)
                    if (auth.user?.role == 'admin' || auth.user?.role == 'facility_manager') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/subscription'),
                          icon: const Icon(Icons.card_membership, size: 18),
                          label: const Text('Abonelik Yonetimi'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ScadaColors.cyan,
                            side: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.scada.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: context.scada.textDim),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(fontSize: 11, color: context.scada.textSecondary)),
        ),
        Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: context.scada.textPrimary))),
      ]),
    );
  }

  void _showEditDialog(UserProfile profile) {
    final phoneCtrl = TextEditingController(text: profile.phone ?? '');
    final emergencyNameCtrl = TextEditingController(text: profile.emergencyName ?? '');
    final emergencyPhoneCtrl = TextEditingController(text: profile.emergencyPhone ?? '');
    final addressCtrl = TextEditingController(text: profile.address ?? '');
    final bioCtrl = TextEditingController(text: profile.bio ?? '');
    String? selectedBloodType = profile.bloodType;
    String? selectedRelation = profile.emergencyRelation;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.scada.borderBright),
        ),
        title: Row(children: [
          const Icon(Icons.edit, color: ScadaColors.cyan, size: 18),
          const SizedBox(width: 8),
          Text('Profil Duzenle', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
        ]),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefon (05xx xxx xxxx)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10), prefixIcon: Icon(Icons.phone, size: 16)),
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 12, color: context.scada.textPrimary),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validatePhone,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Kan Grubu', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                dropdownColor: context.scada.surface,
                initialValue: selectedBloodType,
                items: ['A+','A-','B+','B-','AB+','AB-','0+','0-'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) => selectedBloodType = val,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Adres', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                maxLines: 2,
                style: TextStyle(fontSize: 12, color: context.scada.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emergencyNameCtrl,
                decoration: const InputDecoration(labelText: 'Acil Durum Kisi Adi', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                style: TextStyle(fontSize: 12, color: context.scada.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emergencyPhoneCtrl,
                decoration: const InputDecoration(labelText: 'Acil Durum Telefon (05xx xxx xxxx)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 12, color: context.scada.textPrimary),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validatePhone,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Yakinlik Derecesi', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                dropdownColor: context.scada.surface,
                initialValue: selectedRelation,
                items: ['Es','Anne','Baba','Kardes','Diger'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) => selectedRelation = val,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: bioCtrl,
                decoration: const InputDecoration(labelText: 'Hakkinda', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                maxLines: 3,
                style: TextStyle(fontSize: 12, color: context.scada.textPrimary),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Iptal', style: TextStyle(color: context.scada.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Telefon validation
              if (_validatePhone(phoneCtrl.text) != null || _validatePhone(emergencyPhoneCtrl.text) != null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Lutfen gecerli telefon numaralari girin'), backgroundColor: ScadaColors.red),
                );
                return;
              }
              final auth = ref.read(authProvider);
              if (auth.user != null) {
                final data = <String, dynamic>{};
                if (phoneCtrl.text.isNotEmpty) data['phone'] = phoneCtrl.text;
                if (selectedBloodType != null) data['blood_type'] = selectedBloodType;
                if (addressCtrl.text.isNotEmpty) data['address'] = addressCtrl.text;
                if (emergencyNameCtrl.text.isNotEmpty) data['emergency_name'] = emergencyNameCtrl.text;
                if (emergencyPhoneCtrl.text.isNotEmpty) data['emergency_phone'] = emergencyPhoneCtrl.text;
                if (selectedRelation != null) data['emergency_relation'] = selectedRelation;
                if (bioCtrl.text.isNotEmpty) data['bio'] = bioCtrl.text;

                final ok = await ref.read(profileProvider.notifier).updateProfile(auth.user!.id, data);
                if (ok) {
                  // Profil verisini yeniden yukle
                  ref.read(profileProvider.notifier).loadProfile(auth.user!.id);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Profil guncellendi' : 'Guncelleme basarisiz'),
                      backgroundColor: ok ? ScadaColors.green : ScadaColors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    ).then((_) {
      phoneCtrl.dispose();
      emergencyNameCtrl.dispose();
      emergencyPhoneCtrl.dispose();
      addressCtrl.dispose();
      bioCtrl.dispose();
    });
  }
}
