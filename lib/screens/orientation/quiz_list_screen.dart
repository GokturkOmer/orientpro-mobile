import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../providers/admin_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/role_helper.dart';
import '../../models/training.dart';
import '../../core/utils/status_helper.dart';
import '../../core/utils/turkish_string.dart';

class QuizListScreen extends ConsumerStatefulWidget {
  const QuizListScreen({super.key});

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen> {
  bool _loaded = false;
  String _searchQuery = '';
  String? _selectedDeptFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadData();
    }
  }

  void _loadData() {
    Future.microtask(() {
      final auth = ref.read(authProvider);
      final notifier = ref.read(trainingProvider.notifier);
      notifier.loadQuizzes();
      if (auth.user != null) {
        notifier.loadUserQuizResults(auth.user!.id);
      }
    });
  }

  bool get _isAdmin {
    final role = ref.read(authProvider).user?.role ?? '';
    return ['admin', 'facility_manager', 'chief_technician'].contains(role);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final training = ref.watch(trainingProvider);
    final userRole = auth.user?.role ?? '';
    final userDept = auth.user?.department;

    // RBAC: departman filtreleme
    final allowedDepts = RoleHelper.visibleDepartments(userRole, userDept);

    // Quizleri filtrele
    var quizzes = training.quizList.where((q) => q.isActive).toList();

    if (allowedDepts != null) {
      quizzes = quizzes.where((q) {
        if (q.departmentCode == null) return true;
        return allowedDepts.contains(q.departmentCode);
      }).toList();
    }

    // Admin departman filtresi
    if (_isAdmin && _selectedDeptFilter != null) {
      quizzes = quizzes.where((q) {
        return q.departmentCode == _selectedDeptFilter ||
            q.departmentName == _selectedDeptFilter;
      }).toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      quizzes = quizzes.where((q) =>
        q.title.toTurkishLowerCase().contains(_searchQuery) ||
        (q.departmentName?.toTurkishLowerCase().contains(_searchQuery) ?? false)
      ).toList();
    }

    // Tarihe gore sirala (en yeni uste)
    quizzes.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

    // Departman listesi (filtre icin)
    final deptSet = <String>{};
    for (final q in training.quizList) {
      if (q.departmentName != null && q.departmentName!.isNotEmpty) {
        deptSet.add(q.departmentName!);
      }
    }

    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.scada.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Quiz & Sinavlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
      ),
      body: training.isLoading
          ? const Center(child: CircularProgressIndicator(color: ScadaColors.green))
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Quiz ara...',
                    hintStyle: TextStyle(color: context.scada.textDim, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: context.scada.textDim, size: 20),
                    filled: true,
                    fillColor: context.scada.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.scada.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.scada.border)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: TextStyle(color: context.scada.textPrimary, fontSize: 13),
                  onChanged: (v) => setState(() => _searchQuery = v.toTurkishLowerCase()),
                ),
              ),
              // Admin departman filtre chip'leri
              if (_isAdmin && deptSet.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterChip('Tumu', _selectedDeptFilter == null, () {
                        setState(() => _selectedDeptFilter = null);
                      }),
                      ...deptSet.map((dept) => _buildFilterChip(
                        dept,
                        _selectedDeptFilter == dept,
                        () => setState(() => _selectedDeptFilter = _selectedDeptFilter == dept ? null : dept),
                      )),
                    ],
                  ),
                ),
              Expanded(
                child: quizzes.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: quizzes.length,
                        itemBuilder: (context, index) {
                          return _buildQuizCard(quizzes[index], training.quizResults);
                        },
                      ),
              ),
            ]),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateQuizDialog(),
              backgroundColor: ScadaColors.cyan,
              icon: Icon(Icons.auto_awesome, color: context.scada.bg),
              label: Text('AI Quiz', style: TextStyle(color: context.scada.bg, fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: selected ? context.scada.bg : context.scada.textSecondary)),
        selected: selected,
        selectedColor: ScadaColors.cyan,
        backgroundColor: context.scada.card,
        side: BorderSide(color: selected ? ScadaColors.cyan : context.scada.border),
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.quiz_outlined, size: 48, color: context.scada.textDim),
        const SizedBox(height: 12),
        Text('Henuz quiz bulunmuyor', style: TextStyle(fontSize: 14, color: context.scada.textSecondary)),
        const SizedBox(height: 4),
        Text('Egitim rotalarina quiz eklendikce burada gorunecek', style: TextStyle(fontSize: 11, color: context.scada.textDim)),
      ]),
    );
  }

  Widget _buildQuizCard(QuizListItem item, List<QuizResult> results) {
    // Son sonucu bul
    final quizResults = results.where((r) => r.quizId == item.id).toList();
    quizResults.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final lastResult = quizResults.isNotEmpty ? quizResults.first : null;

    // Durum
    final qs = StatusHelper.quizStatus(
      passed: lastResult?.passed,
      percent: lastResult?.percent,
    );

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/quiz', arguments: item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.scada.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.scada.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Baslik + durum + silme
          Row(children: [
            Expanded(
              child: Text(item.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.scada.textPrimary)),
            ),
            Icon(qs.icon, size: 18, color: qs.color),
            const SizedBox(width: 4),
            Text(qs.text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: qs.color)),
            if (_isAdmin) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmDeleteQuiz(item),
                child: const Icon(Icons.delete_outline, size: 18, color: ScadaColors.red),
              ),
            ],
          ]),
          const SizedBox(height: 6),

          // Departman + Tarih
          Row(children: [
            if (item.departmentName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: ScadaColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(item.departmentName!, style: const TextStyle(fontSize: 9, color: ScadaColors.cyan, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
            ],
            if (item.createdAt != null)
              Text(
                _formatDate(item.createdAt!),
                style: TextStyle(fontSize: 10, color: context.scada.textDim),
              ),
          ]),
          const SizedBox(height: 8),

          // Alt bilgi
          Row(children: [
            _buildDifficultyChip(item.passingScore),
            const SizedBox(width: 10),
            _buildInfoChip(Icons.repeat, 'Maks ${item.maxAttempts} deneme'),
            if (item.timeLimitMinutes != null) ...[
              const SizedBox(width: 10),
              _buildInfoChip(Icons.timer_outlined, '${item.timeLimitMinutes} dk'),
            ],
            if (quizResults.isNotEmpty) ...[
              const SizedBox(width: 10),
              _buildInfoChip(Icons.history, '${quizResults.length} deneme'),
            ],
          ]),
        ]),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _confirmDeleteQuiz(QuizListItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scada.card,
        title: Text('Quiz Sil', style: TextStyle(color: context.scada.textPrimary, fontSize: 16)),
        content: Text(
          "'${item.title}' quizini ve tum sorularini silmek istediginize emin misiniz?",
          style: TextStyle(color: context.scada.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Iptal', style: TextStyle(color: context.scada.textDim)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final admin = ref.read(adminProvider.notifier);
              final success = await admin.deleteQuizFull(item.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quiz silindi'), backgroundColor: ScadaColors.green),
                );
                _loadData(); // Listeyi yenile
              }
            },
            child: const Text('Sil', style: TextStyle(color: ScadaColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showCreateQuizDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.scada.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _CreateQuizSheet(
          onCreated: () {
            _loadData();
          },
          scrollController: scrollController,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: context.scada.textDim),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 9, color: context.scada.textDim)),
    ]);
  }

  Widget _buildDifficultyChip(int passingScore) {
    final String label;
    final Color color;
    if (passingScore >= 80) {
      label = 'Zor';
      color = ScadaColors.red;
    } else if (passingScore >= 60) {
      label = 'Orta';
      color = ScadaColors.amber;
    } else {
      label = 'Kolay';
      color = ScadaColors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.signal_cellular_alt, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ========== AI QUIZ OLUSTUR POPUP ==========

class _CreateQuizSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  final ScrollController? scrollController;
  const _CreateQuizSheet({required this.onCreated, this.scrollController});

  @override
  ConsumerState<_CreateQuizSheet> createState() => _CreateQuizSheetState();
}

class _CreateQuizSheetState extends ConsumerState<_CreateQuizSheet> {
  String? _selectedDept;
  List<Map<String, dynamic>> _documents = [];
  final Set<String> _selectedDocIds = {};
  int _questionCount = 10;
  String _difficulty = 'orta';
  final _titleController = TextEditingController();
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  // Departman listesi
  final List<Map<String, String>> _departments = [
    {'code': 'teknik', 'name': 'Teknik Servis'},
    {'code': 'hk', 'name': 'Kat Hizmetleri'},
    {'code': 'on_buro', 'name': 'On Buro'},
    {'code': 'fb', 'name': 'Yiyecek & Icecek'},
    {'code': 'spa', 'name': 'SPA & Wellness'},
    {'code': 'guvenlik', 'name': 'Guvenlik'},
    {'code': 'genel', 'name': 'Genel'},
  ];

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _documents = [];
      _selectedDocIds.clear();
    });

    final admin = ref.read(adminProvider.notifier);
    // Tum indexlenmis dokumanlari getir
    final docs = await admin.loadAllIndexedDocuments();

    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  Future<void> _generateQuiz() async {
    if (_selectedDocIds.isEmpty) {
      setState(() => _error = 'En az 1 dokuman secin');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Quiz basligi girin');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    final admin = ref.read(adminProvider.notifier);

    // Doc ID'leri doc_id formatinda gonder (ChromaDB doc_id)
    final docIds = _selectedDocIds.toList();

    final result = await admin.generateQuizFromDocs(
      docIds: docIds,
      questionCount: _questionCount,
      difficulty: _difficulty,
      departmentCode: _selectedDept ?? 'genel',
      title: _titleController.text.trim(),
    );

    if (mounted) {
      setState(() => _isGenerating = false);

      if (result != null) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz olusturuldu! ${result['question_count']} soru (${result['verified_count']} dogrulandi)'),
            backgroundColor: ScadaColors.green,
          ),
        );
      } else {
        setState(() => _error = ref.read(adminProvider).error ?? 'Quiz olusturulamadi');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Baslik
          Row(children: [
            const Icon(Icons.auto_awesome, color: ScadaColors.cyan, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text('AI ile Quiz Olustur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
            ),
            IconButton(
              icon: Icon(Icons.close, color: context.scada.textDim, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
          const SizedBox(height: 16),

          // 1. Departman secimi
          Text('Departman', style: TextStyle(fontSize: 12, color: context.scada.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedDept,
            decoration: InputDecoration(
              hintText: 'Departman secin',
              hintStyle: TextStyle(fontSize: 13, color: context.scada.textDim),
              filled: true,
              fillColor: context.scada.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            dropdownColor: context.scada.surface,
            style: TextStyle(color: context.scada.textPrimary, fontSize: 13),
            items: _departments.map((d) => DropdownMenuItem(
              value: d['code'],
              child: Text(d['name']!),
            )).toList(),
            onChanged: (v) {
              setState(() {
                _selectedDept = v;
                _selectedDocIds.clear();
              });
              // Otomatik baslik oner
              if (v != null && _titleController.text.isEmpty) {
                final deptName = _departments.firstWhere((d) => d['code'] == v)['name']!;
                _titleController.text = '$deptName Quiz';
              }
            },
          ),
          const SizedBox(height: 16),

          // 2. Dokuman secimi
          Text('Dokumanlar', style: TextStyle(fontSize: 12, color: context.scada.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: ScadaColors.cyan, strokeWidth: 2),
            ))
          else if (_documents.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.scada.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.scada.border),
              ),
              child: Text(
                'Indexlenmis dokuman bulunamadi. Once Dokuman Havuzu\'na PDF yukleyin.',
                style: TextStyle(fontSize: 11, color: context.scada.textDim),
              ),
            )
          else
            Builder(builder: (_) {
              // Departmana gore filtrele
              final filteredDocs = _selectedDept == null
                  ? _documents
                  : _documents.where((doc) {
                      String docDept = '';
                      if (doc['classification'] is Map) {
                        docDept = (doc['classification'] as Map)['department']?.toString() ?? '';
                      }
                      return docDept == _selectedDept || docDept.isEmpty;
                    }).toList();

              if (filteredDocs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.scada.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.scada.border),
                  ),
                  child: Text(
                    _selectedDept != null
                        ? 'Bu departmanda indexlenmis dokuman yok'
                        : 'Indexlenmis dokuman bulunamadi',
                    style: TextStyle(fontSize: 11, color: context.scada.textDim),
                  ),
                );
              }

              return Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: context.scada.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.scada.border),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredDocs.length,
                itemBuilder: (ctx, i) {
                  final doc = filteredDocs[i];
                  final docId = _getDocId(doc);
                  final title = doc['title'] ?? doc['file_name'] ?? 'Dokuman';
                  final isSelected = _selectedDocIds.contains(docId);
                  String dept = '';
                  if (doc['classification'] is Map) {
                    dept = (doc['classification'] as Map)['department']?.toString() ?? '';
                  } else if (doc['metadata_json'] is Map) {
                    final meta = doc['metadata_json'] as Map;
                    if (meta['classification'] is Map) {
                      dept = (meta['classification'] as Map)['department']?.toString() ?? '';
                    }
                  }

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedDocIds.add(docId);
                        } else {
                          _selectedDocIds.remove(docId);
                        }
                      });
                    },
                    title: Text(title, style: TextStyle(fontSize: 12, color: context.scada.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      dept,
                      style: TextStyle(fontSize: 10, color: context.scada.textDim),
                    ),
                    dense: true,
                    activeColor: ScadaColors.cyan,
                    checkColor: context.scada.bg,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                },
              ),
            );
            }),
          if (_selectedDocIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${_selectedDocIds.length} dokuman secildi', style: const TextStyle(fontSize: 10, color: ScadaColors.cyan)),
            ),
          const SizedBox(height: 16),

          // 3. Soru sayisi ve zorluk
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Soru Sayisi', style: TextStyle(fontSize: 12, color: context.scada.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: _questionCount,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.scada.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  dropdownColor: context.scada.surface,
                  style: TextStyle(color: context.scada.textPrimary, fontSize: 13),
                  items: [5, 10, 15, 20].map((n) => DropdownMenuItem(value: n, child: Text('$n soru'))).toList(),
                  onChanged: (v) => setState(() => _questionCount = v ?? 10),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Zorluk', style: TextStyle(fontSize: 12, color: context.scada.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _difficulty,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.scada.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  dropdownColor: context.scada.surface,
                  style: TextStyle(color: context.scada.textPrimary, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'kolay', child: Text('Kolay')),
                    DropdownMenuItem(value: 'orta', child: Text('Orta')),
                    DropdownMenuItem(value: 'zor', child: Text('Zor')),
                  ],
                  onChanged: (v) => setState(() => _difficulty = v ?? 'orta'),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 16),

          // 4. Quiz basligi
          Text('Quiz Basligi', style: TextStyle(fontSize: 12, color: context.scada.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Quiz basligini girin',
              hintStyle: TextStyle(fontSize: 13, color: context.scada.textDim),
              filled: true,
              fillColor: context.scada.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.scada.border)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: TextStyle(color: context.scada.textPrimary, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Hata mesaji
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: ScadaColors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: const TextStyle(fontSize: 11, color: ScadaColors.red)),
            ),

          // Olustur butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: ScadaColors.cyan,
                foregroundColor: context.scada.bg,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isGenerating
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: context.scada.bg))
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'Quiz olusturuluyor...' : 'Quiz Olustur',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'AI sorulari olusturuyor ve dogruluyor... Bu islem 30-60 saniye surebilir.',
                style: TextStyle(fontSize: 10, color: context.scada.textDim),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
        ]),
        ],
      ),
    );
  }

  String _getDocId(Map<String, dynamic> doc) {
    // rag_doc_id direkt response'ta (training/documents endpoint)
    if (doc.containsKey('rag_doc_id') && doc['rag_doc_id'] != null && doc['rag_doc_id'].toString().isNotEmpty) {
      return doc['rag_doc_id'].toString();
    }
    // documents-by-department endpoint'inden gelen doc icin
    if (doc.containsKey('doc_id')) {
      return doc['doc_id'].toString();
    }
    // metadata_json icinde rag_doc_id
    final meta = doc['metadata_json'];
    if (meta is Map) {
      if (meta.containsKey('rag_doc_id') && meta['rag_doc_id'] != null) {
        return meta['rag_doc_id'].toString();
      }
    }
    // Fallback: id kullan
    return doc['id']?.toString() ?? '';
  }
}
