import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/role_helper.dart';
import '../../core/network/auth_dio.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/training.dart';
import 'widgets/route_list_widget.dart';
import 'widgets/pdf_upload_dialog.dart';

class ContentManagerScreen extends ConsumerStatefulWidget {
  const ContentManagerScreen({super.key});

  @override
  ConsumerState<ContentManagerScreen> createState() => _ContentManagerScreenState();
}

class _ContentManagerScreenState extends ConsumerState<ContentManagerScreen> {
  String? _selectedType; // 'route' | 'modüle'
  String? _selectedId;
  final Set<String> _expandedDepartments = {};
  bool _showLeftPanel = true;

  // Semantic search
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchPanel = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProvider.notifier).loadDepartments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      final results = await ref.read(adminProvider.notifier).searchTrainingContent(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectRoute(String routeId) {
    setState(() {
      _selectedType = 'route';
      _selectedId = routeId;
    });
    ref.read(adminProvider.notifier).loadRouteDetail(routeId);
  }

  void _refresh() {
    ref.read(adminProvider.notifier).loadDepartments();
    for (final deptId in _expandedDepartments) {
      ref.read(adminProvider.notifier).loadRoutes(departmentId: deptId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'İçerik Yönetimi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearchPanel ? Icons.search_off : Icons.search,
              color: _showSearchPanel ? ScadaColors.cyan : context.scada.textSecondary,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showSearchPanel = !_showSearchPanel;
                if (!_showSearchPanel) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
            tooltip: 'Semantik Arama',
          ),
          if (admin.error != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.warning_amber_rounded, color: ScadaColors.amber, size: 18),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          if (isWide) {
            return Row(
              children: [
                SizedBox(width: 280, child: _buildLeftPanel(admin)),
                Container(width: 1, color: context.scada.border),
                Expanded(child: _buildRightPanel(admin)),
              ],
            );
          }

          // Narrow layout: show one panel at a time
          if (_showLeftPanel || _selectedType == null) {
            return _buildLeftPanel(admin, onSelect: () {
              setState(() => _showLeftPanel = false);
            });
          }

          return Column(
            children: [
              _buildNarrowBackBar(),
              Expanded(child: _buildRightPanel(admin)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNarrowBackBar() {
    return Container(
      color: context.scada.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 18),
            onPressed: () => setState(() => _showLeftPanel = true),
            tooltip: 'Agaca don',
          ),
          Text(
            'İçerik Agaci',
            style: TextStyle(fontSize: 12, color: context.scada.textSecondary),
          ),
        ],
      ),
    );
  }

  // ===== LEFT PANEL =====

  Widget _buildLeftPanel(AdminState admin, {VoidCallback? onSelect}) {
    return Container(
      color: context.scada.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.scada.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_tree, color: ScadaColors.cyan, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'İçerik Agaci',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary),
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    color: context.scada.textSecondary,
                    padding: EdgeInsets.zero,
                    onPressed: _refresh,
                    tooltip: 'Yenile',
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    color: ScadaColors.cyan,
                    padding: EdgeInsets.zero,
                    onPressed: _showAddDepartmentDialog,
                    tooltip: 'Yeni departman ekle',
                  ),
                ),
              ],
            ),
          ),

          // Tree
          Expanded(
            child: admin.isLoading && admin.departments.isEmpty
                ? const Center(child: CircularProgressIndicator(color: ScadaColors.cyan, strokeWidth: 2))
                : Builder(builder: (context) {
                    // Departman filtreleme: sadece düzenlenebilir departmanlari göster
                    final auth = ref.watch(authProvider);
                    final userRole = auth.user?.role;
                    final editDepts = RoleHelper.editableDepartments(userRole);
                    final depts = editDepts == null
                        ? admin.departments
                        : admin.departments.where((d) => editDepts.contains(d.code)).toList();
                    if (depts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open, size: 36, color: context.scada.textDim),
                            SizedBox(height: 8),
                            Text(
                              'Departman bulunamadi',
                              style: TextStyle(fontSize: 12, color: context.scada.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 80),
                        itemCount: depts.length,
                        itemBuilder: (context, index) {
                          return _buildDepartmentTile(depts[index], admin, onSelect);
                        },
                      );
                  }),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentTile(Department dept, AdminState admin, VoidCallback? onNarrowSelect) {
    final isExpanded = _expandedDepartments.contains(dept.id);
    final auth = ref.watch(authProvider);
    final userRole = auth.user?.role;
    var routes = admin.routes.where((r) => r.departmentId == dept.id).toList();
    // Teknik dept icerisinde tag filtreleme
    if (dept.code == 'teknik') {
      routes = routes.where((r) => RoleHelper.canSeeTeknikRoute(userRole, r.tags)).toList();
    }

    Color deptColor;
    try {
      deptColor = dept.color != null
          ? Color(int.parse('0xFF${dept.color!.replaceAll('#', '')}'))
          : ScadaColors.purple;
    } catch (_) {
      deptColor = ScadaColors.purple;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Department header
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedDepartments.remove(dept.id);
              } else {
                _expandedDepartments.add(dept.id);
                ref.read(adminProvider.notifier).loadRoutes(departmentId: dept.id);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: context.scada.textDim,
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: deptColor, shape: BoxShape.circle),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dept.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    icon: const Icon(Icons.add, size: 14),
                    color: ScadaColors.cyan,
                    padding: EdgeInsets.zero,
                    onPressed: () => _showAddRouteDialog(dept),
                    tooltip: 'Rota ekle',
                  ),
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 14),
                    color: ScadaColors.red.withValues(alpha: 0.5),
                    hoverColor: ScadaColors.red.withValues(alpha: 0.1),
                    padding: EdgeInsets.zero,
                    onPressed: () => _confirmDeleteDepartment(dept),
                    tooltip: 'Departmani sil',
                  ),
                ),
              ],
            ),
          ),
        ),

        // Routes under department
        if (isExpanded)
          ...routes.map((route) => _buildRouteItem(route, deptColor, onNarrowSelect)),

        if (isExpanded && routes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44, bottom: 8),
            child: Text(
              'Henuz rota yok',
              style: TextStyle(fontSize: 11, color: context.scada.textDim, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget _buildRouteItem(TrainingRoute route, Color deptColor, VoidCallback? onNarrowSelect) {
    final isSelected = _selectedType == 'route' && _selectedId == route.id;
    final difficultyColor = route.difficulty == 'beginner'
        ? ScadaColors.green
        : route.difficulty == 'intermediate'
            ? ScadaColors.amber
            : ScadaColors.red;

    return GestureDetector(
      onSecondaryTap: () => _showRouteActions(route),
      child: InkWell(
        onTap: () {
          _selectRoute(route.id);
          onNarrowSelect?.call();
        },
        onLongPress: () => _showRouteActions(route),
        child: Container(
          padding: const EdgeInsets.only(left: 36, right: 8, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? ScadaColors.cyan.withValues(alpha: 0.08) : Colors.transparent,
          border: isSelected
              ? const Border(left: BorderSide(color: ScadaColors.cyan, width: 2))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              route.isMandatory ? Icons.lock : Icons.route,
              size: 14,
              color: isSelected ? ScadaColors.cyan : context.scada.textDim,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? ScadaColors.cyan : context.scada.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: difficultyColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          route.difficultyText,
                          style: TextStyle(fontSize: 8, color: difficultyColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${route.modules?.length ?? 0} modul',
                        style: TextStyle(fontSize: 9, color: context.scada.textDim),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 22,
              height: 22,
              child: IconButton(
                icon: const Icon(Icons.add, size: 12),
                color: context.scada.textSecondary,
                padding: EdgeInsets.zero,
                onPressed: () => _showAddModuleDialog(route.id),
                tooltip: 'Modül ekle',
              ),
            ),
            const SizedBox(width: 2),
            SizedBox(
              width: 22,
              height: 22,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 12),
                color: ScadaColors.red.withValues(alpha: 0.6),
                hoverColor: ScadaColors.red.withValues(alpha: 0.1),
                padding: EdgeInsets.zero,
                onPressed: () => _confirmDeleteRoute(route),
                tooltip: 'Rotayi sil',
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ===== RIGHT PANEL =====

  Widget _buildRightPanel(AdminState admin) {
    return Column(
      children: [
        // Semantic search bar (toggleable)
        if (_showSearchPanel) _buildSearchBar(),

        // Search results overlay
        if (_showSearchPanel && (_searchResults.isNotEmpty || _isSearching || _searchController.text.trim().isNotEmpty))
          Expanded(child: _buildSearchResults())
        else
          Expanded(child: _buildRightPanelContent(admin)),
      ],
    );
  }

  Widget _buildRightPanelContent(AdminState admin) {
    if (_selectedType == null) {
      return _buildEmptyState();
    }

    if (admin.isLoading && admin.selectedRoute == null && admin.selectedModule == null) {
      return const Center(child: CircularProgressIndicator(color: ScadaColors.cyan, strokeWidth: 2));
    }

    if (_selectedType == 'route') {
      return _buildRouteDetail(admin);
    }

    if (_selectedType == 'modüle') {
      return _buildModuleDetail(admin);
    }

    return _buildEmptyState();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.scada.surface,
        border: Border(bottom: BorderSide(color: context.scada.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: ScadaColors.cyan),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13, color: context.scada.textPrimary),
              decoration: InputDecoration(
                hintText: 'Eğitim dokümanlari içinde AI arama...',
                hintStyle: TextStyle(fontSize: 12, color: context.scada.textDim),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: context.scada.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.scada.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.scada.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ScadaColors.cyan),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 16, color: context.scada.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(left: 10),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: ScadaColors.cyan, strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: ScadaColors.cyan, strokeWidth: 2),
            SizedBox(height: 12),
            Text('Semantik arama yapiliyor...', style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 40, color: context.scada.textDim),
            SizedBox(height: 12),
            Text(
              '"${_searchController.text}" için sonuç bulunamadi',
              style: TextStyle(fontSize: 13, color: context.scada.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _searchResults.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: ScadaColors.cyan),
                SizedBox(width: 6),
                Text(
                  '${_searchResults.length} sonuç bulundu',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.scada.textPrimary),
                ),
              ],
            ),
          );
        }

        final result = _searchResults[index - 1];
        final score = (result['score'] as num?)?.toDouble() ?? 0;
        final scorePercent = (score * 100).toInt();
        final content = result['content'] as String? ?? '';
        final source = result['source'] as String? ?? '';
        final department = result['department'] as String? ?? '';

        final scoreColor = score > 0.8
            ? ScadaColors.green
            : score > 0.6
                ? ScadaColors.amber
                : ScadaColors.red;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.scada.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.scada.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: source + score
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf, size: 14, color: ScadaColors.red),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      source,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.scada.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '%$scorePercent eslesme',
                      style: TextStyle(fontSize: 10, color: scoreColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (department.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  _departmentLabel(department),
                  style: TextStyle(fontSize: 10, color: context.scada.textDim),
                ),
              ],
              const SizedBox(height: 8),
              // Content snippet
              Text(
                content.length > 300 ? '${content.substring(0, 300)}...' : content,
                style: TextStyle(fontSize: 12, color: context.scada.textSecondary, height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }

  String _departmentLabel(String key) {
    const labels = {
      'teknik': 'Teknik Servis',
      'hk': 'Kat Hizmetleri',
      'yönetim': 'Yönetim',
      'on_buro': 'On Buro',
      'spa': 'Spa & Wellness',
      'fb': 'Yiyecek Icecek',
      'guvenlik': 'Guvenlik',
      'genel': 'Genel',
    };
    return labels[key] ?? key;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app, size: 56, color: context.scada.textDim.withValues(alpha: 0.5)),
          SizedBox(height: 16),
          Text(
            'Sol panelden bir oge seçin',
            style: TextStyle(fontSize: 14, color: context.scada.textSecondary),
          ),
          SizedBox(height: 6),
          Text(
            'Departman, rota veya modül detaylarini görüntülemek icin\nagactan bir oge seçin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: context.scada.textDim),
          ),
        ],
      ),
    );
  }

  // ===== ROUTE DETAIL =====

  Widget _buildRouteDetail(AdminState admin) {
    final route = admin.selectedRoute;
    if (route == null) {
      return _buildEmptyState();
    }

    return RouteDetailWidget(
      route: route,
      onEdit: () {
        Navigator.pushNamed(context, '/admin/route-editor', arguments: route.id);
      },
      onDelete: () => _showDeleteRouteDialog(route),
      onPdfUpload: () => showPdfUploadDialog(context: context, ref: ref, route: route),
      onAddModule: () => _showAddModuleDialog(route.id),
    );
  }

  // ===== MODULE DETAIL =====

  Widget _buildModuleDetail(AdminState admin) {
    final module = admin.selectedModule;
    if (module == null) {
      return _buildEmptyState();
    }

    final typeColor = _moduleTypeColor(module.moduleType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module info card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.scada.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.scada.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_moduleTypeIcon(module.moduleType), size: 18, color: typeColor),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        module.title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.scada.textPrimary),
                      ),
                    ),
                  ],
                ),

                if (module.description != null) ...[
                  SizedBox(height: 10),
                  Text(
                    module.description!,
                    style: TextStyle(fontSize: 13, color: context.scada.textSecondary, height: 1.5),
                  ),
                ],

                const SizedBox(height: 14),

                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildMetaChip(Icons.category, module.typeText, typeColor),
                    _buildMetaChip(Icons.timer_outlined, '${module.estimatedMinutes} dk', ScadaColors.cyan),
                    _buildMetaChip(Icons.sort, 'Sira: ${module.sortOrder}', context.scada.textSecondary),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin/module-editor', arguments: {'routeId': module.routeId, 'moduleId': module.id});
                      },
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Düzenle', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScadaColors.cyan.withValues(alpha: 0.12),
                        foregroundColor: ScadaColors.cyan,
                        side: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showDeleteModuleDialog(module),
                      icon: const Icon(Icons.delete_outline, size: 14),
                      label: const Text('Sil', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScadaColors.red.withValues(alpha: 0.12),
                        foregroundColor: ScadaColors.red,
                        side: BorderSide(color: ScadaColors.red.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Contents section
          Row(
            children: [
              const Icon(Icons.description, size: 16, color: ScadaColors.cyan),
              SizedBox(width: 8),
              Text(
                'İçerikler (${module.contents?.length ?? 0})',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (module.contents == null || module.contents!.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.scada.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.scada.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 32, color: context.scada.textDim),
                    SizedBox(height: 8),
                    Text('Henuz içerik eklenmemis', style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
                  ],
                ),
              ),
            )
          else
            ...module.contents!.map((content) => _buildContentCard(content)),

          // Quiz section
          if (module.quizzes != null && module.quizzes!.isNotEmpty) ...[
            SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.quiz, size: 16, color: ScadaColors.amber),
                SizedBox(width: 8),
                Text(
                  'Quizler (${module.quizzes!.length})',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.scada.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...module.quizzes!.map((quiz) => _buildQuizCard(quiz)),
          ],
        ],
      ),
    );
  }

  Future<void> _showVersionHistory(String contentId) async {
    final dio = ref.read(authDioProvider);
    try {
      final response = await dio.get('/training/contents/$contentId/versions');
      final versions = response.data as List;
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: context.scada.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Icon(Icons.history, size: 18, color: ScadaColors.purple),
              const SizedBox(width: 8),
              Text('Versiyon Gecmisi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
            ]),
            const SizedBox(height: 12),
            if (versions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Henuz versiyon gecmisi yok', style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: versions.length,
                  itemBuilder: (_, i) {
                    final v = versions[i] as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.scada.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.scada.border),
                      ),
                      child: Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: ScadaColors.purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                          child: Center(child: Text('v${v['version_number']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ScadaColors.purple))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(v['title'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.scada.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (v['change_note'] != null)
                            Text(v['change_note'], style: TextStyle(fontSize: 10, color: context.scada.textDim)),
                          Text(v['created_at']?.toString().substring(0, 10) ?? '', style: TextStyle(fontSize: 9, color: context.scada.textDim)),
                        ])),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            try {
                              await dio.post('/training/contents/$contentId/rollback/${v['id']}');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('v${v['version_number']} versiyonuna geri donuldu'), backgroundColor: ScadaColors.green));
                              }
                            } catch (_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geri donus başarısız'), backgroundColor: ScadaColors.red));
                              }
                            }
                          },
                          child: const Text('Geri Al', style: TextStyle(fontSize: 10, color: ScadaColors.orange)),
                        ),
                      ]),
                    );
                  },
                ),
              ),
          ]),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Versiyon gecmisi yüklenemedi'), backgroundColor: ScadaColors.red));
      }
    }
  }

  Widget _buildContentCard(ModuleContent content) {
    final contentTypeIcon = _contentTypeIcon(content.contentType);
    final contentTypeColor = _contentTypeColor(content.contentType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.scada.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(contentTypeIcon, size: 16, color: contentTypeColor),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(content.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
                      const SizedBox(height: 2),
                      Text(content.contentType.toUpperCase(), style: TextStyle(fontSize: 10, color: contentTypeColor)),
                    ],
                  ),
                ),
                // RAG status for PDFs
                if (content.isPdf && content.ragStatus != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: content.ragStatus == 'indexed' ? ScadaColors.green : ScadaColors.amber,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    content.ragStatus == 'indexed' ? 'RAG' : 'Bekleniyor',
                    style: TextStyle(
                      fontSize: 9,
                      color: content.ragStatus == 'indexed' ? ScadaColors.green : ScadaColors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text('Sira: ${content.sortOrder}', style: TextStyle(fontSize: 9, color: context.scada.textDim)),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _showVersionHistory(content.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: ScadaColors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.history, size: 12, color: ScadaColors.purple),
                      SizedBox(width: 2),
                      Text('Gecmis', style: TextStyle(fontSize: 9, color: ScadaColors.purple, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ),
            // PDF tags
            if (content.isPdf && content.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: content.tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: ScadaColors.cyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(tag, style: const TextStyle(fontSize: 9, color: ScadaColors.cyan)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.scada.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.scada.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.quiz, size: 16, color: ScadaColors.amber),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quiz.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text('Gecme: %${quiz.passingScore}', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
                      SizedBox(width: 10),
                      Text('Deneme: ${quiz.maxAttempts}', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
                      if (quiz.timeLimitMinutes != null) ...[
                        SizedBox(width: 10),
                        Text('${quiz.timeLimitMinutes} dk', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== DIALOGS =====

  void _showRouteActions(TrainingRoute route) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.scada.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              const Icon(Icons.route, color: ScadaColors.cyan, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(route.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.scada.textPrimary), overflow: TextOverflow.ellipsis)),
            ]),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit, color: ScadaColors.cyan, size: 20),
            title: Text('Rotayi Düzenle', style: TextStyle(fontSize: 13, color: context.scada.textPrimary)),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/admin/route-editor', arguments: {'routeId': route.id});
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: ScadaColors.red, size: 20),
            title: const Text('Rotayi Sil', style: TextStyle(fontSize: 13, color: ScadaColors.red)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDeleteRoute(route);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _confirmDeleteRoute(TrainingRoute route) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rotayi Sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        content: Text(
          '"${route.title}" rotası ve içindeki tum modüller silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
          style: TextStyle(fontSize: 13, color: context.scada.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: context.scada.textDim)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(adminProvider.notifier).deleteRoute(route.id);
              if (mounted) {
                if (success) {
                  if (_selectedId == route.id) {
                    setState(() { _selectedType = null; _selectedId = null; });
                  }
                  _refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rota silindi'), backgroundColor: ScadaColors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ref.read(adminProvider).error ?? 'Silme hatasi'), backgroundColor: ScadaColors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDepartment(Department dept) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Departmani Sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        content: Text(
          '"${dept.name}" departmanı ve içindeki tum rotalar/modüller silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
          style: TextStyle(fontSize: 13, color: context.scada.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: context.scada.textDim)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(adminProvider.notifier).deleteDepartment(dept.id);
              if (mounted) {
                if (success) {
                  setState(() { _expandedDepartments.remove(dept.id); });
                  _refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Departman silindi'), backgroundColor: ScadaColors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ref.read(adminProvider).error ?? 'Silme hatasi'), backgroundColor: ScadaColors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showAddDepartmentDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.scada.borderBright),
        ),
        title: Text('Yeni Departman Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: TextStyle(color: context.scada.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Departman Adi',
                  labelStyle: TextStyle(color: context.scada.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.borderBright)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Departman adi gerekli' : null,
                onChanged: (v) {
                  // Auto-generate code from name
                  codeController.text = v.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeController,
                style: TextStyle(color: context.scada.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Kod (otomatik)',
                  labelStyle: TextStyle(color: context.scada.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.borderBright)),
                  helperText: 'Benzersiz kisaltma kodu',
                  helperStyle: TextStyle(color: context.scada.textDim, fontSize: 10),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Kod gerekli' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: context.scada.textDim)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final success = await ref.read(adminProvider.notifier).createDepartment(
                name: nameController.text.trim(),
                code: codeController.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Departman oluşturuldu' : (ref.read(adminProvider).error ?? 'Hata')),
                    backgroundColor: success ? ScadaColors.green : ScadaColors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.cyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAddRouteDialog(Department dept) {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.scada.borderBright),
        ),
        title: Text('Yeni Rota Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Departman: ${dept.name}', style: TextStyle(fontSize: 12, color: context.scada.textSecondary)),
              SizedBox(height: 14),
              TextFormField(
                controller: titleController,
                style: TextStyle(fontSize: 13, color: context.scada.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Rota Adi',
                  labelStyle: TextStyle(fontSize: 12, color: context.scada.textSecondary),
                  filled: true,
                  fillColor: context.scada.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.scada.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.scada.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.5)),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Rota adi zorunlu' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: context.scada.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                final success = await ref.read(adminProvider.notifier).createRoute({
                  'department_id': dept.id,
                  'title': titleController.text.trim(),
                });
                if (success && mounted) {
                  ref.read(adminProvider.notifier).loadRoutes(departmentId: dept.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rota oluşturuldu'), backgroundColor: context.scada.surface),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.cyan.withValues(alpha: 0.15),
              foregroundColor: ScadaColors.cyan,
            ),
            child: const Text('Oluştur', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showAddModuleDialog(String routeId) {
    final titleController = TextEditingController();
    String selectedType = 'lesson';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.scada.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.scada.borderBright),
          ),
          title: Text('Yeni Modül Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  style: TextStyle(fontSize: 13, color: context.scada.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Modül Adi',
                    labelStyle: TextStyle(fontSize: 12, color: context.scada.textSecondary),
                    filled: true,
                    fillColor: context.scada.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.scada.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.scada.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.5)),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Modül adi zorunlu' : null,
                ),
                SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  dropdownColor: context.scada.surface,
                  style: TextStyle(fontSize: 13, color: context.scada.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Modül Tipi',
                    labelStyle: TextStyle(fontSize: 12, color: context.scada.textSecondary),
                    filled: true,
                    fillColor: context.scada.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.scada.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.scada.border),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'lesson', child: Text('Ders')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                    DropdownMenuItem(value: 'practice', child: Text('Uygulama')),
                    DropdownMenuItem(value: 'assessment', child: Text('Degerlendirme')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal', style: TextStyle(color: context.scada.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx);
                  final success = await ref.read(adminProvider.notifier).createModule({
                    'route_id': routeId,
                    'title': titleController.text.trim(),
                    'module_type': selectedType,
                  });
                  if (success && mounted) {
                    ref.read(adminProvider.notifier).loadRouteDetail(routeId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Modül oluşturuldu'), backgroundColor: context.scada.surface),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ScadaColors.cyan.withValues(alpha: 0.15),
                foregroundColor: ScadaColors.cyan,
              ),
              child: const Text('Oluştur', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteRouteDialog(TrainingRoute route) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.scada.borderBright),
        ),
        title: const Text('Rota Sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.red)),
        content: Text(
          '"${route.title}" rotasını silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz ve rotaya bagli tum modüller de silinir.',
          style: TextStyle(fontSize: 13, color: context.scada.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: context.scada.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(adminProvider.notifier).deleteRoute(route.id);
              if (success && mounted) {
                setState(() {
                  _selectedType = null;
                  _selectedId = null;
                });
                ref.read(adminProvider.notifier).loadRoutes(departmentId: route.departmentId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Rota silindi'), backgroundColor: context.scada.surface),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.red.withValues(alpha: 0.15),
              foregroundColor: ScadaColors.red,
            ),
            child: const Text('Sil', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showDeleteModuleDialog(TrainingModule module) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.scada.borderBright),
        ),
        title: const Text('Modül Sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.red)),
        content: Text(
          '"${module.title}" modülünu silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
          style: TextStyle(fontSize: 13, color: context.scada.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: context.scada.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(adminProvider.notifier).deleteModule(module.id);
              if (success && mounted) {
                setState(() {
                  _selectedType = null;
                  _selectedId = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Modül silindi'), backgroundColor: context.scada.surface),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.red.withValues(alpha: 0.15),
              foregroundColor: ScadaColors.red,
            ),
            child: const Text('Sil', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ===== HELPERS =====

  Widget _buildMetaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _moduleTypeColor(String type) {
    switch (type) {
      case 'lesson':
        return ScadaColors.cyan;
      case 'video':
        return ScadaColors.purple;
      case 'practice':
        return ScadaColors.green;
      case 'assessment':
        return ScadaColors.amber;
      default:
        return context.scada.textSecondary;
    }
  }

  IconData _moduleTypeIcon(String type) {
    switch (type) {
      case 'lesson':
        return Icons.menu_book;
      case 'video':
        return Icons.play_circle_outline;
      case 'practice':
        return Icons.build_outlined;
      case 'assessment':
        return Icons.assignment;
      default:
        return Icons.article;
    }
  }

  IconData _contentTypeIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'link':
        return Icons.link;
      default:
        return Icons.description;
    }
  }

  Color _contentTypeColor(String type) {
    switch (type) {
      case 'text':
        return context.scada.textSecondary;
      case 'image':
        return ScadaColors.green;
      case 'video':
        return ScadaColors.purple;
      case 'pdf':
        return ScadaColors.red;
      case 'link':
        return ScadaColors.cyan;
      default:
        return context.scada.textDim;
    }
  }
}
