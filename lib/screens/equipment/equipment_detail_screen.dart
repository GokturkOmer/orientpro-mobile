import 'package:flutter/material.dart';
import '../../models/equipment.dart';

class EquipmentDetailScreen extends StatelessWidget {
  final Equipment equipment;

  const EquipmentDetailScreen({super.key, required this.equipment});

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'maintenance': return Colors.orange;
      case 'inactive': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(equipment.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Durum karti
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.build, size: 48, color: _statusColor(equipment.status)),
                  const SizedBox(height: 12),
                  Text(equipment.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(equipment.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(equipment.statusText, style: TextStyle(color: _statusColor(equipment.status), fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bilgiler
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ekipman Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildInfoRow('Tip', equipment.equipmentType),
                  _buildInfoRow('Uretici', equipment.manufacturer ?? '-'),
                  _buildInfoRow('Model', equipment.model ?? '-'),
                  _buildInfoRow('Seri No', equipment.serialNumber ?? '-'),
                  _buildInfoRow('Konum', equipment.locationDetail ?? '-'),
                  _buildInfoRow('QR Kod', equipment.qrCode ?? '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Is emri olustur butonu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/create-work-order', arguments: equipment);
              },
              icon: const Icon(Icons.assignment_add),
              label: const Text('Is Emri Olustur', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
