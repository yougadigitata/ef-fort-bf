import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/progression_service.dart' show UserStats, ProgressionService;

// ══════════════════════════════════════════════════════════════
// DASHBOARD SCREEN v10.0 — Accueil style Coursera
// Découverte, domaines populaires, recommandations
// ══════════════════════════════════════════════════════════════

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onGoToSimulation;
  final VoidCallback? onGoToMatieres;
  final VoidCallback? onGoToProgres;
  final VoidCallback? onGoToExplorer;

  const DashboardScreen({
    super.key,
    this.onGoToSimulation,
    this.onGoToMatieres,
    this.onGoToProgres,
    this.onGoToExplorer,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  UserStats? _stats; // nullable
  List<dynamic> _domaines = [];
  bool _loadingDomaines = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final matieres = await ApiService.getMatieres();
      UserStats? stats;
      try {
        stats = await ProgressionService.getUserStats();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _domaines = (matieres as List<dynamic>).take(6).toList();
          _stats = stats;
          _loadingDomaines = false;
        });
        _animCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDomaines = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final prenom = user?['prenom'] ?? user?['nom'] ?? 'Apprenant';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(prenom),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats rapides (si données dispo)
                    if (_stats != null) _buildQuickStats(),
                    // Section objectifs
                    _buildGoalsSection(),
                    // Domaines
                    _buildDomainesSection(),
                    // Parcours recommandés
                    _buildParcoursSection(),
                    // CTA inscription
                    if (!ApiService.isLoggedIn) _buildCtaSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(String prenom) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0056D2),
                Color(0xFF003FA3),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Motifs décoratifs
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              // Contenu
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          // Logo texte
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'EF-FORT.BF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Barre de recherche compacte
                          GestureDetector(
                            onTap: widget.onGoToExplorer,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.search, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text('Rechercher', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Bonjour, $prenom 👋',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Que voulez-vous\napprendre aujourd\'hui ?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        title: const Text(
          'EF-FORT.BF',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_stats == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _buildMiniStat('${_stats!.nbQuestionsRepondues}', 'Questions\nrépondues', Icons.quiz_outlined),
          _buildDividerV(),
          _buildMiniStat('${_stats!.tauxReussiteGlobal.toStringAsFixed(0)}%', 'Taux de\nréussite', Icons.trending_up),
          _buildDividerV(),
          _buildMiniStat('${_stats!.noteSur20.toStringAsFixed(1)}/20', 'Note\nglobale', Icons.star_outline),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDividerV() {
    return Container(width: 1, height: 50, color: AppColors.divider);
  }

  Widget _buildGoalsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quel est votre objectif ?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGoalCard(
                  icon: '🎯',
                  title: 'Réussir un\nconcours',
                  color: AppColors.primary,
                  onTap: widget.onGoToExplorer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGoalCard(
                  icon: '📈',
                  title: 'Développer\nmes compétences',
                  color: AppColors.secondary,
                  onTap: widget.onGoToMatieres,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGoalCard(
                  icon: '🏆',
                  title: 'Obtenir une\ncertification',
                  color: const Color(0xFF7C3AED),
                  onTap: widget.onGoToProgres,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required String icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Explorer les domaines',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onGoToExplorer,
                child: const Text(
                  'Tout voir',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingDomaines)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
              ),
            )
          else if (_domaines.isEmpty)
            _buildDomainesStatic()
          else
            _buildDomainesDynamic(),
        ],
      ),
    );
  }

  static const _domainesStatiques = [
    {'code': 'droit2', 'nom': 'Droit', 'icone': '⚖️', 'couleur': 0xFF1A5C38, 'nb': '450+ questions'},
    {'code': 'fr', 'nom': 'Français', 'icone': '📖', 'couleur': 0xFF0056D2, 'nb': '380+ questions'},
    {'code': 'psycho', 'nom': 'Psychotechnique', 'icone': '🧩', 'couleur': 0xFF7C3AED, 'nb': '620+ questions'},
    {'code': 'maths', 'nom': 'Mathématiques', 'icone': '🔢', 'couleur': 0xFF0891B2, 'nb': '290+ questions'},
    {'code': 'cg', 'nom': 'Culture générale', 'icone': '🌍', 'couleur': 0xFFD97706, 'nb': '510+ questions'},
    {'code': 'info', 'nom': 'Informatique', 'icone': '💻', 'couleur': 0xFF059669, 'nb': '220+ questions'},
  ];

  Widget _buildDomainesStatic() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: _domainesStatiques.length,
      itemBuilder: (context, i) {
        final d = _domainesStatiques[i];
        return _buildDomaineCard(
          icone: d['icone'] as String,
          nom: d['nom'] as String,
          subtitle: d['nb'] as String,
          color: Color(d['couleur'] as int),
          onTap: widget.onGoToExplorer,
        );
      },
    );
  }

  Widget _buildDomainesDynamic() {
    final colors = AppColors.domaineColors;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: _domaines.length,
      itemBuilder: (context, i) {
        final d = _domaines[i] as Map<String, dynamic>;
        final code = (d['matiere_code'] ?? d['code'] ?? '').toString().toLowerCase();
        final nom = d['matiere_nom'] ?? d['nom'] ?? 'Domaine';
        final icone = _getIcone(code);
        final color = colors[i % colors.length];
        return _buildDomaineCard(
          icone: icone,
          nom: nom,
          subtitle: 'Formation gratuite',
          color: color,
          onTap: widget.onGoToExplorer,
        );
      },
    );
  }

  Widget _buildDomaineCard({
    required String icone,
    required String nom,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(icone, style: const TextStyle(fontSize: 28)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParcoursSection() {
    final parcours = [
      {
        'titre': 'Devenir expert en Droit',
        'desc': 'Droit constitutionnel, administratif et civil',
        'modules': '3 modules · 12 leçons',
        'icone': '⚖️',
        'color': 0xFF1A5C38,
      },
      {
        'titre': 'Maîtriser la Psychotechnique',
        'desc': 'Tests de logique et raisonnement abstrait',
        'modules': '4 modules · 18 leçons',
        'icone': '🧩',
        'color': 0xFF7C3AED,
      },
      {
        'titre': 'Excellence en Culture Générale',
        'desc': 'Actualité, histoire et géopolitique africaine',
        'modules': '5 modules · 24 leçons',
        'icone': '🌍',
        'color': 0xFFD97706,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parcours recommandés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Des formations complètes pour atteindre vos objectifs',
            style: TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 14),
          ...parcours.map((p) => _buildParcoursCard(p)),
        ],
      ),
    );
  }

  Widget _buildParcoursCard(Map<String, dynamic> p) {
    final color = Color(p['color'] as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onGoToExplorer,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(p['icone'] as String, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['titre'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p['desc'] as String,
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p['modules'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '100% Gratuit',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSubtle, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCtaSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0056D2), Color(0xFF003FA3)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Commencez à faire évoluer\nvotre carrière',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Apprenez à votre rythme, développez des compétences recherchées',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'S\'inscrire gratuitement →',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getIcone(String code) {
    const icons = {
      'hg': '🗺️', 'droit2': '⚖️', 'eco2': '💰', 'ang': '🗣️',
      'sp': '⚛️', 'psycho': '🧩', 'psy': '🧠', 'histo': '👤',
      'info': '💻', 'comm': '📢', 'aes': '🌍', 'bf': '🇧🇫',
      'burkina_faso': '🇧🇫', 'armee': '🪖', 'actu': '📰',
      'maths': '🔢', 'svt': '🧬', 'cg': '🌍', 'pana': '🌍',
      'fr': '📖', 'pc': '🔬', 'enaref': '🏛️', 'haut': '🎓',
    };
    return icons[code] ?? '📚';
  }
}
