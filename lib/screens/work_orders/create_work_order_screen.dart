import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
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
  final _descriptionController = TextEditingController();
  String _priority = 'normal';
  bool _isLoading = false;

  final List<Map<String, String>> _priorities = [
    {'value': 'critical', 'label': 'Kritik'},
    {'value': 'high', 'label': 'Yuksek'},
    {'value': 'normal', 'label': 'Normal'},
    {'value': 'low', 'label': 'Dusuk'},
  ];

  Future<void> _submit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baslik zorunludur'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authProvider);
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));
      await dio.post('/work-orders/', data: {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'priority': _priority,
        'equipment_id': widget.equipment.id,
        'created_by': auth.user!.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Is emri olusturuldu!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hata olustu'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Is Emri')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ekipman bilgisi
          Card(
            color: const Color(0xFFE8F5E9),
            child: ListTile(
              leading: const Icon(Icons.build, color: Color(0xFF1B5E20)),
              title: Text(widget.equipment.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(' '),
            ),
          ),
          const SizedBox(height: 20),

          // Baslik
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Baslik *',
              hintText: 'Orn: Motor titresim yapiyor',
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Aciklama
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Aciklama',
              hintText: 'Detayli aciklama yazin...',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          // Oncelik
          const Text('Oncelik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _priorities.map((p) {
              final isSelected = _priority == p['value'];
              Color chipColor;
              switch (p['value']) {
                case 'critical': chipColor = Colors.red; break;
                case 'high': chipColor = Colors.orange; break;
                case 'normal': chipColor = Colors.blue; break;
                default: chipColor = Colors.grey;
              }
              return ChoiceChip(
                label: Text(p['label']!),
                selected: isSelected,
                selectedColor: chipColor.withValues(alpha: 0.25),
                labelStyle: TextStyle(color: isSelected ? chipColor : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                onSelected: (_) => setState(() => _priority = p['value']!),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Gonder butonu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
              label: const Text('Is Emri Olustur', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
