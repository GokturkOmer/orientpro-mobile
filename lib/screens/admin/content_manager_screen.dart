import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/role_helper.dart';
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
  String? _selectedType; // 'route' | 'module'
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
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Icerik Yonetimi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearchPanel ? Icons.search_off : Icons.search,
              color: _showSearchPanel ? ScadaColors.cyan : ScadaColors.textSecondary,
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
                Container(width: 1, color: ScadaColors.border),
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
      color: ScadaColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 18),
            onPressed: () => setState(() => _showLeftPanel = true),
            tooltip: 'Agaca don',
          ),
          const Text(
            'Icerik Agaci',
            style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ===== LEFT PANEL =====

  Widget _buildLeftPanel(AdminState admin, {VoidCallback? onSelect}) {
    return Container(
      color: ScadaColors.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ScadaColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_tree, color: ScadaColors.cyan, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Icerik Agaci',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary),
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    color: ScadaColors.textSecondary,
                    padding: EdgeInsets.zero,
                    onPressed: _refresh,
                    tooltip: 'Yenile',
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
                    // Departman filtreleme: sadece duzenlenebilir departmanlari goster
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
                            const Icon(Icons.folder_open, size: 36, color: ScadaColors.textDim),
                            const SizedBox(height: 8),
                            const Text(
                              'Departman bulunamadi',
                              style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary),
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
                  color: ScadaColors.textDim,
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: deptColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dept.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary),
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
              style: TextStyle(fontSize: 11, color: ScadaColors.textDim, fontStyle: FontStyle.italic),
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

    return InkWell(
      onTap: () {
        _selectRoute(route.id);
        onNarrowSelect?.call();
      },
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
              color: isSelected ? ScadaColors.cyan : ScadaColors.textDim,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? ScadaColors.cyan : ScadaColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
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
                      const SizedBox(width: 6),
                      Text(
                        '${route.modules?.length ?? 0} modul',
                        style: const TextStyle(fontSize: 9, color: ScadaColors.textDim),
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
                color: ScadaColors.textSecondary,
                padding: EdgeInsets.zero,
                onPressed: () => _showAddModuleDialog(route.id),
                tooltip: 'Modul ekle',
              ),
            ),
          ],
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

    if (_selectedType == 'module') {
      return _buildModuleDetail(admin);
    }

    return _buildEmptyState();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: ScadaColors.surface,
        border: Border(bottom: BorderSide(color: ScadaColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: ScadaColors.cyan),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Egitim dokumanlari icinde AI arama...',
                hintStyle: const TextStyle(fontSize: 12, color: ScadaColors.textDim),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: ScadaColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ScadaColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ScadaColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ScadaColors.cyan),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: ScadaColors.textSecondary),
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: ScadaColors.cyan, strokeWidth: 2),
            SizedBox(height: 12),
            Text('Semantik arama yapiliyor...', style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 40, color: ScadaColors.textDim),
            const SizedBox(height: 12),
            Text(
              '"${_searchController.text}" icin sonuc bulunamadi',
              style: const TextStyle(fontSize: 13, color: ScadaColors.textSecondary),
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
                const SizedBox(width: 6),
                Text(
                  '${_searchResults.length} sonuc bulundu',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary),
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
            color: ScadaColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ScadaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: source + score
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf, size: 14, color: ScadaColors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      source,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary),
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
                const SizedBox(height: 4),
                Text(
                  _departmentLabel(department),
                  style: const TextStyle(fontSize: 10, color: ScadaColors.textDim),
                ),
              ],
              const SizedBox(height: 8),
              // Content snippet
              Text(
                content.length > 300 ? '${content.substring(0, 300)}...' : content,
                style: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary, height: 1.5),
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
      'yonetim': 'Yonetim',
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
          Icon(Icons.touch_app, size: 56, color: ScadaColors.textDim.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Sol panelden bir oge secin',
            style: TextStyle(fontSize: 14, color: ScadaColors.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Departman, rota veya modul detaylarini goruntulemek icin\nagactan bir oge secin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: ScadaColors.textDim),
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
              color: ScadaColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ScadaColors.border),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        module.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary),
                      ),
                    ),
                  ],
                ),

                if (module.description != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    module.description!,
                    style: const TextStyle(fontSize: 13, color: ScadaColors.textSecondary, height: 1.5),
                  ),
                ],

                const SizedBox(height: 14),

                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildMetaChip(Icons.category, module.typeText, typeColor),
                    _buildMetaChip(Icons.timer_outlined, '${module.estimatedMinutes} dk', ScadaColors.cyan),
                    _buildMetaChip(Icons.sort, 'Sira: ${module.sortOrder}', ScadaColors.textSecondary),
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
                      label: const Text('Duzenle', style: TextStyle(fontSize: 12)),
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
              const SizedBox(width: 8),
              Text(
                'Icerikler (${module.contents?.length ?? 0})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (module.contents == null || module.contents!.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ScadaColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ScadaColors.border),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 32, color: ScadaColors.textDim),
                    SizedBox(height: 8),
                    Text('Henuz icerik eklenmemis', style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            ...module.contents!.map((content) => _buildContentCard(content)),

          // Quiz section
          if (module.quizzes != null && module.quizzes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.quiz, size: 16, color: ScadaColors.amber),
                const SizedBox(width: 8),
                Text(
                  'Quizler (${module.quizzes!.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary),
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

  Widget _buildContentCard(ModuleContent content) {
    final contentTypeIcon = _contentTypeIcon(content.contentType);
    final contentTypeColor = _contentTypeColor(content.contentType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(contentTypeIcon, size: 16, color: contentTypeColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(content.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
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
                Text('Sira: ${content.sortOrder}', style: const TextStyle(fontSize: 9, color: ScadaColors.textDim)),
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
        color: ScadaColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.quiz, size: 16, color: ScadaColors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quiz.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('Gecme: %${quiz.passingScore}', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
                      const SizedBox(width: 10),
                      Text('Deneme: ${quiz.maxAttempts}', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
                      if (quiz.timeLimitMinutes != null) ...[
                        const SizedBox(width: 10),
                        Text('${quiz.timeLimitMinutes} dk', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
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

  void _showAddRouteDialog(Department dept) {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ScadaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ScadaColors.borderBright),
        ),
        title: const Text('Yeni Rota Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Departman: ${dept.name}', style: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary)),
              const SizedBox(height: 14),
              TextFormField(
                controller: titleController,
                style: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Rota Adi',
                  labelStyle: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary),
                  filled: true,
                  fillColor: ScadaColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: ScadaColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: ScadaColors.border),
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
            child: const Text('Iptal', style: TextStyle(color: ScadaColors.textSecondary)),
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
                    const SnackBar(content: Text('Rota olusturuldu'), backgroundColor: ScadaColors.surface),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.cyan.withValues(alpha: 0.15),
              foregroundColor: ScadaColors.cyan,
            ),
            child: const Text('Olustur', style: TextStyle(fontSize: 12)),
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
          backgroundColor: ScadaColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ScadaColors.borderBright),
          ),
          title: const Text('Yeni Modul Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  style: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Modul Adi',
                    labelStyle: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary),
                    filled: true,
                    fillColor: ScadaColors.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: ScadaColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: ScadaColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.5)),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Modul adi zorunlu' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  dropdownColor: ScadaColors.surface,
                  style: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Modul Tipi',
                    labelStyle: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary),
                    filled: true,
                    fillColor: ScadaColors.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: ScadaColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: ScadaColors.border),
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
              child: const Text('Iptal', style: TextStyle(color: ScadaColors.textSecondary)),
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
                      const SnackBar(content: Text('Modul olusturuldu'), backgroundColor: ScadaColors.surface),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ScadaColors.cyan.withValues(alpha: 0.15),
                foregroundColor: ScadaColors.cyan,
              ),
              child: const Text('Olustur', style: TextStyle(fontSize: 12)),
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
        backgroundColor: ScadaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ScadaColors.borderBright),
        ),
        title: const Text('Rota Sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.red)),
        content: Text(
          '"${route.title}" rotasini silmek istediginize emin misiniz?\n\nBu islem geri alinamaz ve rotaya bagli tum moduller de silinir.',
          style: const TextStyle(fontSize: 13, color: ScadaColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Iptal', style: TextStyle(color: ScadaColors.textSecondary)),
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
                  const SnackBar(content: Text('Rota silindi'), backgroundColor: ScadaColors.surface),
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
        backgroundColor: ScadaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ScadaColors.borderBright),
        ),
        title: const Text('Modul Sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ScadaColors.red)),
        content: Text(
          '"${module.title}" modulunu silmek istediginize emin misiniz?\n\nBu islem geri alinamaz.',
          style: const TextStyle(fontSize: 13, color: ScadaColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Iptal', style: TextStyle(color: ScadaColors.textSecondary)),
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
                  const SnackBar(content: Text('Modul silindi'), backgroundColor: ScadaColors.surface),
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
        return ScadaColors.textSecondary;
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
        return ScadaColors.textSecondary;
      case 'image':
        return ScadaColors.green;
      case 'video':
        return ScadaColors.purple;
      case 'pdf':
        return ScadaColors.red;
      case 'link':
        return ScadaColors.cyan;
      default:
        return ScadaColors.textDim;
    }
  }
}
