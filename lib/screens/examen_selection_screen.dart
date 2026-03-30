import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import 'simulation_screen.dart';

/// PHASE 4 — Écran de sélection des examens
/// - Onglet 1 : Examens Blancs publiés par l'Admin (NOUVEAUTÉS)
/// - Onglet 2 : 10 Examens professionnels classiques
class ExamenSelectionScreen extends StatefulWidget {
  const ExamenSelectionScreen({super.key});

  @override
  State<ExamenSelectionScreen> createState() => _ExamenSelectionScreenState();
}

class _ExamenSelectionScreenState extends State<ExamenSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _examens = [];
  List<dynamic> _simulationsAdmin = [];
  bool _loading = true;
  bool _loadingSimulations = true;

  static const List<Map<String, dynamic>> _fallbackExamens = [
    {'id': 'exam_001', 'nom': 'Administration générale', 'description': 'Adjoints administratifs, agents administratifs', 'couleur': '#1A5C38', 'icone': '📋', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 1},
    {'id': 'exam_002', 'nom': 'Justice & sécurité', 'description': 'Greffiers, police nationale, gendarmerie, douane', 'couleur': '#C0392B', 'icone': '⚖️', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 2},
    {'id': 'exam_003', 'nom': 'Économie & finances', 'description': 'Impôts, trésor public, contrôleurs des finances', 'couleur': '#27AE60', 'icone': '💰', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 3},
    {'id': 'exam_004', 'nom': 'Concours de la santé', 'description': 'Infirmiers, sages-femmes, agents de santé', 'couleur': '#8E44AD', 'icone': '⚕️', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 4},
    {'id': 'exam_005', 'nom': 'Éducation & formation', 'description': 'Enseignants du primaire et du secondaire', 'couleur': '#2980B9', 'icone': '🎓', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 5},
    {'id': 'exam_006', 'nom': 'Concours techniques', 'description': 'Techniciens génie civil, électricité, mécanique', 'couleur': '#D4A017', 'icone': '🔧', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 6},
    {'id': 'exam_007', 'nom': 'Agriculture & environnement', 'description': 'Agents agricoles, élevage, environnement', 'couleur': '#16A085', 'icone': '🌾', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 7},
    {'id': 'exam_008', 'nom': 'Informatique & numérique', 'description': 'Techniciens informatiques, développeurs', 'couleur': '#2ECC71', 'icone': '💻', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 8},
    {'id': 'exam_009', 'nom': 'Travaux publics & urbanisme', 'description': 'BTP, urbanisme, topographie', 'couleur': '#9B59B6', 'icone': '🏗️', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 9},
    {'id': 'exam_010', 'nom': 'Statistiques & planification', 'description': 'Statisticiens, économistes, planificateurs', 'couleur': '#34495E', 'icone': '📊', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 10},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadExamens(), _loadSimulationsAdmin()]);
  }

  Future<void> _loadExamens() async {
    setState(() { _loading = true; });
    try {
      final data = await ApiService.getExamens();
      if (mounted) {
        setState(() {
          _examens = data.isNotEmpty ? data : _fallbackExamens;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _examens = _fallbackExamens;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadSimulationsAdmin() async {
    setState(() { _loadingSimulations = true; });
    try {
      final data = await ApiService.getSimulationsAdmin();
      if (mounted) {
        setState(() {
          _simulationsAdmin = data;
          _loadingSimulations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _simulationsAdmin = [];
          _loadingSimulations = false;
        });
      }
    }
  }

  Color _parseColor(String? hex) {
    try {
      return Color(int.parse('0xFF${(hex ?? '#1A5C38').replaceAll('#', '')}'));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          ),
        ),
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Mode Examen',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎯 Examens Blancs'),
                  if (_simulationsAdmin.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_simulationsAdmin.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: '📋 Examens Types'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── ONGLET 1 : Examens Blancs Admin ──
          _buildExamensBlancsTab(),
          // ── ONGLET 2 : Examens Types Classiques ──
          _buildExamensTypesTab(),
        ],
      ),
    );
  }

  // ─── ONGLET EXAMENS BLANCS ────────────────────────────────────
  Widget _buildExamensBlancsTab() {
    if (_loadingSimulations) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_simulationsAdmin.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Aucun examen blanc disponible',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'L\'administrateur n\'a pas encore\npublié d\'examen blanc.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadSimulationsAdmin,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSimulationsAdmin,
      color: AppColors.primary,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primary.withValues(alpha: 0.06),
            child: Text(
              '${_simulationsAdmin.length} examen(s) blanc(s) publié(s) par l\'administration',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _simulationsAdmin.length,
              itemBuilder: (ctx, i) => _buildSimulationAdminCard(_simulationsAdmin[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationAdminCard(dynamic sim, int index) {
    final titre = sim['titre']?.toString() ?? 'Examen Blanc ${index + 1}';
    final description = sim['description']?.toString() ?? '';
    final duree = sim['duree_minutes'] as int? ?? 90;
    final totalQ = sim['total_questions'] as int? ?? 0;
    final colors = [
      AppColors.primary, const Color(0xFF2980B9), const Color(0xFFD4A017),
      const Color(0xFFC0392B), const Color(0xFF8E44AD), const Color(0xFF16A085),
    ];
    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () {
        if (!ApiService.isAbonne && !ApiService.isAdmin) {
          _showAbonnementDialog();
          return;
        }
        final user = ApiService.currentUser;
        final nom = user != null ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim() : 'Candidat';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamWelcomeSlide(
              candidatName: nom.isNotEmpty ? nom : 'Candidat',
              examenNom: titre,
              simulationAdminId: sim['id']?.toString(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Badge numéro
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'EXAMEN BLANC OFFICIEL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      titre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _badge('$totalQ questions', color),
                        const SizedBox(width: 8),
                        _badge('$duree min', color),
                        if (!ApiService.isAbonne && !ApiService.isAdmin) ...[
                          const SizedBox(width: 8),
                          _badge('🔒 Premium', Colors.orange),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 26),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ONGLET EXAMENS TYPES ──────────────────────────────────────
  Widget _buildExamensTypesTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.primary.withValues(alpha: 0.06),
          child: const Text(
            '10 examens professionnels · 50 questions · 1h30',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadExamens,
            color: AppColors.primary,
            child: GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              itemCount: _examens.length,
              itemBuilder: (ctx, i) => _buildExamenCard(_examens[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamenCard(dynamic examen) {
    final color = _parseColor(examen['couleur']?.toString());
    final nom = examen['nom'] as String? ?? '';
    final description = examen['description'] as String? ?? '';
    final icone = examen['icone'] as String? ?? '📋';

    return GestureDetector(
      onTap: () {
        final user = ApiService.currentUser;
        final nomCandidat = user != null
            ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
            : 'Candidat';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamWelcomeSlide(
              candidatName: nomCandidat.isNotEmpty ? nomCandidat : 'Candidat',
              examenNom: nom,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Center(child: Text(icone, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(height: 8),
              Text(
                nom,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.black45, height: 1.3),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _badge('50 q.', color),
                  const SizedBox(width: 6),
                  _badge('1h30', color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  void _showAbonnementDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('👑', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Accès Premium', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Les examens blancs sont réservés aux abonnés Premium.\n\nAbonnez-vous pour y accéder et pratiquer dans des conditions réelles.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("S'abonner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
