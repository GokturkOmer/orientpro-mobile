import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../models/equipment.dart';
import 'equipment_detail_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});
  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  List<Equipment> items = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedCategory;
  final Map<String, String> categories = {'HVAC': 'Iklimlendirme', 'ELEKTRIK': 'Elektrik', 'TESISAT': 'Tesisat', 'KAPI_KILIT': 'Kapi/Kilit', 'MOBILYA': 'Mobilya', 'ELEKTRONIK': 'Elektronik', 'HAVUZ_SPA': 'Havuz/SPA', 'ASANSOR': 'Asansor', 'BOYA_TADILAT': 'Boya/Tadilat'};
  @override
  void initState() { super.initState(); _loadEquipment(); }
  Future<void> _loadEquipment() async {
    setState(() => isLoading = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));
      String url = '/equipment/?limit=200';
      if (searchQuery.isNotEmpty) url += '&search=$searchQuery';
      if (selectedCategory != null) url += '&category=$selectedCategory';
      final res = await dio.get(url);
      setState(() { items = (res.data as List).map((e) => Equipment.fromJson(e)).toList(); isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }
  Color _statusColor(String s) { switch (s) { case 'active': return Colors.green; case 'maintenance': return Colors.orange; case 'inactive': return Colors.red; default: return Colors.grey; } }
  Color _critColor(String? c) { switch (c) { case 'critical': return Colors.red; case 'high': return Colors.orange; case 'normal': return Colors.blue; default: return Colors.grey; } }
  IconData _catIcon(String c) { switch (c) { case 'HVAC': return Icons.ac_unit; case 'ELEKTRIK': return Icons.electric_bolt; case 'TESISAT': return Icons.plumbing; case 'KAPI_KILIT': return Icons.door_front_door; case 'MOBILYA': return Icons.chair; case 'ELEKTRONIK': return Icons.tv; case 'HAVUZ_SPA': return Icons.pool; case 'ASANSOR': return Icons.elevator; case 'BOYA_TADILAT': return Icons.format_paint; default: return Icons.build; } }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ekipmanlar'), bottom: PreferredSize(preferredSize: const Size.fromHeight(50), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: TextField(decoration: InputDecoration(hintText: 'Ekipman ara...', prefixIcon: const Icon(Icons.search, color: Colors.white70), hintStyle: const TextStyle(color: Colors.white70), filled: true, fillColor: Colors.white24, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)), style: const TextStyle(color: Colors.white), onChanged: (v) { searchQuery = v; _loadEquipment(); })))),
      body: Column(children: [
        SizedBox(height: 50, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), children: [
          Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(label: const Text('Tumu'), selected: selectedCategory == null, onSelected: (_) { selectedCategory = null; _loadEquipment(); }, selectedColor: const Color(0xFF1B5E20).withValues(alpha: 0.2))),
          ...categories.entries.map((e) => Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(avatar: Icon(_catIcon(e.key), size: 16), label: Text(e.value), selected: selectedCategory == e.key, onSelected: (_) { selectedCategory = selectedCategory == e.key ? null : e.key; _loadEquipment(); }, selectedColor: const Color(0xFF1B5E20).withValues(alpha: 0.2)))),
        ])),
        Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: _loadEquipment, child: ListView.builder(padding: const EdgeInsets.all(8), itemCount: items.length, itemBuilder: (ctx, i) {
          final eq = items[i];
          return Card(child: ListTile(
            leading: CircleAvatar(backgroundColor: _statusColor(eq.status).withValues(alpha: 0.15), child: Icon(_catIcon(eq.category), color: _statusColor(eq.status), size: 20)),
            title: Text(eq.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(' - '), if (eq.roomNumber != null) Text('Oda: ', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)), if (eq.roomNumber == null && eq.locationDetail != null) Text('', style: const TextStyle(fontSize: 12, color: Colors.grey))]),
            isThreeLine: true,
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _statusColor(eq.status).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text(eq.statusText, style: TextStyle(fontSize: 10, color: _statusColor(eq.status), fontWeight: FontWeight.bold))),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _critColor(eq.criticality).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(eq.criticalityText, style: TextStyle(fontSize: 9, color: _critColor(eq.criticality)))),
            ]),
            onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => EquipmentDetailScreen(equipment: eq))); },
          ));
        }))),
      ]),
    );
  }
}
