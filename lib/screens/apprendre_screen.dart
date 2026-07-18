import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/progression_service.dart';
import 'cours_list_screen.dart';
import 'services_marketing_screen.dart';

// ══════════════════════════════════════════════════════════════
// APPRENDRE SCREEN — Hub central de l'espace apprentissage
// 3 onglets : Tableau de bord · Cours · Services
// ══════════════════════════════════════════════════════════════

class ApprendreScreen extends StatefulWidget {
  const ApprendreScreen({super.key});

  @override
  State<ApprendreScreen> createState() => _ApprendreScreenState();
}

class _ApprendreScreenState extends State<ApprendreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text(
          '🎓 Apprendre',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
        ),
        foregroundColor: AppColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: 'Tableau de bord'),
            Tab(icon: Icon(Icons.book_rounded, size: 20), text: 'Cours'),
            Tab(icon: Icon(Icons.store_rounded, size: 20), text: 'Services'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TableauDeBordTab(),
          CoursListScreen(),
          ServicesMarketingScreen(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TABLEAU DE BORD — Profil d'apprentissage
// ══════════════════════════════════════════════════════════════

class _TableauDeBordTab extends StatefulWidget {
  const _TableauDeBordTab();

  @override
  State<_TableauDeBordTab> createState() => _TableauDeBordTabState();
}

class _TableauDeBordTabState extends State<_TableauDeBordTab>
    with AutomaticKeepAliveClientMixin {
  UserStats? _stats;
  Map<String, dynamic> _dashStats = {};
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await ProgressionService.getUserStats();
      final dash = await ApiService.getUserDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _dashStats = dash;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ApiService.currentUser;
    final prenom = user?['prenom'] ?? '';
    final nom = user?['nom'] ?? '';
    final nomComplet = '$prenom $nom'.trim();
    final niveau = user?['niveau'] ?? 'N/A';

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── En-tête profil ──
                  _buildProfileCard(nomComplet, niveau),
                  const SizedBox(height: 20),

                  // ── Titre section stats ──
                  const Row(
                    children: [
                      Text('📊 ', style: TextStyle(fontSize: 20)),
                      Text(
                        'Mes statistiques',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Grille de stats ──
                  _buildStatsGrid(),
                  const SizedBox(height: 20),

                  // ── Progression par matière ──
                  _buildProgressionSection(),
                  const SizedBox(height: 20),

                  // ── Dernières activités ──
                  _buildActivitesSection(),
                  const SizedBox(height: 20),

                  // ── Motivation ──
                  _buildMotivationCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard(String nomComplet, String niveau) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            child: Center(
              child: Text(
                nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomComplet.isNotEmpty ? nomComplet : 'Candidat',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '🎓 Niveau : $niveau',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Compte actif',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
      final s = _stats;
    final questionsTotal = s?.nbQuestionsRepondues ?? 0;
    final correctes = s?.nbBonnesReponses ?? 0;
    final sessions = s?.nbSimulations ?? 0;
    final taux = questionsTotal > 0
        ? (correctes / questionsTotal * 100).toStringAsFixed(0)
        : '0';
    final noteMoyenne = questionsTotal > 0
        ? (correctes / questionsTotal * 20).toStringAsFixed(1)
        : '—';

    // Stats additionnelles depuis dashboard
    final simuls = _dashStats['nb_simulations'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard('❓ Questions', '$questionsTotal', 'répondues', AppColors.primary),
        _buildStatCard('✅ Correctes', '$correctes', 'bonnes réponses', AppColors.success),
        _buildStatCard('📈 Taux', '$taux%', 'de réussite', Colors.blue),
        _buildStatCard('⭐ Note moy.', noteMoyenne, 'sur 20', AppColors.secondary),
        _buildStatCard('🎯 Sessions', '$sessions', 'QCM effectués', Colors.purple),
        _buildStatCard('🏆 Simulations', '$simuls', 'réalisées', AppColors.red),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionSection() {
    final s = _stats;
    final matieres = s?.statsByMatiere ?? {};
    if (matieres.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Text('📚 ', style: TextStyle(fontSize: 18)),
                Text(
                  'Progression par matière',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Icon(Icons.quiz_outlined, size: 48, color: AppColors.textLight.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            const Text(
              'Commencez un QCM pour voir\nvos progrès par matière !',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📚 ', style: TextStyle(fontSize: 18)),
              Text(
                'Progression par matière',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...matieres.entries.take(5).map((e) {
            final mat = e.value;
            final total = mat.questionsVues;
            final correct = mat.questionsCorrectes;
            final taux = total > 0 ? correct / total : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                  child: Text(
                      mat.matiereNom,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$correct/$total  (${(taux * 100).toInt()}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: taux >= 0.6 ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: taux,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        taux >= 0.6 ? AppColors.success : taux >= 0.4 ? Colors.orange : AppColors.error,
                      ),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivitesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🕐 ', style: TextStyle(fontSize: 18)),
              Text(
                'Dernières activités',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActiviteItem('📝 QCM Mathématiques', 'Hier', AppColors.primary),
          _buildActiviteItem('📖 Cours Droit Public', 'Il y a 2 jours', Colors.blue),
          _buildActiviteItem('🎯 Simulation officielle', 'Il y a 3 jours', AppColors.secondary),
          const Center(
            child: Text(
              'Continuez à pratiquer pour voir\nplus d\'activités ici !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiviteItem(String label, String date, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            date,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    final s = _stats;
    final taux = (s?.nbQuestionsRepondues ?? 0) > 0
        ? ((s!.nbBonnesReponses / s.nbQuestionsRepondues) * 100).round()
        : 0;

    String msg;
    String emoji;
    if (taux >= 80) {
      msg = 'Tu es en excellente forme ! Continue comme ça et tu vas décrocher ce concours !';
      emoji = '🏆';
    } else if (taux >= 60) {
      msg = 'Bon travail ! Tu progresses bien. Encore un peu d\'effort et tu seras imbattable !';
      emoji = '💪';
    } else if (taux >= 40) {
      msg = 'Continue à pratiquer ! Chaque question te rapproche de ton objectif.';
      emoji = '📈';
    } else {
      msg = 'Ne te décourage pas ! Commence par les cours et reviens faire les QCM. Tu peux le faire !';
      emoji = '🌱';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A017), Color(0xFFB8860B)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A017).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
