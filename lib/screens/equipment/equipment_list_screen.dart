import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/auth_dio.dart';
import '../../models/equipment.dart';
import '../../core/theme/app_theme.dart';
import 'equipment_detail_screen.dart';

class EquipmentListScreen extends ConsumerStatefulWidget {
  const EquipmentListScreen({super.key});
  @override
  ConsumerState<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends ConsumerState<EquipmentListScreen> {
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
      final dio = ref.read(authDioProvider);
      String url = '/equipment/?limit=200';
      if (searchQuery.isNotEmpty) url += '&search=$searchQuery';
      if (selectedCategory != null) url += '&category=$selectedCategory';
      final res = await dio.get(url);
      setState(() { items = (res.data as List).map((e) => Equipment.fromJson(e)).toList(); isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }

  Color _statusColor(String s) { switch (s) { case 'active': return ScadaColors.green; case 'maintenance': return ScadaColors.amber; case 'inactive': return ScadaColors.red; default: return context.scada.textDim; } }
  Color _critColor(String? c) { switch (c) { case 'critical': return ScadaColors.red; case 'high': return ScadaColors.amber; case 'normal': return ScadaColors.cyan; default: return context.scada.textDim; } }
  IconData _catIcon(String c) { switch (c) { case 'HVAC': return Icons.ac_unit; case 'ELEKTRIK': return Icons.electric_bolt; case 'TESISAT': return Icons.plumbing; case 'KAPI_KILIT': return Icons.door_front_door; case 'MOBILYA': return Icons.chair; case 'ELEKTRONIK': return Icons.tv; case 'HAVUZ_SPA': return Icons.pool; case 'ASANSOR': return Icons.elevator; case 'BOYA_TADILAT': return Icons.format_paint; default: return Icons.build; } }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: ScadaColors.cyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.inventory, color: ScadaColors.cyan, size: 18)),
          const SizedBox(width: 8),
          Text('Ekipmanlar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        ]),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(50), child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            style: TextStyle(color: context.scada.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Ekipman ara...', prefixIcon: Icon(Icons.search, color: context.scada.textDim, size: 18),
              hintStyle: TextStyle(color: context.scada.textDim, fontSize: 13),
              filled: true, fillColor: context.scada.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.5))),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) { searchQuery = v; _loadEquipment(); },
          ),
        )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        backgroundColor: ScadaColors.cyan,
        tooltip: 'AI Asistan',
        child: Icon(Icons.smart_toy, color: context.scada.bg),
      ),
      body: Column(children: [
        SizedBox(height: 50, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), children: [
          Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(
            label: Text('Tumu', style: TextStyle(fontSize: 11, color: context.scada.textPrimary)),
            selected: selectedCategory == null,
            onSelected: (_) { selectedCategory = null; _loadEquipment(); },
            selectedColor: ScadaColors.cyan.withValues(alpha: 0.15),
            backgroundColor: context.scada.card,
            side: BorderSide(color: selectedCategory == null ? ScadaColors.cyan.withValues(alpha: 0.5) : context.scada.border),
          )),
          ...categories.entries.map((e) => Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(
            avatar: Icon(_catIcon(e.key), size: 14, color: selectedCategory == e.key ? ScadaColors.cyan : context.scada.textDim),
            label: Text(e.value, style: TextStyle(fontSize: 11, color: selectedCategory == e.key ? ScadaColors.cyan : context.scada.textSecondary)),
            selected: selectedCategory == e.key,
            onSelected: (_) { selectedCategory = selectedCategory == e.key ? null : e.key; _loadEquipment(); },
            selectedColor: ScadaColors.cyan.withValues(alpha: 0.15),
            backgroundColor: context.scada.card,
            side: BorderSide(color: selectedCategory == e.key ? ScadaColors.cyan.withValues(alpha: 0.5) : context.scada.border),
          ))),
        ])),
        Expanded(child: isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan))
          : RefreshIndicator(color: ScadaColors.cyan, backgroundColor: context.scada.surface, onRefresh: _loadEquipment,
            child: ListView.builder(padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), itemCount: items.length, itemBuilder: (ctx, i) {
              final eq = items[i];
              final sColor = _statusColor(eq.status);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(color: context.scada.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: context.scada.border)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EquipmentDetailScreen(equipment: eq))),
                  child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: sColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Icon(_catIcon(eq.category), color: sColor, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(eq.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
                      const SizedBox(height: 4),
                      Row(children: [
                        if (eq.roomNumber != null) ...[
                          Icon(Icons.room, size: 11, color: context.scada.textDim),
                          const SizedBox(width: 2),
                          Text('Oda ${eq.roomNumber}', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
                          const SizedBox(width: 8),
                        ],
                        Icon(Icons.category, size: 11, color: context.scada.textDim),
                        const SizedBox(width: 2),
                        Text(categories[eq.category] ?? eq.category, style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
                      ]),
                    ])),
                    Column(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: sColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4), border: Border.all(color: sColor.withValues(alpha: 0.3))),
                        child: Text(eq.statusText, style: TextStyle(fontSize: 9, color: sColor, fontWeight: FontWeight.w600))),
                      const SizedBox(height: 4),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _critColor(eq.criticality).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(eq.criticalityText, style: TextStyle(fontSize: 8, color: _critColor(eq.criticality)))),
                    ]),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: context.scada.textDim),
                  ])),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }
}
