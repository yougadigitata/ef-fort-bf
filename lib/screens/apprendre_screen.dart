import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/progression_service.dart';
import '../services/cours_service.dart';
import 'cours_list_screen.dart' show CoursListScreen;
import 'domaine_detail_screen.dart';

// ══════════════════════════════════════════════════════════════
// APPRENDRE SCREEN v10.0 — Tableau de bord e-learning
// Inspiré Coursera : Progression, Mes cours, Certifications
// ══════════════════════════════════════════════════════════════

class ApprendreScreen extends StatefulWidget {
  const ApprendreScreen({super.key});

  @override
  State<ApprendreScreen> createState() => _ApprendreScreenState();
}

class _ApprendreScreenState extends State<ApprendreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserStats? _stats;
  List<Map<String, dynamic>> _mesDomaines = [];
  final Map<String, int> _pourcentages = {};
  bool _loading = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final matieres = await ApiService.getMatieres();
      UserStats? stats;
      try {
        stats = await ProgressionService.getUserStats();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _mesDomaines = (matieres as List<dynamic>).cast<Map<String, dynamic>>();
          _stats = stats;
          _loading = false;
        });
        _animCtrl.forward(from: 0);
        _loadPourcentages();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPourcentages() async {
    for (final m in _mesDomaines) {
      final id = (m['matiere_id'] ?? '').toString();
      if (id.isEmpty) continue;
      try {
        final pct = await CoursService.getPourcentageMatiere(id);
        if (mounted) setState(() => _pourcentages[id] = pct);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Apprendre',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Tableau de bord'),
                Tab(text: 'Mes cours'),
                Tab(text: 'Certifications'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _TableauDeBordTab(
              stats: _stats,
              domaines: _mesDomaines,
              pourcentages: _pourcentages,
              loading: _loading,
              fadeAnim: _fadeAnim,
              onRefresh: _loadData,
            ),
            // Onglet Mes cours — garde CoursListScreen pour compatibilité complète
            const CoursListScreen(),
            _CertificationsTab(stats: _stats),
          ],
        ),
      ),
    );
  }
}

// ── Tableau de bord ───────────────────────────────────────────

class _TableauDeBordTab extends StatelessWidget {
  final UserStats? stats;
  final List<Map<String, dynamic>> domaines;
  final Map<String, int> pourcentages;
  final bool loading;
  final Animation<double> fadeAnim;
  final Future<void> Function() onRefresh;

  const _TableauDeBordTab({
    required this.stats,
    required this.domaines,
    required this.pourcentages,
    required this.loading,
    required this.fadeAnim,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: FadeTransition(
        opacity: fadeAnim,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bannière progression globale
            _buildProgressionBanner(),
            const SizedBox(height: 20),
            // Statistiques détaillées
            _buildStatsGrid(),
            const SizedBox(height: 20),
            // Graphique par domaine
            _buildDomainesProgression(context),
            const SizedBox(height: 20),
            // Bouton continuer
            _buildContinuerBtn(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressionBanner() {
    final total = stats?.nbQuestionsRepondues ?? 0;
    final taux = stats?.tauxReussiteGlobal ?? 0.0;
    final note = stats?.noteSur20 ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0056D2), Color(0xFF003FA3)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Votre progression globale',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de progression globale
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: taux / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFCD116)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${taux.toStringAsFixed(0)}% de réussite',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '$total questions répondues',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        note.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Note / 20',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${stats?.nbSimulations ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Simulations',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${stats?.nbBonnesReponses ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Bonnes rép.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final domOptim = pourcentages.values.where((p) => p >= 50).length;
    final domEnCours = pourcentages.values.where((p) => p > 0 && p < 50).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.book_outlined,
            color: const Color(0xFF0891B2),
            label: 'Domaines\nentamés',
            value: '${domEnCours + domOptim}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.workspace_premium_outlined,
            color: const Color(0xFF7C3AED),
            label: 'Domaines\nmaîtrisés',
            value: '$domOptim',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_outlined,
            color: const Color(0xFFD97706),
            label: 'Score\nmoyen',
            value: '${(stats?.scoreMoyenSimulation ?? 0).toStringAsFixed(0)}%',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainesProgression(BuildContext context) {
    final domavecProgres = domaines.where((d) {
      final id = (d['matiere_id'] ?? '').toString();
      return (pourcentages[id] ?? 0) > 0;
    }).toList();

    if (domavecProgres.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          children: [
            Text('📚', style: TextStyle(fontSize: 40)),
            SizedBox(height: 12),
            Text(
              'Commencez à apprendre',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            SizedBox(height: 6),
            Text(
              'Explorez les domaines pour commencer votre parcours d\'apprentissage',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progression par domaine',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ...domavecProgres.take(5).map((d) {
          final id = (d['matiere_id'] ?? '').toString();
          final nom = (d['matiere_nom'] ?? d['nom'] ?? 'Domaine').toString();
          final code = (d['matiere_code'] ?? d['code'] ?? '').toString().toLowerCase();
          final pct = pourcentages[id] ?? 0;
          final color = _getColor(code);
          final icone = _getIcone(code);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DomaineDetailScreen(
                    matiereId: id,
                    matiereNom: nom,
                    matiereCode: code,
                    couleur: color,
                    icone: icone,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Text(icone, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              nom,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: color.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.chevron_right, color: AppColors.textSubtle, size: 18),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContinuerBtn(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Naviguer vers l'onglet Mes cours
          final tabCtrl = DefaultTabController.of(context);
          tabCtrl.animateTo(1);
        },
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: const Text('Continuer où j\'en étais'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Color _getColor(String code) {
    const colors = {
      'hg': Color(0xFFBD3B3B), 'droit2': Color(0xFF1A5C38), 'eco2': Color(0xFF27AE60),
      'ang': Color(0xFF2980B9), 'sp': Color(0xFFE74C3C), 'psycho': Color(0xFF8E44AD),
      'psy': Color(0xFF8E44AD), 'histo': Color(0xFFC0392B), 'info': Color(0xFF16A085),
      'comm': Color(0xFFE67E22), 'aes': Color(0xFF006B3F), 'bf': Color(0xFFEF2B2D),
      'burkina_faso': Color(0xFFEF2B2D), 'armee': Color(0xFF34495E),
      'actu': Color(0xFFF39C12), 'maths': Color(0xFF3498DB), 'svt': Color(0xFF1ABC9C),
      'cg': Color(0xFF9B59B6), 'pana': Color(0xFFD35400), 'fr': Color(0xFF1A5C38),
      'pc': Color(0xFFE74C3C), 'enaref': Color(0xFF1A5C38), 'haut': Color(0xFF8B0000),
    };
    return colors[code] ?? const Color(0xFF0056D2);
  }

  String _getIcone(String code) {
    const icons = {
      'hg': '🗺️', 'droit2': '⚖️', 'eco2': '💰', 'ang': '🗣️', 'sp': '⚛️',
      'psycho': '🧩', 'psy': '🧠', 'histo': '👤', 'info': '💻', 'comm': '📢',
      'aes': '🌍', 'bf': '🇧🇫', 'burkina_faso': '🇧🇫', 'armee': '🪖',
      'actu': '📰', 'maths': '🔢', 'svt': '🧬', 'cg': '🌍', 'pana': '🌍',
      'fr': '📖', 'pc': '🔬', 'enaref': '🏛️', 'haut': '🎓',
    };
    return icons[code] ?? '📚';
  }
}

// ── Certifications ─────────────────────────────────────────────

class _CertificationsTab extends StatelessWidget {
  final UserStats? stats;

  const _CertificationsTab({this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats?.nbQuestionsRepondues ?? 0;
    // Simule des certifications basées sur la progression
    final certifs = [
      {
        'titre': 'Initiation au Droit Burkinabè',
        'domaine': 'Droit & Juridique',
        'icone': '⚖️',
        'color': 0xFF1A5C38,
        'requis': 50,
        'obtenu': total >= 50,
      },
      {
        'titre': 'Psychotechnique Niveau 1',
        'domaine': 'Psychotechnique',
        'icone': '🧩',
        'color': 0xFF8E44AD,
        'requis': 100,
        'obtenu': total >= 100,
      },
      {
        'titre': 'Culture Générale Afrique',
        'domaine': 'Culture générale',
        'icone': '🌍',
        'color': 0xFFD97706,
        'requis': 150,
        'obtenu': total >= 150,
      },
      {
        'titre': 'Expert Concours Fonction Publique',
        'domaine': 'Toutes matières',
        'icone': '🏆',
        'color': 0xFF0056D2,
        'requis': 300,
        'obtenu': total >= 300,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bannière info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Text('🏆', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Système de certifications',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    Text(
                      'Répondez aux questions et progressez pour débloquer vos certifications gratuites',
                      style: TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '$total questions répondues au total',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 12),
        ...certifs.map((c) => _buildCertifCard(c)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildCertifCard(Map<String, dynamic> c) {
    final color = Color(c['color'] as int);
    final obtenu = c['obtenu'] as bool;
    final requis = c['requis'] as int;
    final total = stats?.nbQuestionsRepondues ?? 0;
    final progress = (total / requis).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: obtenu ? color.withValues(alpha: 0.4) : AppColors.divider,
          width: obtenu ? 1.5 : 1,
        ),
        boxShadow: obtenu
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          // Médaille
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: obtenu ? color.withValues(alpha: 0.12) : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    c['icone'] as String,
                    style: TextStyle(
                      fontSize: 26,
                      color: obtenu ? null : Colors.grey,
                    ),
                  ),
                  if (!obtenu)
                    const Icon(Icons.lock_outline, color: AppColors.textSubtle, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c['titre'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: obtenu ? AppColors.textDark : AppColors.textLight,
                        ),
                      ),
                    ),
                    if (obtenu)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'OBTENU ✓',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c['domaine'] as String,
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                const SizedBox(height: 8),
                if (!obtenu) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% — $requis questions requises',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSubtle),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
