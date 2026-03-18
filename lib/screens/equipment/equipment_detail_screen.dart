import 'package:flutter/material.dart';
import '../../models/equipment.dart';

class EquipmentDetailScreen extends StatelessWidget {
  final Equipment equipment;
  const EquipmentDetailScreen({super.key, required this.equipment});
  Color _statusColor(String s) { switch (s) { case 'active': return Colors.green; case 'maintenance': return Colors.orange; case 'inactive': return Colors.red; default: return Colors.grey; } }
  Color _critColor(String? c) { switch (c) { case 'critical': return Colors.red; case 'high': return Colors.orange; case 'normal': return Colors.blue; default: return Colors.grey; } }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(equipment.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.smart_toy, color: Color(0xFF0a0e1a)),
        tooltip: 'AI Asistan',
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Icon(Icons.build, size: 48, color: _statusColor(equipment.status)),
          const SizedBox(height: 12),
          Text(equipment.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: _statusColor(equipment.status).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)), child: Text(equipment.statusText, style: TextStyle(color: _statusColor(equipment.status), fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: _critColor(equipment.criticality).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)), child: Text(equipment.criticalityText, style: TextStyle(color: _critColor(equipment.criticality), fontWeight: FontWeight.bold))),
          ]),
        ]))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ekipman Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(),
          _row('Kategori', equipment.categoryText), _row('Alt Tip', equipment.subcategory), _row('Uretici', equipment.manufacturer ?? '-'), _row('Model', equipment.model ?? '-'), _row('Seri No', equipment.serialNumber ?? '-'), _row('QR Kod', equipment.qrCode ?? '-'),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Konum Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(),
          _row('Konum', equipment.locationDetail ?? '-'),
          if (equipment.roomNumber != null) _row('Oda No', equipment.roomNumber!),
          if (equipment.zone != null) _row('Bolge', equipment.zone!),
        ]))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/create-work-order', arguments: equipment), icon: const Icon(Icons.assignment_add), label: const Text('Is Emri Olustur', style: TextStyle(fontSize: 16)), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white))),
      ]),
    );
  }
  Widget _row(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)))]));
  }
}
