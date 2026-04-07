import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════════
// ADMIN SCREEN — EF-FORT.BF v8.0 — REFONTE COMPLÈTE
// Panel harmonisé: Stats fusionnées, CMS QCM complet, Paiements,
// Annonces, Changement mot de passe admin
// ══════════════════════════════════════════════════════════════

const String _baseUrl = 'https://ef-fort-bf.yembuaro29.workers.dev';
const String _cmsBase = '$_baseUrl/api/admin-cms';

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

  final List<_AdminTab> _tabs = const [
    _AdminTab(icon: Icons.dashboard_rounded, label: 'Tableau de bord'),
    _AdminTab(icon: Icons.credit_card_rounded, label: 'Paiements'),
    _AdminTab(icon: Icons.newspaper_rounded, label: 'Annonces'),
    _AdminTab(icon: Icons.key_rounded, label: 'Sécurité'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadData();
    // Rafraîchissement automatique toutes les 60 secondes
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        _loadData();
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() { _loadingStats = true; _loadingDemandes = true; });
    final statsResult = await ApiService.getAdminStats();
    final demandes = await ApiService.getDemandesAbonnement();
    if (mounted) {
      setState(() {
        _stats = statsResult['stats'] as Map<String, dynamic>? ?? statsResult;
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
        title: const Text('Administration', style: TextStyle(fontWeight: FontWeight.w700)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1A5C38), Color(0xFF0f3d26)]),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Rafraîchir',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.5),
          isScrollable: true,
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(
            icon: Icon(t.icon, size: 18),
            text: t.label,
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DashboardTab(stats: _stats, demandes: _demandes, loading: _loadingStats, onRefresh: _loadData),
          _PaiementsTab(demandes: _demandes, loading: _loadingDemandes, onRefresh: _loadData),
          const _AnnoncesTab(),
          const _ChangePasswordTab(),
        ],
      ),
    );
  }
}

class _AdminTab {
  final IconData icon;
  final String label;
  const _AdminTab({required this.icon, required this.label});
}

// ══════════════════════════════════════════════════════════════
// ONGLET 1 — TABLEAU DE BORD FUSIONNÉ
// ══════════════════════════════════════════════════════════════
class _DashboardTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<dynamic> demandes;
  final bool loading;
  final VoidCallback onRefresh;

  const _DashboardTab({required this.stats, required this.demandes, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    final pendingCount = demandes.where((d) => d['statut'] == 'EN_ATTENTE').length;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Titre
          Row(children: [
            Container(width: 4, height: 22, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Expanded(child: Text('Tableau de bord consolidé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 4),
          Text('Mis à jour : ${DateTime.now().hour.toString().padLeft(2, '0')}h${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 17, color: AppColors.textLight)),
          const SizedBox(height: 16),

          // Alerte paiements en attente
          if (pendingCount > 0) Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(children: [
              const Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$pendingCount paiement(s) en attente', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const Text('Validez les abonnements des utilisateurs', style: TextStyle(fontSize: 17, color: Colors.grey)),
              ])),
            ]),
          ),

          // Grille de stats
          Row(children: [
            _statCard('Utilisateurs', '${stats['totalUsers'] ?? stats['total_users'] ?? 0}', Icons.people_rounded, AppColors.primary),
            const SizedBox(width: 12),
            _statCard('Abonnés', '${stats['abonnes'] ?? stats['total_abonnes'] ?? 0}', Icons.workspace_premium_rounded, AppColors.secondary),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _statCard('Questions', '${stats['totalQuestions'] ?? stats['total_questions'] ?? 0}', Icons.quiz_rounded, Colors.blue.shade700),
            const SizedBox(width: 12),
            _statCard('Simulations', '${stats['totalSimulations'] ?? stats['total_sessions'] ?? 0}', Icons.timer_rounded, Colors.orange.shade700),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _statCard('En attente', '${stats['demandesEnAttente'] ?? stats['demandes_en_attente'] ?? pendingCount}', Icons.pending_rounded,
                pendingCount > 0 ? AppColors.error : Colors.grey),
            const SizedBox(width: 12),
            _statCard('Actualités', '${stats['totalActualites'] ?? stats['total_actualites'] ?? 0}', Icons.newspaper_rounded, Colors.teal.shade700),
          ]),
          const SizedBox(height: 24),

          // Dernières demandes
          if (demandes.isNotEmpty) ...[
            Row(children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              const Text('Dernières demandes d\'abonnement', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            ...demandes.take(3).map((d) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: d['statut'] == 'EN_ATTENTE' ? Colors.orange.shade200 : Colors.green.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
              ),
              child: Row(children: [
                Icon(
                  d['statut'] == 'EN_ATTENTE' ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                  color: d['statut'] == 'EN_ATTENTE' ? Colors.orange : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['nom_complet']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(d['telephone']?.toString() ?? '', style: const TextStyle(fontSize: 17, color: Colors.grey)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: d['statut'] == 'EN_ATTENTE' ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(d['statut']?.toString() ?? '', style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: d['statut'] == 'EN_ATTENTE' ? Colors.orange.shade800 : Colors.green.shade800,
                  )),
                ),
              ]),
            )),
          ],
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
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
          Text(label, style: TextStyle(fontSize: 17, color: AppColors.textLight), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ONGLET 2 — VALIDATION DES PAIEMENTS
// ══════════════════════════════════════════════════════════════
class _PaiementsTab extends StatefulWidget {
  final List<dynamic> demandes;
  final bool loading;
  final VoidCallback onRefresh;
  const _PaiementsTab({required this.demandes, required this.loading, required this.onRefresh});
  @override
  State<_PaiementsTab> createState() => _PaiementsTabState();
}

class _PaiementsTabState extends State<_PaiementsTab> {
  String _filter = 'EN_ATTENTE';
  bool _validating = false;

  List<dynamic> get _filtered {
    if (_filter == 'TOUS') return widget.demandes;
    return widget.demandes.where((d) => d['statut'] == _filter).toList();
  }

  Future<void> _valider(String id) async {
    setState(() => _validating = true);
    final result = await ApiService.validerAbonnement(id);
    if (mounted) {
      setState(() => _validating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] == true ? '✅ Abonnement validé !' : '❌ ${result['error'] ?? 'Erreur'}'),
        backgroundColor: result['success'] == true ? AppColors.success : AppColors.error,
      ));
      if (result['success'] == true) widget.onRefresh();
    }
  }

  Future<void> _rejeter(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter la demande ?'),
        content: const Text('L\'utilisateur ne recevra pas l\'accès premium.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final token = ApiService.token;
    await http.post(
      Uri.parse('$_baseUrl/api/admin/valider-abonnement/$id'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'statut': 'REJETE'}),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande rejetée'), backgroundColor: Colors.orange));
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    final pendingCount = widget.demandes.where((d) => d['statut'] == 'EN_ATTENTE').length;

    return Column(
      children: [
        // Header info
        Container(
          padding: const EdgeInsets.all(16),
          color: pendingCount > 0 ? Colors.orange.shade50 : Colors.green.shade50,
          child: Row(children: [
            Icon(pendingCount > 0 ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                color: pendingCount > 0 ? Colors.orange : Colors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(
              pendingCount > 0 ? '$pendingCount demande(s) en attente de validation' : '✅ Aucune demande en attente',
              style: TextStyle(fontWeight: FontWeight.w700, color: pendingCount > 0 ? Colors.orange.shade800 : Colors.green.shade800),
            )),
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: widget.onRefresh, tooltip: 'Rafraîchir'),
          ]),
        ),
        // Filtres
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.white,
          child: Row(children: [
            _filterChip('⏳ En attente', 'EN_ATTENTE', Colors.orange),
            const SizedBox(width: 8),
            _filterChip('✅ Validés', 'VALIDE', Colors.green),
            const SizedBox(width: 8),
            _filterChip('📋 Tous', 'TOUS', Colors.blueGrey),
          ]),
        ),
        // Liste
        Expanded(
          child: _filtered.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Aucune demande ${_filter == 'EN_ATTENTE' ? 'en attente' : ''}', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ]))
              : RefreshIndicator(
                  onRefresh: () async => widget.onRefresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final d = _filtered[i] as Map<String, dynamic>;
                      final isEnAttente = d['statut'] == 'EN_ATTENTE';
                      final id = d['id']?.toString() ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isEnAttente ? Colors.orange.shade200 : Colors.green.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isEnAttente ? Colors.orange.shade100 : Colors.green.shade100,
                                child: Icon(
                                  isEnAttente ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                                  color: isEnAttente ? Colors.orange : Colors.green,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(d['nom_complet']?.toString() ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                                Row(children: [
                                  const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(d['telephone']?.toString() ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                                ]),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isEnAttente ? Colors.orange.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isEnAttente ? '⏳ En attente' : '✅ Validé',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                                      color: isEnAttente ? Colors.orange.shade800 : Colors.green.shade800),
                                ),
                              ),
                            ]),
                            if (d['moyen_paiement'] != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Row(children: [
                                  const Icon(Icons.payment_rounded, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('💳 ${d['moyen_paiement']}', style: const TextStyle(fontSize: 16)),
                                ]),
                              ),
                            ],
                            if (isEnAttente) ...[
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _validating ? null : () => _valider(id),
                                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                                    label: const Text('Valider', style: TextStyle(fontWeight: FontWeight.w700)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: AppColors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _validating ? null : () => _rejeter(id),
                                    icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.error),
                                    label: const Text('Rejeter', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.error),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ]),
                            ],
                          ]),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value, Color color) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(fontSize: 17, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? color : Colors.grey.shade700)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ONGLET CMS QCM — EN COURS DE REFONTE (non affiché dans le menu)
// ══════════════════════════════════════════════════════════════
class CmsQcmTab extends StatefulWidget {
  const CmsQcmTab({super.key});
  @override
  State<CmsQcmTab> createState() => _CmsQcmTabState();
}

class _CmsQcmTabState extends State<CmsQcmTab> {
  int _selectedSection = 0;

  final List<_CmsSection> _sections = const [
    _CmsSection(icon: Icons.dashboard_rounded, label: 'Stats', color: Color(0xFF1A5C38)),
    _CmsSection(icon: Icons.quiz_rounded, label: 'Questions', color: Color(0xFF1D4ED8)),
    _CmsSection(icon: Icons.upload_file_rounded, label: 'Importer', color: Color(0xFF7C3AED)),
    _CmsSection(icon: Icons.library_books_rounded, label: 'Séries', color: Color(0xFFB45309)),
    _CmsSection(icon: Icons.timer_rounded, label: 'Examens', color: Color(0xFFCE1126)),
    _CmsSection(icon: Icons.extension_rounded, label: 'Générateur', color: Color(0xFF0891B2)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de navigation CMS horizontale
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
                      Text(s.label, style: TextStyle(fontSize: 17, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, color: isActive ? Colors.white : Colors.white60)),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
        // Contenu de section
        Expanded(
          child: switch (_selectedSection) {
            0 => const _CmsDashboardSection(),
            1 => const _CmsQuestionsSection(),
            2 => const _CmsBulkImportSection(),
            3 => const _CmsSeriesSection(),
            4 => const _CmsSimulationsSection(),
            5 => const _CmsExamGeneratorSection(),
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
  try { return jsonDecode(res.body) as Map<String, dynamic>; } catch (_) { return {}; }
}

Future<Map<String, dynamic>> _cmsPost(String path, Map<String, dynamic> body) async {
  final token = ApiService.token;
  final res = await http.post(Uri.parse('$_cmsBase$path'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body));
  try { return jsonDecode(res.body) as Map<String, dynamic>; } catch (_) { return {}; }
}

Future<Map<String, dynamic>> _cmsPut(String path, Map<String, dynamic> body) async {
  final token = ApiService.token;
  final res = await http.put(Uri.parse('$_cmsBase$path'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body));
  try { return jsonDecode(res.body) as Map<String, dynamic>; } catch (_) { return {}; }
}

Future<Map<String, dynamic>> _cmsDelete(String path) async {
  final token = ApiService.token;
  final res = await http.delete(Uri.parse('$_cmsBase$path'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
  try { return jsonDecode(res.body) as Map<String, dynamic>; } catch (_) { return {}; }
}

// ══════════════════════════════════════════════════════════════
// SECTION CMS 0 — DASHBOARD STATISTIQUES
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
  void initState() { super.initState(); _load(); }

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
          _sectionTitle('Statistiques CMS', const Color(0xFF1A5C38)),
          const SizedBox(height: 16),
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
          _sectionTitle('Questions par matière', const Color(0xFF1A5C38)),
          const SizedBox(height: 10),
          ...((stats['matiere_stats'] as List<dynamic>? ?? []).take(10).map((m) {
            final mat = m as Map<String, dynamic>;
            final nb = (mat['nb_questions'] as num?)?.toInt() ?? 0;
            final total = (stats['total_questions'] as num?)?.toInt() ?? 1;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(flex: 3, child: Text(mat['nom']?.toString() ?? '', style: const TextStyle(fontSize: 17), overflow: TextOverflow.ellipsis)),
                Expanded(flex: 4, child: Stack(children: [
                  Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                  if (nb > 0) FractionallySizedBox(
                    widthFactor: (nb / total).clamp(0.0, 1.0),
                    child: Container(height: 8, decoration: BoxDecoration(color: const Color(0xFF1A5C38), borderRadius: BorderRadius.circular(4))),
                  ),
                ])),
                const SizedBox(width: 8),
                Text('$nb', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A5C38))),
              ]),
            );
          })),
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
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 17, color: Colors.grey)),
          ])),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION CMS 1 — GESTION QUESTIONS
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
  void initState() { super.initState(); _loadMatieres(); }

  Future<void> _loadMatieres() async {
    try {
      final d = await _cmsGet('/matieres');
      if (mounted) {
        setState(() => _matieres = d['matieres'] as List<dynamic>? ?? []);
        _loadQuestions();
      }
    } catch (_) { _loadQuestions(); }
  }

  Future<void> _loadQuestions() async {
    setState(() => _loading = true);
    try {
      String path = '/questions?page=$_page&limit=15';
      if (_selectedMatiere != null) path += '&matiere_id=$_selectedMatiere';
      if (_search.isNotEmpty) path += '&search=${Uri.encodeComponent(_search)}';
      final d = await _cmsGet(path);
      if (mounted) setState(() {
        _questions = d['questions'] as List<dynamic>? ?? [];
        _total = (d['total'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteQuestion(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Supprimer la question ?'),
      content: const Text('Cette action est irréversible.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Supprimer', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (confirm != true) return;
    await _cmsDelete('/questions/$id');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Question supprimée'), backgroundColor: Color(0xFF1A5C38)));
      _loadQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12), color: Colors.white,
          child: Column(children: [
            Row(children: [
              Expanded(child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher une question...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onSubmitted: (v) { _search = v; _page = 1; _loadQuestions(); },
              )),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showQuestionSheet(context, null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Créer'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13)),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                _chip('Toutes', null),
                ..._matieres.take(15).map((m) {
                  final mat = m as Map<String, dynamic>;
                  return _chip(mat['code']?.toString() ?? mat['nom']?.toString() ?? '', mat['id']?.toString());
                }),
              ]),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), color: Colors.grey.shade50,
          child: Row(children: [
            Text('$_total questions', style: const TextStyle(fontSize: 17, color: Colors.grey)),
            const Spacer(),
            Text('Page $_page / ${((_total / 15).ceil()).clamp(1, 9999)}', style: const TextStyle(fontSize: 17, color: Colors.grey)),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A5C38)))
              : _questions.isEmpty
                  ? _buildEmpty('Aucune question', 'Créez votre première question')
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _questions.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == _questions.length) return _buildPagination();
                        final q = _questions[i] as Map<String, dynamic>;
                        return _QuestionCard(question: q,
                          onEdit: () => _showQuestionSheet(context, q),
                          onDelete: () => _deleteQuestion(q['id']?.toString() ?? ''),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _chip(String label, String? value) {
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
        child: Text(label, style: TextStyle(fontSize: 17, color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = ((_total / 15).ceil()).clamp(1, 9999);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(onPressed: _page > 1 ? () { setState(() => _page--); _loadQuestions(); } : null, icon: const Icon(Icons.chevron_left), color: const Color(0xFF1A5C38)),
        Text('$_page / $totalPages', style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(onPressed: _page < totalPages ? () { setState(() => _page++); _loadQuestions(); } : null, icon: const Icon(Icons.chevron_right), color: const Color(0xFF1A5C38)),
      ]),
    );
  }

  void _showQuestionSheet(BuildContext context, Map<String, dynamic>? existing) {
    final isEdit = existing != null;
    final questionCtrl = TextEditingController(text: existing?['enonce']?.toString() ?? '');
    final aCtrl = TextEditingController(text: existing?['option_a']?.toString() ?? '');
    final bCtrl = TextEditingController(text: existing?['option_b']?.toString() ?? '');
    final cCtrl = TextEditingController(text: existing?['option_c']?.toString() ?? '');
    final dCtrl = TextEditingController(text: existing?['option_d']?.toString() ?? '');
    final expCtrl = TextEditingController(text: existing?['explication']?.toString() ?? '');
    String bonneReponse = existing?['bonne_reponse']?.toString() ?? 'A';
    String? matiereId = existing?['matiere_id']?.toString() ?? (_matieres.isNotEmpty ? _matieres.first['id']?.toString() : null);

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(isEdit ? '✏️ Modifier la question' : '✚ Nouvelle question', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 12),
              // Matière
              if (_matieres.isNotEmpty) DropdownButtonFormField<String>(
                value: matiereId,
                decoration: InputDecoration(labelText: 'Matière', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                items: _matieres.map((m) => DropdownMenuItem<String>(
                  value: m['id']?.toString(),
                  child: Text('${m['code'] ?? ''} — ${m['nom'] ?? ''}', style: const TextStyle(fontSize: 16)),
                )).toList(),
                onChanged: (v) => setSt(() => matiereId = v),
              ),
              const SizedBox(height: 10),
              TextField(controller: questionCtrl, decoration: InputDecoration(labelText: 'Question *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), maxLines: 3),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: aCtrl, decoration: InputDecoration(labelText: 'A)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: bCtrl, decoration: InputDecoration(labelText: 'B)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: cCtrl, decoration: InputDecoration(labelText: 'C)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: dCtrl, decoration: InputDecoration(labelText: 'D)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true))),
              ]),
              const SizedBox(height: 10),
              // Bonne réponse
              Row(children: [
                const Text('Bonne réponse :', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                ...['A', 'B', 'C', 'D'].map((r) => GestureDetector(
                  onTap: () => setSt(() => bonneReponse = r),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: bonneReponse == r ? const Color(0xFF1A5C38) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: bonneReponse == r ? const Color(0xFF1A5C38) : Colors.grey.shade300),
                    ),
                    child: Center(child: Text(r, style: TextStyle(fontWeight: FontWeight.w700, color: bonneReponse == r ? Colors.white : Colors.grey))),
                  ),
                )),
              ]),
              const SizedBox(height: 10),
              TextField(controller: expCtrl, decoration: InputDecoration(labelText: 'Explication détaillée', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), maxLines: 3),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final q = questionCtrl.text.trim();
                    if (q.isEmpty) return;
                    final payload = {
                      'enonce': q, 'question': q,
                      'option_a': aCtrl.text.trim(), 'option_b': bCtrl.text.trim(),
                      'option_c': cCtrl.text.trim(), 'option_d': dCtrl.text.trim(),
                      'bonne_reponse': bonneReponse, 'explication': expCtrl.text.trim(),
                      if (matiereId != null) 'matiere_id': matiereId,
                    };
                    if (isEdit) {
                      await _cmsPut('/questions/${existing['id']}', payload);
                    } else {
                      await _cmsPost('/questions', payload);
                    }
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isEdit ? '✅ Question modifiée' : '✅ Question créée'),
                        backgroundColor: const Color(0xFF1A5C38),
                      ));
                      _loadQuestions();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEdit ? '💾 Enregistrer les modifications' : '✚ Créer la question', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION CMS 2 — IMPORT EN MASSE (txt/MD/PDF)
// ══════════════════════════════════════════════════════════════
class _CmsBulkImportSection extends StatefulWidget {
  const _CmsBulkImportSection();
  @override
  State<_CmsBulkImportSection> createState() => _CmsBulkImportSectionState();
}

class _CmsBulkImportSectionState extends State<_CmsBulkImportSection> {
  List<dynamic> _matieres = [];
  List<dynamic> _simulations = [];
  String? _selectedMatiere;
  String? _selectedSimulation;
  String _destination = 'matiere'; // 'matiere' | 'simulation' | 'examen_type'
  final _textCtrl = TextEditingController();
  bool _loading = false;
  String? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final [matRes, simRes] = await Future.wait([
        _cmsGet('/matieres'),
        _cmsGet('/simulations'),
      ]);
      if (mounted) setState(() {
        _matieres = matRes['matieres'] as List<dynamic>? ?? [];
        _simulations = simRes['simulations'] as List<dynamic>? ?? [];
      });
    } catch (_) {}
  }

  Future<void> _importer() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Collez le contenu à importer');
      return;
    }
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      String url;

      if (_destination == 'matiere') {
        url = '$_cmsBase/questions/bulk-import${_selectedMatiere != null ? '?matiere_id=$_selectedMatiere' : ''}';
        final token = ApiService.token;
        final res = await http.post(Uri.parse(url),
            headers: {'Content-Type': 'text/plain', 'Authorization': 'Bearer $token'},
            body: text);
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (!res.statusCode.toString().startsWith('2')) throw Exception(data['error'] ?? 'Erreur import');
        setState(() => _result = '✅ ${data['imported'] ?? 0} questions importées dans la matière sélectionnée.\n${data['series_created'] ?? 0} série(s) créée(s) automatiquement.');
      } else {
        // Import vers simulation ou examen type
        final titre = _destination == 'simulation' ? 'Examen Blanc — ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}' : 'Examen Type — ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
        final data = await _cmsPost('/examens/bulk-import', {
          'questions_text': text,
          'titre': titre,
          'format': 'md',
          'type': _destination,
          if (_selectedSimulation != null) 'simulation_id': _selectedSimulation,
        });
        if (data['error'] != null) throw Exception(data['error']);
        setState(() => _result = '✅ ${data['imported'] ?? 0} questions importées dans l\'examen "${data['simulation_titre'] ?? titre}".');
      }
    } catch (e) {
      setState(() => _error = '❌ $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Import QCM en Masse', const Color(0xFF7C3AED)),
        const SizedBox(height: 4),
        const Text('Collez vos questions au format Markdown ou Texte brut. Chaque question commence par ## ou un chiffre.',
            style: TextStyle(fontSize: 17, color: Colors.grey)),
        const SizedBox(height: 16),

        // Format aide
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purple.shade200)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📝 Format accepté (Markdown) :', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(8)),
              child: const Text(
                '## Capitale du Burkina Faso ?\nA) Bobo-Dioulasso\nB) Ouagadougou *\nC) Koudougou\nD) Banfora\nExplication: Ouagadougou est la capitale.',
                style: TextStyle(fontFamily: 'monospace', fontSize: 17, color: Colors.white70),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Destination
        const Text('Destination :', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        const SizedBox(height: 8),
        Row(children: [
          _destChip('📚 Matière', 'matiere'),
          const SizedBox(width: 8),
          _destChip('🎯 Simulation', 'simulation'),
          const SizedBox(width: 8),
          _destChip('📝 Examen Type', 'examen_type'),
        ]),
        const SizedBox(height: 12),

        // Sélection matière ou simulation
        if (_destination == 'matiere' && _matieres.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _selectedMatiere,
            hint: const Text('Choisir une matière (optionnel)'),
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('Auto (depuis le fichier)')),
              ..._matieres.map((m) => DropdownMenuItem<String>(
                value: m['id']?.toString(),
                child: Text('${m['code'] ?? ''} — ${m['nom'] ?? ''}', style: const TextStyle(fontSize: 16)),
              )),
            ],
            onChanged: (v) => setState(() => _selectedMatiere = v),
          ),

        if (_destination != 'matiere' && _simulations.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: _selectedSimulation,
            hint: const Text('Créer une nouvelle simulation'),
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('— Nouvelle simulation —')),
              ..._simulations.map((s) => DropdownMenuItem<String>(
                value: s['id']?.toString(),
                child: Text(s['titre']?.toString() ?? '', style: const TextStyle(fontSize: 16)),
              )),
            ],
            onChanged: (v) => setState(() => _selectedSimulation = v),
          ),
        ],
        const SizedBox(height: 14),

        // Zone de texte
        TextField(
          controller: _textCtrl,
          maxLines: 12,
          decoration: InputDecoration(
            hintText: '## Question 1 ?\nA) Option A\nB) Option B *\nC) Option C\nD) Option D\nExplication: ...\n\n## Question 2 ?...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            fillColor: Colors.grey.shade50, filled: true,
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
        ),
        const SizedBox(height: 16),

        // Bouton import
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _importer,
            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.upload_file_rounded, size: 20),
            label: Text(_loading ? 'Import en cours...' : 'Importer les questions', style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (_error != null) Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
          child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
        ),
        if (_result != null) Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
          child: Text(_result!, style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _destChip(String label, String value) {
    final isSelected = _destination == value;
    return GestureDetector(
      onTap: () => setState(() => _destination = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED).withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(fontSize: 17, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade700)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION CMS 3 — SÉRIES
// ══════════════════════════════════════════════════════════════
class _CmsSeriesSection extends StatefulWidget {
  const _CmsSeriesSection();
  @override
  State<_CmsSeriesSection> createState() => _CmsSeriesSectionState();
}

class _CmsSeriesSectionState extends State<_CmsSeriesSection> {
  List<dynamic> _series = [];
  List<dynamic> _matieres = [];
  String? _filterMatiere;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final [serRes, matRes] = await Future.wait([
        _cmsGet('/series${_filterMatiere != null ? '?matiere_id=$_filterMatiere' : ''}'),
        _cmsGet('/matieres'),
      ]);
      if (mounted) setState(() {
        _series = serRes['series'] as List<dynamic>? ?? [];
        _matieres = matRes['matieres'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePublish(String id, bool published) async {
    await _cmsPut('/series/$id', {'published': !published});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFB45309)));
    return Column(
      children: [
        // Filtres matière
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _matiereChip('Toutes', null),
              ..._matieres.take(15).map((m) => _matiereChip(m['code']?.toString() ?? m['nom']?.toString() ?? '', m['id']?.toString())),
            ]),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), color: Colors.grey.shade50,
          child: Row(children: [
            Text('${_series.length} série(s)', style: const TextStyle(fontSize: 17, color: Colors.grey)),
          ]),
        ),
        Expanded(
          child: _series.isEmpty
              ? _buildEmpty('Aucune série', 'Importez des questions pour créer des séries automatiquement')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _series.length,
                    itemBuilder: (_, i) {
                      final s = _series[i] as Map<String, dynamic>;
                      final published = s['published'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: published ? Colors.green.shade200 : Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: const Color(0xFFB45309).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.library_books_rounded, color: Color(0xFFB45309), size: 22),
                          ),
                          title: Text(s['titre']?.toString() ?? s['nom']?.toString() ?? 'Série ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                          subtitle: Text(
                            '${s['nb_questions'] ?? 0} questions • ${s['matiere_nom'] ?? s['matiere_code'] ?? ''}',
                            style: const TextStyle(fontSize: 17, color: Colors.grey),
                          ),
                          trailing: Switch(
                            value: published,
                            activeColor: Colors.green,
                            onChanged: (_) => _togglePublish(s['id']?.toString() ?? '', published),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _matiereChip(String label, String? value) {
    final isSelected = _filterMatiere == value;
    return GestureDetector(
      onTap: () { setState(() => _filterMatiere = value); _load(); },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB45309) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(fontSize: 17, color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION CMS 4 — SIMULATIONS & EXAMENS
// ══════════════════════════════════════════════════════════════
class _CmsSimulationsSection extends StatefulWidget {
  const _CmsSimulationsSection();
  @override
  State<_CmsSimulationsSection> createState() => _CmsSimulationsSectionState();
}

class _CmsSimulationsSectionState extends State<_CmsSimulationsSection> {
  List<dynamic> _simulations = [];
  bool _loading = true;
  bool _showCreate = false;
  List<dynamic> _matieres = [];
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _duree = 120;
  List<Map<String, dynamic>> _questionSelections = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final [simRes, matRes] = await Future.wait([_cmsGet('/simulations'), _cmsGet('/matieres')]);
      if (mounted) setState(() {
        _simulations = simRes['simulations'] as List<dynamic>? ?? [];
        _matieres = matRes['matieres'] as List<dynamic>? ?? [];
        _questionSelections = _matieres.take(8).map((m) => {
          'id': m['id'], 'code': m['code'], 'nom': m['nom'], 'count': 0
        }).toList();
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _togglePublish(String id, bool published) async {
    await _cmsPut('/simulations/$id', {'published': !published});
    _load();
  }

  Future<void> _deleteSimulation(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Supprimer la simulation ?'),
      content: const Text('Cette action est irréversible.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (confirm != true) return;
    await _cmsDelete('/simulations/$id');
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Supprimée'), backgroundColor: Color(0xFF1A5C38))); _load(); }
  }

  Future<void> _createSimulation() async {
    if (_titreCtrl.text.trim().isEmpty) return;
    final totalQ = _questionSelections.fold<int>(0, (s, m) => s + (m['count'] as int));
    if (totalQ == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoutez des questions'), backgroundColor: Colors.orange));
      return;
    }
    final allocations = _questionSelections.where((m) => (m['count'] as int) > 0)
        .map((m) => {'matiere_id': m['id'], 'count': m['count']}).toList();

    final data = await _cmsPost('/exam-generator/generate', {
      'titre': _titreCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'duree_minutes': _duree,
      'destination': 'simulation',
      'allocations': allocations,
    });
    if (mounted) {
      if (data['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${data['error']}'), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${data['message'] ?? 'Examen créé !'}'), backgroundColor: AppColors.success));
        setState(() { _showCreate = false; _titreCtrl.clear(); _descCtrl.clear(); });
        _load();
      }
    }
  }

  int get _totalQuestions => _questionSelections.fold(0, (s, m) => s + (m['count'] as int));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFCE1126)));
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12), color: Colors.white,
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Simulations & Examens', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              Text('${_simulations.length} examen(s) créé(s)', style: const TextStyle(fontSize: 17, color: Colors.grey)),
            ]),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showCreate = !_showCreate),
              icon: Icon(_showCreate ? Icons.close : Icons.add),
              label: Text(_showCreate ? 'Annuler' : 'Créer'),
              style: ElevatedButton.styleFrom(backgroundColor: _showCreate ? Colors.grey : const Color(0xFFCE1126), foregroundColor: Colors.white),
            ),
          ]),
        ),
        Expanded(child: _showCreate ? _buildCreateForm() : _buildList()),
      ],
    );
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Créer un examen/simulation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFCE1126))),
        const Text('Composez un examen en sélectionnant les questions par matière', style: TextStyle(fontSize: 17, color: Colors.grey)),
        const SizedBox(height: 14),
        TextField(controller: _titreCtrl, decoration: InputDecoration(labelText: 'Titre *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 10),
        TextField(controller: _descCtrl, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _duree,
          decoration: InputDecoration(labelText: 'Durée', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          items: [60, 90, 120, 150, 180, 240].map((d) => DropdownMenuItem(value: d, child: Text('${d ~/ 60}h${d % 60 == 0 ? '00' : d % 60}min'))).toList(),
          onChanged: (v) => setState(() => _duree = v!),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Text('Questions par matière', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: _totalQuestions > 0 ? const Color(0xFF1A5C38) : Colors.grey, borderRadius: BorderRadius.circular(12)),
            child: Text('Total: $_totalQuestions Q', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ]),
        const SizedBox(height: 10),
        ..._questionSelections.map((sel) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: Text('${sel['code']} — ${(sel['nom'] as String).substring(0, (sel['nom'] as String).length.clamp(0, 28))}', style: const TextStyle(fontSize: 17))),
              Row(children: [
                IconButton(onPressed: sel['count'] > 0 ? () => setState(() => sel['count'] = (sel['count'] as int) - 1) : null, icon: const Icon(Icons.remove_circle_outline, size: 20), color: const Color(0xFFCE1126)),
                SizedBox(width: 28, child: Text('${sel['count']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
                IconButton(onPressed: () => setState(() => sel['count'] = (sel['count'] as int) + 1), icon: const Icon(Icons.add_circle_outline, size: 20), color: const Color(0xFF1A5C38)),
              ]),
            ]),
          );
        }),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.rocket_launch_rounded),
            label: Text('Créer l\'examen ($_totalQuestions questions)'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCE1126), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _totalQuestions > 0 ? _createSimulation : null,
          ),
        ),
      ]),
    );
  }

  Widget _buildList() {
    if (_simulations.isEmpty) return _buildEmpty('Aucune simulation', 'Créez votre premier examen');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _simulations.length,
        itemBuilder: (_, i) {
          final s = _simulations[i] as Map<String, dynamic>;
          final published = s['published'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: published ? Colors.green.shade200 : Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFFCE1126).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.timer_rounded, color: Color(0xFFCE1126), size: 24),
              ),
              title: Text(s['titre']?.toString() ?? 'Simulation', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${s['nb_questions'] ?? 0} questions • ${s['duree_minutes'] ?? 120} min', style: const TextStyle(fontSize: 17, color: Colors.grey)),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: published ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(published ? '✅ Publiée' : '📝 Brouillon', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: published ? Colors.green.shade700 : Colors.orange.shade700)),
                  ),
                ]),
              ]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: Icon(published ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: published ? Colors.orange : Colors.green, size: 22),
                  onPressed: () => _togglePublish(s['id']?.toString() ?? '', published),
                  tooltip: published ? 'Dépublier' : 'Publier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 22),
                  onPressed: () => _deleteSimulation(s['id']?.toString() ?? ''),
                  tooltip: 'Supprimer',
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION CMS 5 — GÉNÉRATEUR D'EXAMENS COMPOSITES
// ══════════════════════════════════════════════════════════════
class _CmsExamGeneratorSection extends StatefulWidget {
  const _CmsExamGeneratorSection();
  @override
  State<_CmsExamGeneratorSection> createState() => _CmsExamGeneratorSectionState();
}

class _CmsExamGeneratorSectionState extends State<_CmsExamGeneratorSection> {
  List<dynamic> _matieres = [];
  List<Map<String, dynamic>> _allocations = [];
  final _titreCtrl = TextEditingController();
  int _duree = 60;
  bool _loading = false;
  String? _result;
  String? _error;

  @override
  void initState() { super.initState(); _loadMatieres(); }

  Future<void> _loadMatieres() async {
    try {
      final d = await _cmsGet('/matieres');
      if (mounted) setState(() => _matieres = d['matieres'] as List<dynamic>? ?? []);
    } catch (_) {}
  }

  int get _total => _allocations.fold(0, (s, a) => s + (a['count'] as int));

  void _toggleMatiere(Map<String, dynamic> mat) {
    final id = mat['id']?.toString() ?? '';
    setState(() {
      if (_allocations.any((a) => a['matiereId'] == id)) {
        _allocations.removeWhere((a) => a['matiereId'] == id);
      } else {
        _allocations.add({'matiereId': id, 'nom': mat['nom'], 'count': 10});
      }
    });
  }

  Future<void> _generer() async {
    if (_titreCtrl.text.trim().isEmpty) { setState(() => _error = 'Donnez un titre à l\'examen'); return; }
    if (_allocations.isEmpty) { setState(() => _error = 'Sélectionnez au moins une matière'); return; }
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final data = await _cmsPost('/exam-generator/generate', {
        'titre': _titreCtrl.text.trim(),
        'duree_minutes': _duree,
        'destination': 'simulation',
        'allocations': _allocations.map((a) => {'matiere_id': a['matiereId'], 'count': a['count']}).toList(),
      });
      if (data['error'] != null) throw Exception(data['error']);
      setState(() => _result = '✅ Examen "${data['titre'] ?? _titreCtrl.text}" créé avec ${data['total_questions'] ?? _total} questions !\n\nÀ publier depuis la section "Examens".');
    } catch (e) {
      setState(() => _error = '❌ $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Générateur d\'Examens Composites', const Color(0xFF0891B2)),
        const SizedBox(height: 4),
        const Text('Composez un examen en puisant des questions dans plusieurs matières.', style: TextStyle(fontSize: 17, color: Colors.grey)),
        const SizedBox(height: 16),

        // Titre
        TextField(controller: _titreCtrl, decoration: InputDecoration(labelText: 'Titre de l\'examen *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), hintText: 'Ex: Concours 2026 — Épreuve Générale')),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _duree,
          decoration: InputDecoration(labelText: 'Durée', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          items: [30, 60, 90, 120, 150, 180, 240].map((d) => DropdownMenuItem(value: d, child: Text('${d ~/ 60}h${d % 60 == 0 ? '00' : d % 60}min'))).toList(),
          onChanged: (v) => setState(() => _duree = v!),
        ),
        const SizedBox(height: 16),

        // Allocation par matière
        if (_allocations.isNotEmpty) ...[
          Row(children: [
            const Text('Répartition sélectionnée', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF0891B2), borderRadius: BorderRadius.circular(12)),
              child: Text('$_total Q', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ]),
          const SizedBox(height: 10),
          ..._allocations.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: Text(a['nom']?.toString() ?? '', style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis)),
              Row(children: [
                IconButton(onPressed: a['count'] > 1 ? () => setState(() => a['count'] = a['count'] - 1) : null, icon: const Icon(Icons.remove_circle_outline, size: 20), color: Colors.red),
                SizedBox(width: 36, child: Text('${a['count']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                IconButton(onPressed: () => setState(() => a['count'] = a['count'] + 1), icon: const Icon(Icons.add_circle_outline, size: 20), color: const Color(0xFF0891B2)),
                IconButton(onPressed: () => setState(() => _allocations.removeWhere((x) => x['matiereId'] == a['matiereId'])), icon: const Icon(Icons.close, size: 18), color: Colors.grey),
              ]),
            ]),
          )),
          const Divider(),
          const SizedBox(height: 8),
        ],

        // Sélection matières
        const Text('Ajouter des matières :', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _matieres.map((mat) {
            final id = mat['id']?.toString() ?? '';
            final isSelected = _allocations.any((a) => a['matiereId'] == id);
            return GestureDetector(
              onTap: () => _toggleMatiere(mat as Map<String, dynamic>),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0891B2).withValues(alpha: 0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? const Color(0xFF0891B2) : Colors.grey.shade300),
                ),
                child: Text(
                  isSelected ? '✓ ${mat['nom']}' : mat['nom']?.toString() ?? '',
                  style: TextStyle(fontSize: 17, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? const Color(0xFF0891B2) : Colors.grey.shade700),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Bouton générer
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _generer,
            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.rocket_launch_rounded, size: 20),
            label: Text(_loading ? 'Génération...' : 'Générer l\'examen ($_total QCM)', style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0891B2), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_error != null) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16))),
        if (_result != null) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)), child: Text(_result!, style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ONGLET 4 — ANNONCES
// ══════════════════════════════════════════════════════════════
class _AnnoncesTab extends StatefulWidget {
  const _AnnoncesTab();
  @override
  State<_AnnoncesTab> createState() => _AnnoncesTabState();
}

class _AnnoncesTabState extends State<_AnnoncesTab> {
  List<dynamic> _annonces = [];
  bool _loading = true;
  bool _publishing = false;
  final _titreCtrl = TextEditingController();
  final _contenuCtrl = TextEditingController();
  String _categorie = 'ACTUALITE';
  bool _showForm = false;

  @override
  void initState() { super.initState(); _loadAnnonces(); }

  Future<void> _loadAnnonces() async {
    setState(() => _loading = true);
    try {
      final token = ApiService.token;
      final res = await http.get(Uri.parse('$_baseUrl/api/actualites'), headers: {'Authorization': 'Bearer $token'});
      final data = jsonDecode(res.body);
      if (mounted) setState(() {
        _annonces = (data as Map<String, dynamic>)['actualites'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _publier() async {
    if (_titreCtrl.text.trim().isEmpty || _contenuCtrl.text.trim().isEmpty) return;
    setState(() => _publishing = true);
    final result = await ApiService.addActualite({
      'titre': _titreCtrl.text.trim(),
      'contenu': _contenuCtrl.text.trim(),
      'categorie': _categorie,
    });
    if (mounted) {
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] == true ? '✅ Annonce publiée !' : '❌ ${result['error'] ?? 'Erreur'}'),
        backgroundColor: result['success'] == true ? AppColors.success : AppColors.error,
      ));
      if (result['success'] == true) {
        _titreCtrl.clear(); _contenuCtrl.clear();
        setState(() => _showForm = false);
        _loadAnnonces();
      }
    }
  }

  Future<void> _deleteAnnonce(String id) async {
    final token = ApiService.token;
    await http.delete(Uri.parse('$_baseUrl/api/actualites/$id'), headers: {'Authorization': 'Bearer $token'});
    if (mounted) { _loadAnnonces(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annonce supprimée'), backgroundColor: Colors.orange)); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14), color: Colors.white,
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Gestion des Annonces', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              Text('${_annonces.length} annonce(s) publiée(s)', style: const TextStyle(fontSize: 17, color: Colors.grey)),
            ]),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showForm = !_showForm),
              icon: Icon(_showForm ? Icons.close : Icons.add_circle_rounded, size: 18),
              label: Text(_showForm ? 'Annuler' : 'Publier'),
              style: ElevatedButton.styleFrom(backgroundColor: _showForm ? Colors.grey : AppColors.primary, foregroundColor: Colors.white),
            ),
          ]),
        ),
        // Formulaire de publication
        if (_showForm) Container(
          padding: const EdgeInsets.all(16), color: Colors.grey.shade50,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: _titreCtrl, decoration: InputDecoration(labelText: 'Titre de l\'annonce *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 10),
            TextField(controller: _contenuCtrl, maxLines: 4, decoration: InputDecoration(labelText: 'Contenu de l\'annonce *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _categorie,
              decoration: InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
              items: const [
                DropdownMenuItem(value: 'ACTUALITE', child: Text('📰 Actualité')),
                DropdownMenuItem(value: 'CONCOURS', child: Text('📋 Concours')),
                DropdownMenuItem(value: 'ALERTE', child: Text('🚨 Alerte')),
                DropdownMenuItem(value: 'GENERAL', child: Text('📢 Général')),
              ],
              onChanged: (v) => setState(() => _categorie = v!),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _publishing ? null : _publier,
                icon: _publishing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18),
                label: Text(_publishing ? 'Publication...' : 'Publier l\'annonce', style: const TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
        ),
        // Liste annonces
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _annonces.isEmpty
                  ? _buildEmpty('Aucune annonce', 'Publiez votre première annonce')
                  : RefreshIndicator(
                      onRefresh: _loadAnnonces,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _annonces.length,
                        itemBuilder: (_, i) {
                          final a = _annonces[i] as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                              leading: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.newspaper_rounded, color: AppColors.primary, size: 20),
                              ),
                              title: Text(a['titre']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(a['contenu']?.toString() ?? '', style: const TextStyle(fontSize: 17, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                                if (a['created_at'] != null) Text(_formatDate(a['created_at'].toString()), style: const TextStyle(fontSize: 17, color: Colors.grey)),
                              ]),
                              trailing: IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 22), onPressed: () => _deleteAnnonce(a['id']?.toString() ?? ''), tooltip: 'Supprimer'),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) { return dateStr.substring(0, 10.clamp(0, dateStr.length)); }
  }
}

// ══════════════════════════════════════════════════════════════
// ONGLET 5 — CHANGEMENT DE MOT DE PASSE
// ══════════════════════════════════════════════════════════════
class _ChangePasswordTab extends StatefulWidget {
  const _ChangePasswordTab();
  @override
  State<_ChangePasswordTab> createState() => _ChangePasswordTabState();
}

class _ChangePasswordTabState extends State<_ChangePasswordTab> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;
  String? _error;
  String? _success;

  int get _strength {
    final p = _newCtrl.text;
    if (p.isEmpty) return 0;
    if (p.length < 6) return 1;
    if (p.length < 10) return 2;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[0-9]').hasMatch(p) && RegExp(r'[^a-zA-Z0-9]').hasMatch(p)) return 4;
    return 3;
  }

  Future<void> _changePassword() async {
    setState(() { _error = null; _success = null; });
    final current = _currentCtrl.text.trim();
    final newPwd = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.isEmpty) { setState(() => _error = 'Saisissez votre mot de passe actuel'); return; }
    if (newPwd.length < 8) { setState(() => _error = 'Au moins 8 caractères requis'); return; }
    if (!RegExp(r'[A-Z]').hasMatch(newPwd)) { setState(() => _error = 'Au moins une lettre majuscule requise'); return; }
    if (!RegExp(r'[0-9]').hasMatch(newPwd)) { setState(() => _error = 'Au moins un chiffre requis'); return; }
    if (newPwd != confirm) { setState(() => _error = 'Les mots de passe ne correspondent pas'); return; }
    if (newPwd == current) { setState(() => _error = 'Le nouveau mot de passe doit être différent'); return; }

    setState(() => _loading = true);
    try {
      final token = ApiService.token;
      if (token == null || token.isEmpty) {
        if (mounted) setState(() { _error = 'Session expirée. Veuillez vous déconnecter et vous reconnecter.'; _loading = false; });
        return;
      }
      final res = await http.post(
        Uri.parse('$_baseUrl/api/admin/change-password'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'current_password': current, 'new_password': newPwd}),
      ).timeout(const Duration(seconds: 15));
      
      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}
      
      if (res.statusCode == 401) {
        // Mot de passe actuel incorrect
        if (mounted) setState(() { 
          _error = data['error']?.toString() ?? 'Mot de passe actuel incorrect. Vérifiez et réessayez.'; 
          _loading = false; 
        });
        return;
      }
      if (res.statusCode == 403) {
        if (mounted) setState(() { 
          _error = 'Accès refusé. Votre session admin est peut-être expirée. Reconnectez-vous.'; 
          _loading = false; 
        });
        return;
      }
      if (res.statusCode >= 400) {
        if (mounted) setState(() { 
          _error = data['error']?.toString() ?? 'Erreur serveur (${res.statusCode}). Réessayez.'; 
          _loading = false; 
        });
        return;
      }
      
      if (mounted) {
        setState(() {
          _success = '✅ Mot de passe changé avec succès ! Reconnectez-vous pour des raisons de sécurité.';
          _loading = false;
          _error = null;
        });
        _currentCtrl.clear(); _newCtrl.clear(); _confirmCtrl.clear();
      }
    } catch (e) {
      if (mounted) setState(() { 
        _error = e.toString().replaceAll('Exception: ', ''); 
        _loading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strengthColors = [Colors.transparent, Colors.red, Colors.orange, Colors.green, const Color(0xFF1A5C38)];
    final strengthLabels = ['', 'Faible', 'Moyen', 'Fort', 'Très fort'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // En-tête
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A5C38), Color(0xFF0f3d26)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.security_rounded, color: Colors.white, size: 28)),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sécurité du Compte', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(height: 4),
              Text('Changez votre mot de passe régulièrement pour protéger le panel admin', style: TextStyle(fontSize: 17, color: Colors.white70)),
            ])),
          ]),
        ),
        const SizedBox(height: 24),

        // Formulaire
        _pwdField('Mot de passe actuel', _currentCtrl, _showCurrent, () => setState(() => _showCurrent = !_showCurrent)),
        const SizedBox(height: 14),
        _pwdField('Nouveau mot de passe', _newCtrl, _showNew, () => setState(() => _showNew = !_showNew)),

        // Indicateur de force
        if (_newCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: List.generate(4, (i) => Expanded(
            child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), height: 4, decoration: BoxDecoration(
              color: i < _strength ? strengthColors[_strength] : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            )),
          ))),
          const SizedBox(height: 4),
          Text(strengthLabels[_strength], style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: strengthColors[_strength])),
        ],
        const SizedBox(height: 14),
        _pwdField('Confirmer le nouveau mot de passe', _confirmCtrl, _showConfirm, () => setState(() => _showConfirm = !_showConfirm), matchValue: _newCtrl.text),
        const SizedBox(height: 12),

        // Critères
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Critères :', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            ...[
              ('8 caractères minimum', _newCtrl.text.length >= 8),
              ('1 lettre majuscule', RegExp(r'[A-Z]').hasMatch(_newCtrl.text)),
              ('1 chiffre', RegExp(r'[0-9]').hasMatch(_newCtrl.text)),
              ('Différent de l\'actuel', _newCtrl.text.isNotEmpty && _newCtrl.text != _currentCtrl.text),
            ].map((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Icon(c.$2 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: c.$2 ? AppColors.success : Colors.grey),
                const SizedBox(width: 8),
                Text(c.$1, style: TextStyle(fontSize: 16, color: c.$2 ? AppColors.textDark : Colors.grey)),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 20),

        if (_error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))), child: Text('❌ $_error', style: const TextStyle(color: AppColors.error, fontSize: 16))),
        if (_success != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))), child: Text(_success!, style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w600))),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _changePassword,
            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.lock_reset_rounded, size: 20),
            label: Text(_loading ? 'Modification...' : 'Changer le mot de passe', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2))),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡 Conseils de sécurité', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.secondary)),
            SizedBox(height: 8),
            Text('• Changez votre mot de passe après chaque déploiement\n• Utilisez 12+ caractères avec des symboles spéciaux\n• Ne partagez jamais votre mot de passe admin', style: TextStyle(fontSize: 17, color: Colors.grey, height: 1.7)),
          ]),
        ),
      ]),
    );
  }

  Widget _pwdField(String label, TextEditingController ctrl, bool show, VoidCallback toggle, {String? matchValue}) {
    final isMatch = matchValue != null && ctrl.text.isNotEmpty && ctrl.text == matchValue;
    final noMatch = matchValue != null && ctrl.text.isNotEmpty && ctrl.text != matchValue;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: !show,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isMatch ? AppColors.success : noMatch ? AppColors.error : Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isMatch ? AppColors.success : noMatch ? AppColors.error : AppColors.primary, width: 2)),
          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: Colors.grey), onPressed: toggle),
        ),
      ),
      if (isMatch) const Padding(padding: EdgeInsets.only(top: 4), child: Text('✓ Les mots de passe correspondent', style: TextStyle(color: AppColors.success, fontSize: 17))),
      if (noMatch) const Padding(padding: EdgeInsets.only(top: 4), child: Text('✗ Les mots de passe ne correspondent pas', style: TextStyle(color: AppColors.error, fontSize: 17))),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET CARTE QUESTION
// ══════════════════════════════════════════════════════════════
class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _QuestionCard({required this.question, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final enonce = question['enonce']?.toString() ?? question['question']?.toString() ?? '';
    final bonneRep = question['bonne_reponse']?.toString() ?? '';
    final matiere = question['matiere_nom']?.toString() ?? question['matiere_code']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (matiere.isNotEmpty) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF1A5C38).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(matiere, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A5C38))),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text('Rép: $bonneRep', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.blue.shade700)),
          ),
          const SizedBox(width: 4),
          GestureDetector(onTap: onEdit, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.edit_rounded, size: 16, color: Colors.orange.shade700))),
          const SizedBox(width: 4),
          GestureDetector(onTap: onDelete, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.delete_rounded, size: 16, color: Colors.red.shade700))),
        ]),
        const SizedBox(height: 8),
        Text(enonce, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('A: ${question['option_a']?.toString() ?? ''}', style: const TextStyle(fontSize: 17, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Expanded(child: Text('B: ${question['option_b']?.toString() ?? ''}', style: const TextStyle(fontSize: 17, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ]),
    );
  }
}

// ── Helpers communs ───────────────────────────────────────────
Widget _sectionTitle(String title, Color color) {
  return Row(children: [
    Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 10),
    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
  ]);
}

Widget _buildError(String error, VoidCallback onRetry) {
  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
    const SizedBox(height: 12),
    Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
    const SizedBox(height: 16),
    ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Réessayer'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
  ]));
}

Widget _buildEmpty(String title, String subtitle) {
  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
    const SizedBox(height: 16),
    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.grey)),
    const SizedBox(height: 6),
    Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
  ]));
}
