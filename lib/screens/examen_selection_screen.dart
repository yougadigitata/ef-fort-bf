import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import 'simulation_screen.dart';
import 'examen_screen.dart';

/// v7.0 — Écran de sélection des examens — Nouveau design coloré
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

  // Couleurs par catégorie pour le design coloré
  static const Map<String, Color> _examColors = {
    'exam_001': Color(0xFF2980B9),  // Bleu - Administration
    'exam_002': Color(0xFFC0392B),  // Rouge - Justice
    'exam_003': Color(0xFF27AE60),  // Vert - Finances
    'exam_004': Color(0xFF8E44AD),  // Violet - Santé
    'exam_005': Color(0xFF2980B9),  // Bleu - Éducation
    'exam_006': Color(0xFFD4A017),  // Or - Technique
    'exam_007': Color(0xFF27AE60),  // Vert - Agriculture
    'exam_008': Color(0xFF16A085),  // Turquoise - Informatique
    'exam_009': Color(0xFF8E44AD),  // Violet - TP
    'exam_010': Color(0xFF5D6D7E),  // Gris - Stats
  };

  static const List<Map<String, dynamic>> _fallbackExamens = [
    {'id': 'exam_001', 'nom': 'Administration générale', 'description': 'Adjoints administratifs, agents administratifs', 'couleur': '#2980B9', 'icone': '🎓', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 1},
    {'id': 'exam_002', 'nom': 'Justice & sécurité', 'description': 'Greffiers, police nationale, gendarmerie, douane', 'couleur': '#C0392B', 'icone': '⚖️', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 2},
    {'id': 'exam_003', 'nom': 'Économie & finances', 'description': 'Impôts, trésor public, contrôleurs des finances', 'couleur': '#27AE60', 'icone': '💰', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 3},
    {'id': 'exam_004', 'nom': 'Concours de la santé', 'description': 'Infirmiers, sages-femmes, agents de santé', 'couleur': '#8E44AD', 'icone': '⚕️', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 4},
    {'id': 'exam_005', 'nom': 'Éducation & formation', 'description': 'Enseignants du primaire, enseignants du second…', 'couleur': '#2980B9', 'icone': '🎓', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 5},
    {'id': 'exam_006', 'nom': 'Concours techniques', 'description': 'Techniciens génie civil, électricité, mécanique, s…', 'couleur': '#D4A017', 'icone': '🔧', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 6},
    {'id': 'exam_007', 'nom': 'Agriculture & environnement', 'description': 'Agents agricoles, élevage, environnement,…', 'couleur': '#27AE60', 'icone': '🌾', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 7},
    {'id': 'exam_008', 'nom': 'Informatique & numérique', 'description': 'Techniciens informatiques, développement,…', 'couleur': '#16A085', 'icone': '💻', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 8},
    {'id': 'exam_009', 'nom': 'Travaux publics & urbanisme', 'description': 'BTP, urbanisme, infrastructures,…', 'couleur': '#8E44AD', 'icone': '🏗️', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 9},
    {'id': 'exam_010', 'nom': 'Statistiques & planification', 'description': 'Statisticiens, planification, analyse de données,…', 'couleur': '#5D6D7E', 'icone': '📊', 'nombre_questions': 50, 'duree_minutes': 90, 'ordre': 10},
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

  // Obtenir la couleur par index ou par ID
  Color _getExamColor(dynamic examen, int index) {
    final id = examen['id']?.toString() ?? '';
    if (_examColors.containsKey(id)) return _examColors[id]!;
    final hex = examen['couleur']?.toString();
    if (hex != null && hex.isNotEmpty) return _parseColor(hex);
    // Fallback couleurs par index
    const fallbackColors = [
      Color(0xFF2980B9), Color(0xFFD4A017), Color(0xFF27AE60),
      Color(0xFF16A085), Color(0xFF8E44AD), Color(0xFF5D6D7E),
      Color(0xFFC0392B), Color(0xFFE67E22), Color(0xFF1A5C38),
      Color(0xFF2ECC71),
    ];
    return fallbackColors[index % fallbackColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F1),
      body: Column(
        children: [
          // ── Header dégradé vert ──────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              bottom: 0,
              left: 20,
              right: 20,
            ),
            child: Column(
              children: [
                // Titre et sous-titre
                const Text(
                  'Choisir votre Concours',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '10 examens professionnels • 50 questions • 1h30',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // TabBar
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorSize: TabBarIndicatorSize.label,
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
              ],
            ),
          ),

          // ── Contenu ──────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExamensBlancsTab(),
                _buildExamensTypesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ONGLET EXAMENS BLANCS ──────────────────────────────────
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              "L'administrateur n'a pas encore\npublié d'examen blanc.",
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              '${_simulationsAdmin.length} examen(s) blanc(s) publié(s)',
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
        final nom = user != null
            ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
            : 'Candidat';
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
                        _buildPillBadge('$totalQ questions', color),
                        const SizedBox(width: 8),
                        _buildPillBadge('$duree min', color, icon: Icons.access_time_rounded),
                        if (!ApiService.isAbonne && !ApiService.isAdmin) ...[
                          const SizedBox(width: 8),
                          _buildPillBadge('🔒 Premium', Colors.orange),
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

  // ─── ONGLET EXAMENS TYPES ────────────────────────────────────
  Widget _buildExamensTypesTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return RefreshIndicator(
      onRefresh: _loadExamens,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        itemCount: _examens.length,
        itemBuilder: (ctx, i) => _buildExamenCard(_examens[i], i),
      ),
    );
  }

  Widget _buildExamenCard(dynamic examen, int index) {
    final color = _getExamColor(examen, index);
    final nom = examen['nom'] as String? ?? '';
    final description = examen['description'] as String? ?? '';
    final icone = examen['icone'] as String? ?? '📋';
    final nbQ = examen['nombre_questions'] as int? ?? 50;
    final duree = examen['duree_minutes'] as int? ?? 90;
    final dureeStr = duree >= 60
        ? '${duree ~/ 60}h${duree % 60 > 0 ? (duree % 60).toString().padLeft(2, '0') : ''}'
        : '${duree}min';
    final examenId = examen['id'] as String? ?? '';

    void lancerSerie(int serie) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamenScreen(
            examenId: examenId,
            nomExamen: serie == 2 ? '$nom — Série 2' : nom,
            couleur: color,
            serie: serie,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Icône sur pastille colorée ─────────────────
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(icone, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 7),

            // ── Nom du concours ────────────────────────────
            Text(
              nom,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),

            // ── Description ────────────────────────────────
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                color: Colors.black45,
                height: 1.3,
              ),
            ),

            const Spacer(),

            // ── Badges pilules ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPillBadge('$nbQ q.', color),
                const SizedBox(width: 5),
                _buildPillBadge(
                  dureeStr,
                  color,
                  icon: Icons.access_time_rounded,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── 2 boutons Série 1 & Série 2 ───────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => lancerSerie(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Série 1',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => lancerSerie(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Text(
                        'Série 2',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Badge pilule ─────────────────────────────────────────────
  Widget _buildPillBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
            Text('Accès Premium',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
            child: const Text("S'abonner",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
