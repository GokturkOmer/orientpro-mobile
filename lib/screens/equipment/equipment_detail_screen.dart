import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/equipment.dart';

class EquipmentDetailScreen extends StatelessWidget {
  final Equipment equipment;
  const EquipmentDetailScreen({super.key, required this.equipment});
  Color _statusColor(String s) { switch (s) { case 'active': return ScadaColors.green; case 'maintenance': return ScadaColors.amber; case 'inactive': return ScadaColors.red; default: return ScadaColors.textDim; } }
  Color _critColor(String? c) { switch (c) { case 'critical': return ScadaColors.red; case 'high': return ScadaColors.amber; case 'normal': return ScadaColors.cyan; default: return ScadaColors.textDim; } }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(equipment.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: ScadaColors.cyan,
        tooltip: 'AI Asistan',
        child: Icon(Icons.smart_toy, color: context.scada.bg),
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
          _row(context, 'Kategori', equipment.categoryText), _row(context, 'Alt Tip', equipment.subcategory), _row(context, 'Üretici', equipment.manufacturer ?? '-'), _row(context, 'Model', equipment.model ?? '-'), _row(context, 'Seri No', equipment.serialNumber ?? '-'), _row(context, 'QR Kod', equipment.qrCode ?? '-'),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Konum Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(),
          _row(context, 'Konum', equipment.locationDetail ?? '-'),
          if (equipment.roomNumber != null) _row(context, 'Oda No', equipment.roomNumber!),
          if (equipment.zone != null) _row(context, 'Bolge', equipment.zone!),
        ]))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/create-work-order', arguments: equipment), icon: const Icon(Icons.assignment_add), label: const Text('Is Emri Oluştur', style: TextStyle(fontSize: 16)), style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.amber, foregroundColor: Colors.white))),
      ]),
    );
  }
  Widget _row(BuildContext context, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [SizedBox(width: 100, child: Text(label, style: TextStyle(color: context.scada.textDim, fontWeight: FontWeight.w500))), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)))]));
  }
}
