import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/auth_dio.dart';
import '../../models/equipment.dart';
import '../../providers/auth_provider.dart';

class CreateWorkOrderScreen extends ConsumerStatefulWidget {
  final Equipment equipment;
  const CreateWorkOrderScreen({super.key, required this.equipment});
  @override
  ConsumerState<CreateWorkOrderScreen> createState() => _CreateWorkOrderScreenState();
}

class _CreateWorkOrderScreenState extends ConsumerState<CreateWorkOrderScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'normal';
  String _faultType = 'calismiyor';
  String _source = 'teknik';
  bool _isLoading = false;
  final List<Map<String, String>> _faultTypes = [{'value': 'calismiyor', 'label': 'Calismiyor'}, {'value': 'sogutmuyor', 'label': 'Sogutmuyor'}, {'value': 'ses_gurultu', 'label': 'Ses/Gurultu'}, {'value': 'tikaniklik', 'label': 'Tikaniklik'}, {'value': 'su_kacagi', 'label': 'Su Kacagi'}, {'value': 'kirik_hasarli', 'label': 'Kirik/Hasarli'}, {'value': 'kapanmiyor', 'label': 'Kapanmiyor'}, {'value': 'koku', 'label': 'Koku'}, {'value': 'yanmiyor', 'label': 'Yanmiyor'}, {'value': 'dusuk_basinc', 'label': 'Dusuk Basinc'}, {'value': 'diger', 'label': 'Diger'}];
  Future<void> _submit() async {
    if (_titleController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Baslik zorunludur'), backgroundColor: Colors.red)); return; }
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authProvider);
      final dio = ref.read(authDioProvider);
      await dio.post('/work-orders/', data: {'title': _titleController.text, 'description': _descController.text, 'priority': _priority, 'fault_type': _faultType, 'source_department': _source, 'equipment_id': widget.equipment.id, 'room_number': widget.equipment.roomNumber, 'created_by': auth.user!.id});
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Is emri olusturuldu!'), backgroundColor: Colors.green)); Navigator.pop(context, true); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata olustu'), backgroundColor: Colors.red)); }
    finally { setState(() => _isLoading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Is Emri')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.smart_toy, color: Color(0xFF0a0e1a)),
        tooltip: 'AI Asistan',
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), children: [
        Card(color: const Color(0xFFE8F5E9), child: ListTile(leading: const Icon(Icons.build, color: Color(0xFF1B5E20)), title: Text(widget.equipment.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(widget.equipment.categoryText))),
        const SizedBox(height: 16),
        TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Baslik *', hintText: 'Orn: Klima sogutmuyor', prefixIcon: Icon(Icons.title), border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Aciklama', prefixIcon: Icon(Icons.description), border: OutlineInputBorder()), maxLines: 3),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: _faultType, decoration: const InputDecoration(labelText: 'Ariza Tipi', prefixIcon: Icon(Icons.report_problem), border: OutlineInputBorder()), items: _faultTypes.map((f) => DropdownMenuItem(value: f['value'], child: Text(f['label']!))).toList(), onChanged: (v) => setState(() => _faultType = v!)),
        const SizedBox(height: 12),
        const Text('Oncelik', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [_prioChip('critical', 'Kritik', Colors.red), _prioChip('high', 'Yuksek', Colors.orange), _prioChip('normal', 'Normal', Colors.blue), _prioChip('low', 'Dusuk', Colors.grey)]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: _source, decoration: const InputDecoration(labelText: 'Bildiren Departman', prefixIcon: Icon(Icons.business), border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'teknik', child: Text('Teknik')), DropdownMenuItem(value: 'hk', child: Text('Housekeeping')), DropdownMenuItem(value: 'yonetim', child: Text('Yonetim')), DropdownMenuItem(value: 'misafir', child: Text('Misafir')), DropdownMenuItem(value: 'kontrol', child: Text('Kontrol Turu'))], onChanged: (v) => setState(() => _source = v!)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _isLoading ? null : _submit, icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send), label: const Text('Is Emri Olustur', style: TextStyle(fontSize: 16)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white))),
      ]),
    );
  }
  Widget _prioChip(String val, String label, Color color) { final sel = _priority == val; return ChoiceChip(label: Text(label), selected: sel, selectedColor: color.withValues(alpha: 0.25), labelStyle: TextStyle(color: sel ? color : Colors.black87, fontWeight: sel ? FontWeight.bold : FontWeight.normal), onSelected: (_) => setState(() => _priority = val)); }
}
