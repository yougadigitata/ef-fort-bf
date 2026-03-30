import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════════
// ADMIN SCREEN — EF-FORT.BF CMS v6.0
// Toutes les fonctionnalités CMS intégrées dans l'application
// ══════════════════════════════════════════════════════════════

const String _cmsBase = 'https://ef-fort-bf.yembuaro29.workers.dev/api/admin-cms';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {};
  List<dynamic> _demandes = [];
  bool _loadingStats = true;
  bool _loadingDemandes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingStats = true;
      _loadingDemandes = true;
    });
    final statsResult = await ApiService.getAdminStats();
    final demandes = await ApiService.getDemandesAbonnement();
    if (mounted) {
      setState(() {
        if (statsResult['stats'] != null) {
          _stats = statsResult['stats'] as Map<String, dynamic>;
        } else {
          _stats = statsResult;
        }
        _demandes = demandes;
        _loadingStats = false;
        _loadingDemandes = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Administration'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.red, Color(0xFF8B0000)]),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Stats', icon: Icon(Icons.bar_chart_rounded, size: 18)),
            Tab(text: 'Demandes', icon: Icon(Icons.pending_actions_rounded, size: 18)),
            Tab(text: 'Publier', icon: Icon(Icons.add_circle_outline_rounded, size: 18)),
            Tab(text: 'CMS QCM', icon: Icon(Icons.quiz_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildDemandesTab(),
          _buildAddTab(),
          const CmsQcmTab(),
        ],
      ),
    );
  }

  // ── Onglet Stats ──────────────────────────────────────────────
  Widget _buildStatsTab() {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tableau de bord', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(children: [
              _buildStatCard('Utilisateurs', '${_stats['totalUsers'] ?? _stats['total_users'] ?? 0}', Icons.people_rounded, AppColors.primary),
              const SizedBox(width: 12),
              _buildStatCard('Abonnés', '${_stats['abonnes'] ?? _stats['total_abonnes'] ?? 0}', Icons.workspace_premium_rounded, AppColors.secondary),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _buildStatCard('Questions', '${_stats['totalQuestions'] ?? _stats['total_questions'] ?? 0}', Icons.quiz_rounded, Colors.blue),
              const SizedBox(width: 12),
              _buildStatCard('Simulations', '${_stats['totalSimulations'] ?? _stats['total_sessions'] ?? 0}', Icons.timer_rounded, Colors.orange),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _buildStatCard('Demandes', '${_stats['demandesEnAttente'] ?? _stats['demandes_en_attente'] ?? 0}', Icons.pending_rounded, AppColors.red),
              const SizedBox(width: 12),
              _buildStatCard('Actualités', '${_stats['totalActualites'] ?? _stats['total_actualites'] ?? 0}', Icons.newspaper_rounded, Colors.teal),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ]),
      ),
    );
  }

  // ── Onglet Demandes ───────────────────────────────────────────
  Widget _buildDemandesTab() {
    if (_loadingDemandes) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_demandes.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_rounded, size: 64, color: AppColors.textLight.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Aucune demande en attente', style: TextStyle(color: AppColors.textLight, fontSize: 16)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _demandes.length,
        itemBuilder: (context, index) {
          final d = _demandes[index] as Map<String, dynamic>;
          final statut = (d['statut'] ?? 'EN_ATTENTE').toString();
          final isEnAttente = statut == 'EN_ATTENTE';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: isEnAttente ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                child: Icon(
                  isEnAttente ? Icons.pending_rounded : Icons.check_circle_rounded,
                  color: isEnAttente ? AppColors.secondary : AppColors.success,
                ),
              ),
              title: Text(d['nom_complet'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['telephone'] ?? '', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                Text('Paiement: ${d['moyen_paiement'] ?? ''}', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                Text('Statut: $statut', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isEnAttente ? AppColors.secondary : AppColors.success)),
              ]),
              trailing: isEnAttente
                  ? IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
                      onPressed: () async {
                        final id = d['id']?.toString();
                        if (id == null) return;
                        final result = await ApiService.validerAbonnement(id);
                        if (result['success'] == true) {
                          _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Abonnement validé !'), backgroundColor: AppColors.success),
                            );
                          }
                        }
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  // ── Onglet Publier ────────────────────────────────────────────
  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _buildAddCard('Ajouter une question rapide', Icons.quiz_rounded, AppColors.primary, () => _showAddQuestionDialog()),
        const SizedBox(height: 12),
        _buildAddCard('Publier une actualité', Icons.newspaper_rounded, AppColors.secondary, () => _showAddActualiteDialog()),
      ]),
    );
  }

  Widget _buildAddCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark))),
          Icon(Icons.add_circle_rounded, color: color, size: 28),
        ]),
      ),
    );
  }

  void _showAddQuestionDialog() {
    final matiereCtrl = TextEditingController(text: 'culture_generale');
    final questionCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    final bCtrl = TextEditingController();
    final cCtrl = TextEditingController();
    final dCtrl = TextEditingController();
    String bonneReponse = 'A';
    final expCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ajouter une question', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: matiereCtrl, decoration: const InputDecoration(labelText: 'Matière (ex: culture_generale)')),
              const SizedBox(height: 10),
              TextField(controller: questionCtrl, decoration: const InputDecoration(labelText: 'Question'), maxLines: 2),
              const SizedBox(height: 10),
              TextField(controller: aCtrl, decoration: const InputDecoration(labelText: 'Option A')),
              const SizedBox(height: 8),
              TextField(controller: bCtrl, decoration: const InputDecoration(labelText: 'Option B')),
              const SizedBox(height: 8),
              TextField(controller: cCtrl, decoration: const InputDecoration(labelText: 'Option C')),
              const SizedBox(height: 8),
              TextField(controller: dCtrl, decoration: const InputDecoration(labelText: 'Option D')),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (ctx2, setInnerState) => DropdownButtonFormField<String>(
                  initialValue: bonneReponse,
                  decoration: const InputDecoration(labelText: 'Bonne réponse'),
                  items: ['A', 'B', 'C', 'D'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setInnerState(() => bonneReponse = v!),
                ),
              ),
              const SizedBox(height: 10),
              TextField(controller: expCtrl, decoration: const InputDecoration(labelText: 'Explication'), maxLines: 2),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await ApiService.addQuestion({
                      'matiere': matiereCtrl.text,
                      'question': questionCtrl.text,
                      'option_a': aCtrl.text,
                      'option_b': bCtrl.text,
                      'option_c': cCtrl.text,
                      'option_d': dCtrl.text,
                      'bonne_reponse': bonneReponse,
                      'explication': expCtrl.text,
                    });
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (result['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Question ajoutée !'), backgroundColor: AppColors.success),
                      );
                    }
                  },
                  child: const Text('Ajouter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddActualiteDialog() {
    final titreCtrl = TextEditingController();
    final contenuCtrl = TextEditingController();
    String selectedColor = '#1A5C38';

    const colorOptions = [
      {'hex': '#1A5C38', 'label': 'Vert EF-FORT'},
      {'hex': '#6B21A8', 'label': 'Violet'},
      {'hex': '#D4A017', 'label': 'Or Burkina'},
      {'hex': '#CE1126', 'label': 'Rouge Faso'},
      {'hex': '#1D4ED8', 'label': 'Bleu Royal'},
      {'hex': '#0F766E', 'label': 'Teal'},
      {'hex': '#B45309', 'label': 'Orange'},
      {'hex': '#7C3AED', 'label': 'Violet Vif'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 4, height: 22, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  const Text('Publier une actualité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: titreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Titre de l\'actualité *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: AppColors.background,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contenuCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Contenu *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: AppColors.background,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Couleur de fond', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: colorOptions.length,
                    itemBuilder: (_, i) {
                      final opt = colorOptions[i];
                      final hexStr = opt['hex']!.replaceFirst('#', '');
                      final color = Color(int.parse('FF$hexStr', radix: 16));
                      final isSelected = selectedColor == opt['hex'];
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = opt['hex']!),
                        child: Container(
                          width: 44, height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                            boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : [],
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (titreCtrl.text.trim().isEmpty || contenuCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Titre et contenu requis'), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      final result = await ApiService.addActualite({
                        'titre': titreCtrl.text.trim(),
                        'contenu': contenuCtrl.text.trim(),
                        'couleur_fond': selectedColor,
                      });
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (result['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Actualité publiée !'), backgroundColor: AppColors.success),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['error']?.toString() ?? 'Erreur'), backgroundColor: AppColors.error),
                        );
                      }
                    },
                    child: const Text('Publier l\'actualité', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CMS QCM TAB — Gestion complète des questions
// ══════════════════════════════════════════════════════════════

class CmsQcmTab extends StatefulWidget {
  const CmsQcmTab({super.key});

  @override
  State<CmsQcmTab> createState() => _CmsQcmTabState();
}

class _CmsQcmTabState extends State<CmsQcmTab> {
  int _selectedSection = 0; // 0=dashboard, 1=questions, 2=import, 3=séries, 4=simulations

  final List<_CmsSection> _sections = const [
    _CmsSection(icon: Icons.dashboard_rounded, label: 'Tableau de bord', color: Color(0xFF1A5C38)),
    _CmsSection(icon: Icons.quiz_rounded, label: 'Questions', color: Color(0xFF1D4ED8)),
    _CmsSection(icon: Icons.upload_file_rounded, label: 'Import masse', color: Color(0xFF7C3AED)),
    _CmsSection(icon: Icons.library_books_rounded, label: 'Séries', color: Color(0xFFB45309)),
    _CmsSection(icon: Icons.timer_rounded, label: 'Simulations', color: Color(0xFFCE1126)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Navigation horizontal CMS
        Container(
          color: const Color(0xFF1e293b),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_sections.length, (i) {
                final s = _sections[i];
                final isActive = _selectedSection == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSection = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? s.color : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? s.color : Colors.white24),
                    ),
                    child: Row(children: [
                      Icon(s.icon, size: 16, color: isActive ? Colors.white : Colors.white60),
                      const SizedBox(width: 6),
                      Text(s.label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, color: isActive ? Colors.white : Colors.white60)),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
        // Contenu
        Expanded(
          child: switch (_selectedSection) {
            0 => const _CmsDashboardSection(),
            1 => const _CmsQuestionsSection(),
            2 => const _CmsBulkImportSection(),
            3 => const _CmsSeriesSection(),
            4 => const _CmsSimulationsSection(),
            _ => const SizedBox(),
          },
        ),
      ],
    );
  }
}

class _CmsSection {
  final IconData icon;
  final String label;
  final Color color;
  const _CmsSection({required this.icon, required this.label, required this.color});
}

// ── Helper API CMS ────────────────────────────────────────────
Future<Map<String, dynamic>> _cmsGet(String path) async {
  final token = ApiService.token;
  final res = await http.get(Uri.parse('$_cmsBase$path'), headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  });
  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _cmsPost(String path, Map<String, dynamic> body) async {
  final token = ApiService.token;
  final res = await http.post(Uri.parse('$_cmsBase$path'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body));
  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _cmsPut(String path, Map<String, dynamic> body) async {
  final token = ApiService.token;
  final res = await http.put(Uri.parse('$_cmsBase$path'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body));
  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _cmsDelete(String path) async {
  final token = ApiService.token;
  final res = await http.delete(Uri.parse('$_cmsBase$path'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
  return jsonDecode(res.body) as Map<String, dynamic>;
}

// ══════════════════════════════════════════════════════════════
// SECTION 0 : DASHBOARD CMS
// ══════════════════════════════════════════════════════════════

class _CmsDashboardSection extends StatefulWidget {
  const _CmsDashboardSection();

  @override
  State<_CmsDashboardSection> createState() => _CmsDashboardSectionState();
}

class _CmsDashboardSectionState extends State<_CmsDashboardSection> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await _cmsGet('/analytics/dashboard');
      if (mounted) setState(() { _data = d['stats'] as Map<String, dynamic>?; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A5C38)));
    if (_error != null) return _buildError(_error!, _load);
    final stats = _data ?? {};

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Titre
          Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF1A5C38), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Text('Tableau de bord CMS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          // Stats cards
          Row(children: [
            _dashCard('Utilisateurs', '${stats['total_users'] ?? 0}', Icons.people_rounded, const Color(0xFF1A5C38)),
            const SizedBox(width: 10),
            _dashCard('Questions', '${stats['total_questions'] ?? 0}', Icons.quiz_rounded, const Color(0xFF1D4ED8)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _dashCard('Simulations', '${stats['total_simulations_played'] ?? 0}', Icons.timer_rounded, const Color(0xFFB45309)),
            const SizedBox(width: 10),
            _dashCard('Signalements', '${stats['pending_flags'] ?? 0}', Icons.flag_rounded, const Color(0xFFCE1126)),
          ]),
          const SizedBox(height: 20),
          // Matières stats
          const Text('Questions par matière', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...((stats['matiere_stats'] as List<dynamic>? ?? []).take(8).map((m) {
            final mat = m as Map<String, dynamic>;
            final nb = (mat['nb_questions'] ?? 0) as int;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(flex: 3, child: Text(mat['nom']?.toString() ?? '', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                Expanded(flex: 4, child: Stack(children: [
                  Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                  if (nb > 0) FractionallySizedBox(
                    widthFactor: (nb / (stats['total_questions'] ?? 1) as double).clamp(0.0, 1.0),
                    child: Container(height: 8, decoration: BoxDecoration(color: const Color(0xFF1A5C38), borderRadius: BorderRadius.circular(4))),
                  ),
                ])),
                const SizedBox(width: 8),
                Text('$nb', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A5C38))),
              ]),
            );
          })),
          // Derniers imports
          if ((stats['recent_imports'] as List<dynamic>? ?? []).isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Derniers imports', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...((stats['recent_imports'] as List<dynamic>).take(3).map((imp) {
              final i = imp as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
                child: Row(children: [
                  const Icon(Icons.upload_file_rounded, color: Color(0xFF7C3AED), size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i['filename']?.toString() ?? 'Import', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('${i['imported_count'] ?? 0} questions importées', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF1A5C38).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(i['status']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF1A5C38), fontWeight: FontWeight.w600)),
                  ),
                ]),
              );
            })),
          ],
        ]),
      ),
    );
  }

  Widget _dashCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ])),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION 1 : GESTION QUESTIONS
// ══════════════════════════════════════════════════════════════

class _CmsQuestionsSection extends StatefulWidget {
  const _CmsQuestionsSection();

  @override
  State<_CmsQuestionsSection> createState() => _CmsQuestionsSectionState();
}

class _CmsQuestionsSectionState extends State<_CmsQuestionsSection> {
  List<dynamic> _questions = [];
  List<dynamic> _matieres = [];
  String? _selectedMatiere;
  String _search = '';
  int _page = 1;
  int _total = 0;
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMatieres();
  }

  Future<void> _loadMatieres() async {
    try {
      final d = await _cmsGet('/matieres');
      if (mounted) {
        setState(() { _matieres = d['matieres'] as List<dynamic>? ?? []; });
        _loadQuestions();
      }
    } catch (_) {
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    setState(() => _loading = true);
    try {
      String path = '/questions?page=$_page&limit=15';
      if (_selectedMatiere != null) path += '&matiere=$_selectedMatiere';
      if (_search.isNotEmpty) path += '&search=${Uri.encodeComponent(_search)}';
      final d = await _cmsGet(path);
      if (mounted) setState(() {
        _questions = d['questions'] as List<dynamic>? ?? [];
        _total = (d['total'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de filtres
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onSubmitted: (v) { _search = v; _page = 1; _loadQuestions(); },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showCreateQuestionSheet(context, null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Créer'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('Toutes', null),
                  ..._matieres.take(12).map((m) {
                    final mat = m as Map<String, dynamic>;
                    return _filterChip(mat['code']?.toString() ?? '', mat['code']?.toString());
                  }),
                ],
              ),
            ),
          ]),
        ),
        // Info total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: Colors.grey.shade50,
          child: Row(children: [
            Text('$_total questions trouvées', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Spacer(),
            Text('Page $_page / ${((_total / 15).ceil()).clamp(1, 9999)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        // Liste questions
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A5C38)))
              : _questions.isEmpty
                  ? _buildEmpty('Aucune question', 'Créez votre première question QCM')
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _questions.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == _questions.length) return _buildPagination();
                        final q = _questions[i] as Map<String, dynamic>;
                        return _QuestionCard(question: q, onEdit: () => _showCreateQuestionSheet(context, q), onDelete: () => _deleteQuestion(q['id']?.toString() ?? ''));
                      },
                    ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? value) {
    final isSelected = _selectedMatiere == value;
    return GestureDetector(
      onTap: () { setState(() { _selectedMatiere = value; _page = 1; }); _loadQuestions(); },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A5C38) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = ((_total / 15).ceil()).clamp(1, 9999);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          onPressed: _page > 1 ? () { setState(() => _page--); _loadQuestions(); } : null,
          icon: const Icon(Icons.chevron_left), color: const Color(0xFF1A5C38),
        ),
        Text('$_page / $totalPages', style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(
          onPressed: _page < totalPages ? () { setState(() => _page++); _loadQuestions(); } : null,
          icon: const Icon(Icons.chevron_right), color: const Color(0xFF1A5C38),
        ),
      ]),
    );
  }

  Future<void> _deleteQuestion(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Supprimer la question ?'),
      content: const Text('Cette action est irréversible.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (confirm != true) return;
    try {
      await _cmsDelete('/questions/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Question supprimée'), backgroundColor: Color(0xFF1A5C38)));
        _loadQuestions();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  void _showCreateQuestionSheet(BuildContext context, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _CreateQuestionForm(
        matieres: _matieres,
        existing: existing,
        onSaved: () { Navigator.pop(ctx); _loadQuestions(); },
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({required this.question, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final enonce = question['enonce']?.toString() ?? '';
    final diff = question['difficulte']?.toString() ?? 'MOYEN';
    final bonneRep = question['bonne_reponse']?.toString() ?? '';
    final published = question['published'] as bool? ?? true;

    Color diffColor = Colors.orange;
    if (diff == 'FACILE') diffColor = Colors.green;
    if (diff == 'DIFFICILE') diffColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        border: Border.all(color: published ? Colors.transparent : Colors.orange.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(diff[0], style: TextStyle(fontWeight: FontWeight.w700, color: diffColor, fontSize: 14))),
        ),
        title: Text(enonce, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text('Réponse: $bonneRep  •  ${published ? "Publié" : "Masqué"}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF1D4ED8))),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.red)),
        ]),
        children: [
          // Options
          if (question['option_a'] != null) _optionRow('A', question['option_a']?.toString() ?? '', bonneRep == 'A'),
          if (question['option_b'] != null) _optionRow('B', question['option_b']?.toString() ?? '', bonneRep == 'B'),
          if (question['option_c'] != null) _optionRow('C', question['option_c']?.toString() ?? '', bonneRep == 'C'),
          if (question['option_d'] != null) _optionRow('D', question['option_d']?.toString() ?? '', bonneRep == 'D'),
          if (question['option_e'] != null) _optionRow('E', question['option_e']?.toString() ?? '', bonneRep == 'E'),
          if (question['explication'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text('💡 ${question['explication']}', style: const TextStyle(fontSize: 12, color: Color(0xFF1D4ED8))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _optionRow(String letter, String text, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: isCorrect ? Colors.green : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(child: Text(letter, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isCorrect ? Colors.white : Colors.grey.shade600))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: isCorrect ? Colors.green.shade700 : Colors.black87, fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w400))),
        if (isCorrect) const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
      ]),
    );
  }
}

// Formulaire de création / édition de question
class _CreateQuestionForm extends StatefulWidget {
  final List<dynamic> matieres;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const _CreateQuestionForm({required this.matieres, required this.existing, required this.onSaved});

  @override
  State<_CreateQuestionForm> createState() => _CreateQuestionFormState();
}

class _CreateQuestionFormState extends State<_CreateQuestionForm> {
  final _enonceCtrl = TextEditingController();
  final _aCtrl = TextEditingController();
  final _bCtrl = TextEditingController();
  final _cCtrl = TextEditingController();
  final _dCtrl = TextEditingController();
  final _eCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _piegesCtrl = TextEditingController();
  final _sourcesCtrl = TextEditingController();
  String _bonneReponse = 'A';
  String _difficulte = 'MOYEN';
  String? _matiereId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final q = widget.existing!;
      _enonceCtrl.text = q['enonce']?.toString() ?? '';
      _aCtrl.text = q['option_a']?.toString() ?? '';
      _bCtrl.text = q['option_b']?.toString() ?? '';
      _cCtrl.text = q['option_c']?.toString() ?? '';
      _dCtrl.text = q['option_d']?.toString() ?? '';
      _eCtrl.text = q['option_e']?.toString() ?? '';
      _expCtrl.text = q['explication']?.toString() ?? '';
      _piegesCtrl.text = q['pieges']?.toString() ?? '';
      _sourcesCtrl.text = q['sources']?.toString() ?? '';
      _bonneReponse = q['bonne_reponse']?.toString() ?? 'A';
      _difficulte = q['difficulte']?.toString() ?? 'MOYEN';
      _matiereId = q['matiere_id']?.toString();
    } else if (widget.matieres.isNotEmpty) {
      _matiereId = (widget.matieres.first as Map<String, dynamic>)['id']?.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Icon(isEdit ? Icons.edit_rounded : Icons.add_circle_rounded, color: const Color(0xFF1A5C38)),
              const SizedBox(width: 10),
              Text(isEdit ? 'Modifier la question' : 'Créer une question', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),
            // Matière
            DropdownButtonFormField<String>(
              value: _matiereId,
              decoration: _inputDecor('Matière *'),
              items: widget.matieres.map((m) {
                final mat = m as Map<String, dynamic>;
                return DropdownMenuItem(value: mat['id']?.toString(), child: Text('${mat['code']} — ${mat['nom']}'.substring(0, ('${mat['code']} — ${mat['nom']}'.length).clamp(0, 35))));
              }).toList(),
              onChanged: (v) => setState(() => _matiereId = v),
            ),
            const SizedBox(height: 10),
            // Difficulté
            DropdownButtonFormField<String>(
              value: _difficulte,
              decoration: _inputDecor('Difficulté'),
              items: ['FACILE', 'MOYEN', 'DIFFICILE'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _difficulte = v!),
            ),
            const SizedBox(height: 10),
            // Énoncé
            TextField(controller: _enonceCtrl, maxLines: 3, decoration: _inputDecor('Énoncé de la question *')),
            const SizedBox(height: 10),
            // Options
            const Text('Propositions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 6),
            _optionField(_aCtrl, 'A', 'A'),
            _optionField(_bCtrl, 'B', 'B'),
            _optionField(_cCtrl, 'C', 'C'),
            _optionField(_dCtrl, 'D', 'D'),
            _optionField(_eCtrl, 'E (optionnel)', 'E'),
            const SizedBox(height: 10),
            // Bonne réponse
            DropdownButtonFormField<String>(
              value: _bonneReponse,
              decoration: _inputDecor('Bonne réponse *'),
              items: ['A', 'B', 'C', 'D', 'E'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _bonneReponse = v!),
            ),
            const SizedBox(height: 10),
            TextField(controller: _expCtrl, maxLines: 3, decoration: _inputDecor('Explication *')),
            const SizedBox(height: 8),
            TextField(controller: _piegesCtrl, maxLines: 2, decoration: _inputDecor('Pièges courants (optionnel)')),
            const SizedBox(height: 8),
            TextField(controller: _sourcesCtrl, decoration: _inputDecor('Source (optionnel)')),
            const SizedBox(height: 20),
            // Bouton sauvegarde
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(isEdit ? Icons.save_rounded : Icons.check_circle_rounded),
                label: Text(isEdit ? 'Enregistrer les modifications' : 'Créer la question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionField(TextEditingController ctrl, String label, String letter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        GestureDetector(
          onTap: () => setState(() => _bonneReponse = letter),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _bonneReponse == letter ? Colors.green : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _bonneReponse == letter ? Colors.green : Colors.grey.shade300),
            ),
            child: Center(child: Text(label.substring(0, 1), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _bonneReponse == letter ? Colors.white : Colors.grey))),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: ctrl, decoration: _inputDecor('Option $label'))),
      ]),
    );
  }

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label, isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true, fillColor: Colors.grey.shade50,
    );
  }

  Future<void> _save() async {
    if (_enonceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('L\'énoncé est requis'), backgroundColor: Colors.red));
      return;
    }
    if (_matiereId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisissez une matière'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'enonce': _enonceCtrl.text.trim(),
        'option_a': _aCtrl.text.trim(),
        'option_b': _bCtrl.text.trim(),
        'option_c': _cCtrl.text.isEmpty ? null : _cCtrl.text.trim(),
        'option_d': _dCtrl.text.isEmpty ? null : _dCtrl.text.trim(),
        'option_e': _eCtrl.text.isEmpty ? null : _eCtrl.text.trim(),
        'bonne_reponse': _bonneReponse,
        'explication': _expCtrl.text.trim(),
        'difficulte': _difficulte,
        'matiere_id': _matiereId,
        'pieges': _piegesCtrl.text.isEmpty ? null : _piegesCtrl.text.trim(),
        'sources': _sourcesCtrl.text.isEmpty ? null : _sourcesCtrl.text.trim(),
      };
      final isEdit = widget.existing != null;
      final result = isEdit
          ? await _cmsPut('/questions/${widget.existing!['id']}', body)
          : await _cmsPost('/questions', body);

      if (mounted) {
        if (result['success'] == true || result['question'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isEdit ? '✅ Question modifiée avec succès !' : '✅ Question créée et publiée en live !'),
            backgroundColor: const Color(0xFF1A5C38),
          ));
          widget.onSaved();
        } else {
          throw Exception(result['error'] ?? 'Erreur inconnue');
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
    setState(() => _saving = false);
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION 2 : IMPORT EN MASSE (CSV / JSON)
// ══════════════════════════════════════════════════════════════

class _CmsBulkImportSection extends StatefulWidget {
  const _CmsBulkImportSection();

  @override
  State<_CmsBulkImportSection> createState() => _CmsBulkImportSectionState();
}

class _CmsBulkImportSectionState extends State<_CmsBulkImportSection> {
  List<dynamic> _matieres = [];
  String? _selectedMatiereId;
  bool _loading = false;
  String _status = '';
  List<dynamic> _preview = [];
  int _validCount = 0;
  int _invalidCount = 0;
  List<dynamic> _errors = [];
  String _importHistory = '';
  bool _validated = false;

  // Données saisies manuellement en JSON
  final _jsonCtrl = TextEditingController(text: '''[
  {
    "enonce": "Qui est l'actuel Président du Burkina Faso ?",
    "option_a": "Roch Marc Kaboré",
    "option_b": "Paul-Henri Sandaogo Damiba",
    "option_c": "Ibrahim Traoré",
    "option_d": "Blaise Compaoré",
    "bonne_reponse": "C",
    "explication": "Le Capitaine Ibrahim Traoré est chef d'État depuis le 30 septembre 2022.",
    "difficulte": "FACILE"
  }
]''');

  @override
  void initState() {
    super.initState();
    _loadMatieres();
  }

  Future<void> _loadMatieres() async {
    try {
      final d = await _cmsGet('/matieres');
      if (mounted) setState(() {
        _matieres = d['matieres'] as List<dynamic>? ?? [];
        if (_matieres.isNotEmpty) _selectedMatiereId = (_matieres.first as Map<String, dynamic>)['id']?.toString();
      });
    } catch (_) {}
  }

  Future<void> _validate() async {
    if (_selectedMatiereId == null) {
      setState(() => _status = '❌ Veuillez choisir une matière');
      return;
    }
    setState(() { _loading = true; _status = 'Validation en cours...'; _validated = false; });
    try {
      List<dynamic> questions = jsonDecode(_jsonCtrl.text) as List<dynamic>;
      final result = await _cmsPost('/questions/validate-bulk', {
        'questions': questions,
        'matiere_id': _selectedMatiereId,
      });
      if (mounted) setState(() {
        _loading = false;
        _preview = result['preview'] as List<dynamic>? ?? [];
        _validCount = (result['total_valid'] as num?)?.toInt() ?? 0;
        _invalidCount = (result['total_invalid'] as num?)?.toInt() ?? 0;
        _errors = result['errors'] as List<dynamic>? ?? [];
        _status = '✅ Validation terminée : $_validCount valides, $_invalidCount invalides';
        _validated = true;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _status = '❌ Erreur: $e'; });
    }
  }

  Future<void> _import() async {
    if (_selectedMatiereId == null) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirmer l\'import ?'),
      content: Text('Vous allez importer $_validCount questions dans la base de données. Cette action est immédiate et les utilisateurs verront les questions en live.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5C38)),
          child: const Text('Importer maintenant', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
    if (confirm != true) return;

    setState(() { _loading = true; _status = 'Import en cours...'; });
    try {
      List<dynamic> questions = jsonDecode(_jsonCtrl.text) as List<dynamic>;
      final result = await _cmsPost('/questions/bulk-import', {
        'questions': questions,
        'matiere_id': _selectedMatiereId,
      });
      if (mounted) setState(() {
        _loading = false;
        final imported = result['imported'] as num? ?? 0;
        final failed = result['failed'] as num? ?? 0;
        _status = '✅ Import réussi ! $imported questions importées, $failed échouées';
        _importHistory = 'ID: ${result['import_id'] ?? ''}\nImporté: $imported questions\nÉchoué: $failed';
        _validated = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ${result['imported'] ?? 0} questions importées en live !'),
          backgroundColor: const Color(0xFF1A5C38),
        ));
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _status = '❌ Erreur: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          const Icon(Icons.upload_file_rounded, color: Color(0xFF7C3AED)),
          const SizedBox(width: 8),
          const Text('Import en masse (JSON)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        const Text('Collez votre JSON ou saisissez vos questions directement', style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 16),

        // Sélection matière
        DropdownButtonFormField<String>(
          value: _selectedMatiereId,
          decoration: InputDecoration(
            labelText: 'Matière cible *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.book_rounded, color: Color(0xFF7C3AED)),
          ),
          items: _matieres.map((m) {
            final mat = m as Map<String, dynamic>;
            return DropdownMenuItem(value: mat['id']?.toString(), child: Text('${mat['code']} — ${mat['nom']}'.substring(0, ('${mat['code']} — ${mat['nom']}'.length).clamp(0, 40))));
          }).toList(),
          onChanged: (v) => setState(() => _selectedMatiereId = v),
        ),
        const SizedBox(height: 12),

        // Format attendu
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Format JSON attendu :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
            const SizedBox(height: 4),
            const Text('enonce, option_a/b/c/d/e, bonne_reponse (A/B/C/D/E), explication, difficulte (FACILE/MOYEN/DIFFICILE)', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
        const SizedBox(height: 12),

        // Zone saisie JSON
        TextField(
          controller: _jsonCtrl,
          maxLines: 12,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          decoration: InputDecoration(
            labelText: 'Contenu JSON (tableau de questions)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true, fillColor: const Color(0xFF1e293b).withValues(alpha: 0.05),
          ),
        ),
        const SizedBox(height: 12),

        // Boutons
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Valider'),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7C3AED), side: const BorderSide(color: Color(0xFF7C3AED))),
              onPressed: _loading ? null : _validate,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.rocket_launch_rounded),
              label: const Text('Importer'),
              style: ElevatedButton.styleFrom(backgroundColor: _validated ? const Color(0xFF7C3AED) : Colors.grey, foregroundColor: Colors.white),
              onPressed: (_loading || !_validated) ? null : _import,
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Status
        if (_status.isNotEmpty) Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _status.startsWith('✅') ? Colors.green.shade50 : _status.startsWith('❌') ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _status.startsWith('✅') ? Colors.green.shade200 : _status.startsWith('❌') ? Colors.red.shade200 : Colors.blue.shade200),
          ),
          child: Text(_status, style: TextStyle(fontSize: 13, color: _status.startsWith('✅') ? Colors.green.shade700 : _status.startsWith('❌') ? Colors.red.shade700 : Colors.blue.shade700)),
        ),

        // Erreurs de validation
        if (_errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Erreurs détectées :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
          const SizedBox(height: 6),
          ..._errors.map((e) {
            final err = e as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
              child: Text('Ligne ${err['line'] ?? '?'}: ${err['error'] ?? '?'}', style: const TextStyle(fontSize: 12, color: Colors.red)),
            );
          }),
        ],

        // Prévisualisation
        if (_preview.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Prévisualisation (5 premières) :', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._preview.take(5).map((q) {
            final question = q as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(question['enonce']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Réponse: ${question['bonne_reponse']}  •  ${question['difficulte'] ?? 'MOYEN'}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                if (question['status'] != null) Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(question['status']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                ),
              ]),
            );
          }),
        ],

        // Historique import
        if (_importHistory.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Rapport d\'import :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green)),
              const SizedBox(height: 4),
              Text(_importHistory, style: const TextStyle(fontSize: 12, color: Colors.green)),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION 3 : GESTION SÉRIES
// ══════════════════════════════════════════════════════════════

class _CmsSeriesSection extends StatefulWidget {
  const _CmsSeriesSection();

  @override
  State<_CmsSeriesSection> createState() => _CmsSeriesSectionState();
}

class _CmsSeriesSectionState extends State<_CmsSeriesSection> {
  List<dynamic> _series = [];
  List<dynamic> _matieres = [];
  String? _selectedMatiereId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMatieres();
  }

  Future<void> _loadMatieres() async {
    try {
      final d = await _cmsGet('/matieres');
      if (mounted) {
        setState(() {
          _matieres = d['matieres'] as List<dynamic>? ?? [];
          if (_matieres.isNotEmpty) _selectedMatiereId = (_matieres.first as Map<String, dynamic>)['id']?.toString();
        });
        _loadSeries();
      }
    } catch (_) { _loadSeries(); }
  }

  Future<void> _loadSeries() async {
    setState(() => _loading = true);
    try {
      String path = '/series';
      if (_selectedMatiereId != null) path += '?matiere_id=$_selectedMatiereId';
      final d = await _cmsGet(path);
      if (mounted) setState(() {
        _series = d['series'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _autoGenerate() async {
    if (_selectedMatiereId == null) return;
    setState(() => _loading = true);
    try {
      final result = await _cmsPost('/series/auto-generate', {'matiere_id': _selectedMatiereId, 'count': 20});
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Série créée automatiquement !'), backgroundColor: Color(0xFF1A5C38)));
          _loadSeries();
        } else {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']?.toString() ?? 'Erreur'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) { setState(() => _loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red)); }
    }
  }

  Future<void> _deleteSerie(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Supprimer la série ?'),
      content: const Text('Les questions liées seront conservées.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (confirm != true) return;
    await _cmsDelete('/series/$id?orphan=keep');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Série supprimée'), backgroundColor: Color(0xFF1A5C38)));
      _loadSeries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtre matière
        Container(
          padding: const EdgeInsets.all(12), color: Colors.white,
          child: Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedMatiereId,
                decoration: InputDecoration(labelText: 'Matière', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                items: _matieres.map((m) {
                  final mat = m as Map<String, dynamic>;
                  return DropdownMenuItem(value: mat['id']?.toString(), child: Text('${mat['code']} — ${mat['nom']}'.substring(0, ('${mat['code']} — ${mat['nom']}'.length).clamp(0, 30))));
                }).toList(),
                onChanged: (v) { setState(() => _selectedMatiereId = v); _loadSeries(); },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _loading ? null : _autoGenerate,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Auto'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB45309), foregroundColor: Colors.white),
            ),
          ]),
        ),
        // Liste séries
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFB45309)))
              : _series.isEmpty
                  ? _buildEmpty('Aucune série', 'Créez une série auto avec 20 questions aléatoires')
                  : RefreshIndicator(
                      onRefresh: _loadSeries,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _series.length,
                        itemBuilder: (ctx, i) {
                          final s = _series[i] as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: const Color(0xFFB45309).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: Center(child: Text('${s['numero'] ?? i + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB45309), fontSize: 16))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s['titre']?.toString() ?? 'Série ${s['numero'] ?? i + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('${s['nb_questions'] ?? 0} questions  •  ${s['matiere']?.toString() ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ])),
                              IconButton(
                                onPressed: () => _deleteSerie(s['id']?.toString() ?? ''),
                                icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION 4 : GESTION SIMULATIONS
// ══════════════════════════════════════════════════════════════

class _CmsSimulationsSection extends StatefulWidget {
  const _CmsSimulationsSection();

  @override
  State<_CmsSimulationsSection> createState() => _CmsSimulationsSectionState();
}

class _CmsSimulationsSectionState extends State<_CmsSimulationsSection> {
  List<dynamic> _simulations = [];
  List<dynamic> _matieres = [];
  bool _loading = true;
  bool _showCreate = false;

  // Formulaire création
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _duree = 90;
  final List<Map<String, dynamic>> _questionSelections = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r1 = await _cmsGet('/simulations');
      final r2 = await _cmsGet('/matieres');
      if (mounted) setState(() {
        _simulations = r1['simulations'] as List<dynamic>? ?? [];
        _matieres = r2['matieres'] as List<dynamic>? ?? [];
        // Initialiser les sélections de questions
        if (_questionSelections.isEmpty) {
          for (final m in _matieres) {
            final mat = m as Map<String, dynamic>;
            _questionSelections.add({'matiere_id': mat['id'], 'nom': mat['nom'], 'code': mat['code'], 'count': 0});
          }
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalQuestions => _questionSelections.fold(0, (sum, s) => sum + (s['count'] as int));

  Future<void> _createSimulation() async {
    if (_titreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titre requis'), backgroundColor: Colors.red));
      return;
    }
    if (_totalQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez au moins une question'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _loading = true);
    try {
      final questions = _questionSelections.where((s) => (s['count'] as int) > 0).map((s) => {'matiere_id': s['matiere_id'], 'count': s['count']}).toList();
      final result = await _cmsPost('/simulations', {
        'titre': _titreCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'duree_minutes': _duree,
        'questions': questions,
      });
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ Simulation créée avec ${result['total_questions'] ?? _totalQuestions} questions !'),
            backgroundColor: const Color(0xFF1A5C38),
          ));
          setState(() { _showCreate = false; _titreCtrl.clear(); _descCtrl.clear(); for (final s in _questionSelections) s['count'] = 0; });
          _load();
        } else {
          throw Exception(result['error'] ?? 'Erreur');
        }
      }
    } catch (e) {
      if (mounted) { setState(() => _loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red)); }
    }
  }

  Future<void> _deleteSimulation(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Supprimer la simulation ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (confirm != true) return;
    await _cmsDelete('/simulations/$id');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Simulation supprimée'), backgroundColor: Color(0xFF1A5C38)));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFCE1126)));

    return Column(
      children: [
        // Header avec bouton créer
        Container(
          padding: const EdgeInsets.all(12), color: Colors.white,
          child: Row(children: [
            const Text('Simulations d\'examen', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showCreate = !_showCreate),
              icon: Icon(_showCreate ? Icons.close : Icons.add),
              label: Text(_showCreate ? 'Annuler' : 'Créer'),
              style: ElevatedButton.styleFrom(backgroundColor: _showCreate ? Colors.grey : const Color(0xFFCE1126), foregroundColor: Colors.white),
            ),
          ]),
        ),
        Expanded(
          child: _showCreate ? _buildCreateForm() : _buildSimulationsList(),
        ),
      ],
    );
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Créer une simulation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFCE1126))),
        const SizedBox(height: 14),
        TextField(controller: _titreCtrl, decoration: InputDecoration(labelText: 'Titre *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey.shade50)),
        const SizedBox(height: 10),
        TextField(controller: _descCtrl, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey.shade50)),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _duree,
          decoration: InputDecoration(labelText: 'Durée', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          items: [90, 120, 180, 240].map((d) => DropdownMenuItem(value: d, child: Text('${d ~/ 60}h${d % 60 == 0 ? '' : '${d % 60}min'}'))).toList(),
          onChanged: (v) => setState(() => _duree = v!),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Text('Questions par matière', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: _totalQuestions > 0 ? const Color(0xFF1A5C38) : Colors.grey, borderRadius: BorderRadius.circular(12)),
            child: Text('Total: $_totalQuestions', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 10),
        ..._questionSelections.take(10).map((sel) {
          return StatefulBuilder(
            builder: (ctx, setSel) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Text('${sel['code']} — ${sel['nom']}'.substring(0, ('${sel['code']} — ${sel['nom']}'.length).clamp(0, 30)), style: const TextStyle(fontSize: 13))),
                Row(children: [
                  IconButton(
                    onPressed: sel['count'] > 0 ? () { setState(() => sel['count'] = (sel['count'] as int) - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: const Color(0xFFCE1126),
                  ),
                  SizedBox(width: 28, child: Text('${sel['count']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
                  IconButton(
                    onPressed: () => setState(() => sel['count'] = (sel['count'] as int) + 1),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    color: const Color(0xFF1A5C38),
                  ),
                ]),
              ]),
            ),
          );
        }),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.rocket_launch_rounded),
            label: Text('Créer et publier ($_totalQuestions questions)'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCE1126), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _createSimulation,
          ),
        ),
      ]),
    );
  }

  Widget _buildSimulationsList() {
    if (_simulations.isEmpty) return _buildEmpty('Aucune simulation', 'Créez votre première simulation d\'examen');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _simulations.length,
        itemBuilder: (ctx, i) {
          final s = _simulations[i] as Map<String, dynamic>;
          final nbQ = (s['nb_questions'] as num?)?.toInt() ?? (s['question_ids'] as List?)?.length ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFCE1126).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.timer_rounded, color: Color(0xFFCE1126), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['titre']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('$nbQ questions  •  ${(s['duree_minutes'] as num?)?.toInt() ?? 90} min', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (s['total_played'] != null) Text('Joué ${s['total_played']} fois', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ])),
              IconButton(
                onPressed: () => _deleteSimulation(s['id']?.toString() ?? ''),
                icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
              ),
            ]),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS UTILITAIRES
// ══════════════════════════════════════════════════════════════

Widget _buildEmpty(String title, String subtitle) {
  return Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
      const SizedBox(height: 6),
      Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade400), textAlign: TextAlign.center),
    ]),
  );
}

Widget _buildError(String error, VoidCallback onRetry) {
  return Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
      const SizedBox(height: 16),
      Text('Erreur de chargement', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(error, style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Réessayer'),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white),
      ),
    ]),
  );
}
