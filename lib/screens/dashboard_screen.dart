import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/bell_service.dart';
import '../widgets/logo_widget.dart';
import 'abonnement_screen.dart';
import 'actualites_chat_screen.dart';
import 'entraide_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onGoToSimulation;
  final VoidCallback? onGoToMatieres;
  const DashboardScreen({super.key, this.onGoToSimulation, this.onGoToMatieres});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  List<dynamic> _actualites = [];
  bool _loadingActu = true;
  // Bannière de bienvenue supprimée (mission de refonte page d'accueil)
  // Le champ est conservé pour compatibilité interne.
  // ignore: unused_field, prefer_final_fields
  bool _showWelcome = true;

  // ── Ticker actualités ──────────────────────────────────────────────
  late AnimationController _tickerController;
  late ScrollController _tickerScrollController;

  // Stats utilisateur
  String _scoresMoyen = '--';
  String _nbSimulations = '0';
  String _nbQuestions = '0';

  // ── Animation Controllers ──────────────────────────────────────────
  late AnimationController _headerParticleController;
  late AnimationController _shimmerController;
  late AnimationController _pulseSimController;
  late AnimationController _cardSlideController;
  late AnimationController _statsCountController;
  late AnimationController _floatController;
  late AnimationController _rotateController;

  // ── Animations ────────────────────────────────────────────────────
  late Animation<double> _headerParticleAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _pulseSimAnim;
  late Animation<double> _cardSlideAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _tickerScrollController = ScrollController();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadUserStats();
      _cardSlideController.forward();
      // Son d'arrivée sur le dashboard (fanfare de succès)
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) BellService.playDashboard();
      });
    });
  }

  void _initAnimations() {
    _headerParticleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseSimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _cardSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _statsCountController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _headerParticleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerParticleController, curve: Curves.linear),
    );
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _pulseSimAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseSimController, curve: Curves.easeInOut),
    );
    _cardSlideAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardSlideController, curve: Curves.easeOutCubic),
    );
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _rotateAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _headerParticleController.dispose();
    _shimmerController.dispose();
    _pulseSimController.dispose();
    _cardSlideController.dispose();
    _statsCountController.dispose();
    _floatController.dispose();
    _rotateController.dispose();
    _tickerController.dispose();
    _tickerScrollController.dispose();
    super.dispose();
  }

  @override
  void activate() {
    super.activate();
    _loadUserStats();
  }

  Future<void> _loadData() async {
    final actu = await ApiService.getActualites();
    if (mounted) {
      setState(() {
        _actualites = actu;
        _loadingActu = false;
      });
    }
    // Recharger les stats utilisateur en même temps
    await _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    // Charger stats depuis API (temps réel)
    final stats = await ApiService.getUserStats();
    if (mounted) {
      setState(() {
        final nbSim = stats['nb_simulations'] ?? 0;
        final score = stats['score_moyen'] ?? 0.0;
        final questions = stats['questions_repondues'] ?? 0;
        _nbSimulations = '$nbSim';
        _scoresMoyen = nbSim > 0 ? '${score.toStringAsFixed(0)}%' : '--';
        _nbQuestions = '$questions';
      });
    }
    // Relancer dans 30 secondes pour mise à jour automatique
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) _loadUserStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final prenom = user?['prenom'] ?? 'Candidat';
    final nom = user?['nom'] ?? '';
    final niveau = user?['niveau'] ?? 'BAC';
    final isAbonne = user?['abonnement_actif'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── SECTION 1 : En-tête PREMIUM animé ─────────────────
              SliverToBoxAdapter(
                child: _buildPremiumHeader(prenom, nom, niveau, isAbonne),
              ),

              // ─── SECTION 1b : Bandeau ACTUALITÉS défilant AGRANDI ──
              //    (occupe l'espace de l'ancienne bannière de bienvenue)
              if (_loadingActu)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                )
              else if (_actualites.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildNewsTicker(),
                ),

              // ─── SECTION 3 : Bouton SIMULATION animé ───────────────
              SliverToBoxAdapter(
                child: _buildSimulationButton(),
              ),

              // ─── SECTION 3b : Bouton "J'AI PAYÉ — ENVOYER MA DEMANDE"
              //                 (visible uniquement si non abonné) ────
              if (!isAbonne)
                SliverToBoxAdapter(
                  child: _buildDemandeAbonnementButton(),
                ),

              // ─── SECTION 4 : Matières rapides ──────────────────────
              SliverToBoxAdapter(
                child: _buildMatieresSection(),
              ),

              // ─── SECTION 6 : Abonnement animé ───────────────────────
              SliverToBoxAdapter(
                child: _buildAbonnementSection(isAbonne),
              ),

              // ─── SECTION 7 : Communauté ──────────────────────────────
              SliverToBoxAdapter(
                child: _buildCommunitySection(),
              ),

              // ─── SECTION 8 : Citation burkinabè du jour ─────────────
              const SliverToBoxAdapter(
                child: _CitationBurkinabeWidget(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BANDEAU NEWS TICKER — Défilant automatique avec badge NOUVEAU
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildNewsTicker() {
    if (_actualites.isEmpty) return const SizedBox.shrink();
    // Construire le texte défilant : toutes les actualités séparées par ••
    final titres = _actualites
        .map((a) => a['titre']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toList();
    if (titres.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActualitesChatScreen(actualites: _actualites),
          ),
        );
      },
      child: Container(
        // Marges extérieures pour remplir l'espace de l'ancienne bannière
        margin: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0E3D24), Color(0xFF1A5C38), Color(0xFFD4A017)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A5C38).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Cercle rouge clignotant "ACTU"
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3B30), Color(0xFFD61A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.55),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🔴',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'ACTU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Séparateur vertical
            Container(
              width: 1.5,
              height: 40,
              color: Colors.white.withValues(alpha: 0.28),
            ),
            const SizedBox(width: 10),
            // Texte défilant + titre
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'Actualités Concours',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_actualites.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 22,
                    child: _TickerText(
                      items: titres,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Icône flèche "Voir"
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // EN-TÊTE PREMIUM — Particules + Shimmer + Stats animées
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPremiumHeader(String prenom, String nom, String niveau, bool isAbonne) {
    return AnimatedBuilder(
      animation: Listenable.merge([_headerParticleAnim, _shimmerAnim, _floatAnim]),
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E6B42),
                Color(0xFF1A5C38),
                Color(0xFF0F3D24),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A5C38).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Particules dorées flottantes ──
              CustomPaint(
                painter: _HeaderParticlePainter(
                  progress: _headerParticleAnim.value,
                ),
                child: const SizedBox(height: 200, width: double.infinity),
              ),

              // ── Cercles décoratifs lumineux ──
              Positioned(
                right: -30,
                top: -30,
                child: Transform.rotate(
                  angle: _rotateAnim.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4A017).withValues(alpha: 0.15),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: 10,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD4A017).withValues(alpha: 0.06),
                  ),
                ),
              ),

              // ── Contenu principal ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  children: [
                    // Ligne utilisateur
                    Row(
                      children: [
                        // Avatar avec bordure dorée brillante
                        AnimatedBuilder(
                          animation: _floatAnim,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _floatAnim.value * 0.3),
                            child: child,
                          ),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD4A017), Color(0xFFF0C040)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4A017).withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.5),
                              child: ClipOval(
                                child: const LogoWidget(size: 47, borderRadius: 24),
                              ),
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
                                  Text(
                                    'Bonjour $prenom 👋',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              // Message motivant animé
                              _buildShimmerText(
                                '🔥 Continue sur ta lancée !',
                                fontSize: 11,
                              ),
                            ],
                          ),
                        ),
                        // Badge abonnement premium
                        _buildPremiumBadge(isAbonne),
                        const SizedBox(width: 8),
                        _buildNotifBadge(),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Niveau et stats
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Niveau badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1A5C38), Color(0xFF2D8F5E)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🎓', style: TextStyle(fontSize: 14)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Niveau : $niveau',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                              Flexible(
                                child: Text(
                                '$nom',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Stats 3 colonnes avec animation
                          Row(
                            children: [
                              _buildAnimatedStat('🎯', 'Score moyen', _scoresMoyen),
                              _buildStatDivider(),
                              _buildAnimatedStat('📝', 'Simulations', _nbSimulations),
                              _buildStatDivider(),
                              _buildAnimatedStat('✅', 'Questions', _nbQuestions),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // ── Barre de progression niveau — Micro-amélioration #5
                          _buildNiveauProgressBar(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerText(String text, {double fontSize = 13}) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: 0.6),
                const Color(0xFFD4A017),
                Colors.white.withValues(alpha: 0.6),
              ],
              stops: [
                (_shimmerAnim.value - 0.4).clamp(0.0, 1.0),
                _shimmerAnim.value.clamp(0.0, 1.0),
                (_shimmerAnim.value + 0.4).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumBadge(bool isAbonne) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: isAbonne
            ? const LinearGradient(
                colors: [Color(0xFFD4A017), Color(0xFFB8860B)],
              )
            : null,
        color: isAbonne ? null : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAbonne
              ? const Color(0xFFF0C040)
              : Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: isAbonne
            ? [
                BoxShadow(
                  color: const Color(0xFFD4A017).withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Text(
        isAbonne ? '👑 Premium' : '🔓 Gratuit',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildNotifBadge() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
        ),
        if (_actualites.isNotEmpty)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFFD4A017),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedStat(String emoji, String label, String value) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _floatAnim,
        builder: (_, __) {
          return Transform.translate(
            offset: Offset(0, _floatAnim.value * 0.15),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD4A017),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  // ── Barre de progression niveau candidat — Micro-amélioration #5 ──
  Widget _buildNiveauProgressBar() {
    // Calculer le niveau basé sur le nombre de questions traitées
    final nbQ = int.tryParse(_nbQuestions.replaceAll('+', '').replaceAll(' ', '')) ?? 0;
    final nbSim = int.tryParse(_nbSimulations) ?? 0;

    // Niveau basé sur les questions (paliers : 0-50, 50-200, 200-500, 500-1000, 1000+)
    String niveau;
    double progress;
    String nextMilestone;
    Color niveauColor;

    if (nbQ >= 1000) {
      niveau = '🏆 Champion';
      progress = 1.0;
      nextMilestone = 'Niveau max atteint !';
      niveauColor = const Color(0xFFD4A017);
    } else if (nbQ >= 500) {
      niveau = '💎 Expert';
      progress = (nbQ - 500) / 500;
      nextMilestone = '${1000 - nbQ} questions pour Champion';
      niveauColor = const Color(0xFF9C27B0);
    } else if (nbQ >= 200) {
      niveau = '🚀 Avancé';
      progress = (nbQ - 200) / 300;
      nextMilestone = '${500 - nbQ} questions pour Expert';
      niveauColor = const Color(0xFF2196F3);
    } else if (nbQ >= 50) {
      niveau = '📈 Intermédiaire';
      progress = (nbQ - 50) / 150;
      nextMilestone = '${200 - nbQ} questions pour Avancé';
      niveauColor = const Color(0xFF4CAF50);
    } else {
      niveau = '🌱 Débutant';
      progress = nbQ == 0 ? 0.0 : nbQ / 50;
      nextMilestone = nbQ == 0 ? 'Commence ta 1ère série !' : '${50 - nbQ} questions pour Intermédiaire';
      niveauColor = Colors.white.withValues(alpha: 0.7);
    }

    // Bonus simulation
    final simBonus = nbSim > 0 ? ' · $nbSim simulation${nbSim > 1 ? 's' : ''}' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              flex: 2,
              child: Text(
                niveau,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              flex: 3,
              child: Text(
                nextMilestone + simBonus,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(niveauColor),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BANNIÈRE DE BIENVENUE animée — [DÉSACTIVÉE]
  // Méthode conservée pour historique / potentielle réactivation future.
  // Elle n'est plus référencée dans le build (mission de refonte accueil).
  // ═══════════════════════════════════════════════════════════════════
  // ignore: unused_element
  Widget _buildWelcomeBanner() {
    return AnimatedBuilder(
      animation: _cardSlideAnim,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _cardSlideAnim.value)),
          child: Opacity(
            opacity: _cardSlideAnim.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4A017), Color(0xFFE8C030)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A017).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _floatAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _floatAnim.value * 0.5),
                  child: child,
                ),
                child: const Text('🎯', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bienvenue sur EF-FORT.BF !',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A5C38),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chaque effort te rapproche de ton admission finale. 💪',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF1A5C38).withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showWelcome = false),
                child: Icon(
                  Icons.close_rounded,
                  color: const Color(0xFF1A5C38).withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BOUTON SIMULATION — Grand bouton animé pulsant
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSimulationButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: GestureDetector(
        onTap: () => widget.onGoToSimulation?.call(),
        child: AnimatedBuilder(
          animation: _pulseSimAnim,
          builder: (_, child) {
            return Transform.scale(
              scale: _pulseSimAnim.value,
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: _shimmerAnim,
            builder: (_, __) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE8A000),
                      Color(0xFFD4A017),
                      Color(0xFFE67E22),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4A017).withValues(alpha: 0.5),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFFE67E22).withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Effet shimmer
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                              stops: [
                                (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                                _shimmerAnim.value.clamp(0.0, 1.0),
                                (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                              ],
                            ).createShader(bounds);
                          },
                          child: Container(color: Colors.white),
                        ),
                      ),
                    ),
                    // Contenu
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text('🚀', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LANCER UNE SIMULATION',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  _buildSimTag('⏱️', '50 questions'),
                                  const SizedBox(width: 6),
                                  _buildSimTag('⏰', '1h30'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '🎯 Objectif : 70%+ · Conditions réelles',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSimTag(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$emoji $text',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BOUTON "J'AI PAYÉ — ENVOYER MA DEMANDE" (Page d'accueil)
  // Envoie la demande à l'administrateur via ApiService
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildDemandeAbonnementButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF25D366).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25D366).withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bouton principal
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _envoyerDemandeDepuisAccueil,
                icon: const Text('📩', style: TextStyle(fontSize: 22)),
                label: const Text(
                  'J\'AI PAYÉ — ENVOYER MA DEMANDE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: const Color(0xFF25D366).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Explication sous le bouton
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Si vous avez effectué votre paiement via Orange Money, soumettez votre demande ici. Notre équipe vous débloquera l\'accès premium.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      height: 1.4,
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

  /// Envoie la demande d'abonnement depuis la page d'accueil
  Future<void> _envoyerDemandeDepuisAccueil() async {
    // Vérifier que l'utilisateur est connecté
    if (!ApiService.isLoggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous devez être connecté pour envoyer une demande.',
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Afficher un dialogue de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Text('📩', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Envoyer ma demande',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: const Text(
          'Confirmez-vous avoir effectué le paiement de 12 000 FCFA via Orange Money ?\n\nVotre demande sera transmise à notre équipe qui activera votre accès premium.',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Confirmer',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final result = await ApiService.demanderAbonnement('Orange Money');
    if (!mounted) return;
    Navigator.pop(context); // Fermer le loader

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Demande envoyée ! Notre équipe va vous contacter très prochainement.',
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 6),
        ),
      );
    } else if (result['pending'] == true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Text('⌛', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Text(
                'Demande en cours',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: const Text(
            'Votre demande est déjà en cours de traitement.\nNotre équipe vous contacte très prochainement.',
            style: TextStyle(height: 1.5, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (result['already_subscribed'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre abonnement est déjà actif !'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Erreur lors de l\'envoi'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION MATIÈRES avec entrée animée en cascade
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMatieresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('📚 Mes Matières'),
              GestureDetector(
                onTap: () => widget.onGoToMatieres?.call(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'Voir tout →',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20),
            children: _buildAnimatedMatiereChips(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION ABONNEMENT
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAbonnementSection(bool isAbonne) {
    return AnimatedBuilder(
      animation: _cardSlideAnim,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - _cardSlideAnim.value)),
          child: Opacity(
            opacity: _cardSlideAnim.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AbonnementScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFD4A017).withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4A017).withValues(alpha: 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4A017), Color(0xFFE8B520)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4A017).withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text('💳', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Débloquer EF-FORT Complet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: '12 000 FCFA ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFD4A017),
                                  ),
                                ),
                                TextSpan(
                                  text: '· jusqu\'au 31/12/2028',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppColors.primary, size: 16),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildAdvantageTag('✅ Questions illimitées'),
                    _buildAdvantageTag('📄 PDF corrigés'),
                    _buildAdvantageTag('🤝 Entraide'),
                    _buildAdvantageTag('🏆 Simulations'),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AbonnementScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    child: const Text(
                      '🚀  VOIR L\'OFFRE PREMIUM',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvantageTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION COMMUNAUTÉ
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCommunitySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EntraideScreen()),
        ),
        child: AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _floatAnim.value * 0.3),
            child: child,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.06),
                  AppColors.primary.withValues(alpha: 0.14),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseSimAnim,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseSimAnim.value,
                    child: child,
                  ),
                  child: const Text('🤝', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rejoindre la Communauté',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Des candidats actifs vous attendent',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMiniTag('🟢 En ligne'),
                          const SizedBox(width: 6),
                          _buildMiniTag('24h/24'),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF2D8F5E)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Rejoindre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CHIPS MATIÈRES animés
  // ═══════════════════════════════════════════════════════════════════
  List<Widget> _buildAnimatedMatiereChips() {
    final matieres = [
      {'emoji': '🌍', 'label': 'Culture G.', 'color': const Color(0xFF1A5C38)},
      {'emoji': '🧠', 'label': 'Psycho', 'color': const Color(0xFF8E44AD)},
      {'emoji': '📐', 'label': 'Maths', 'color': const Color(0xFFE67E22)},
      {'emoji': '📝', 'label': 'Français', 'color': const Color(0xFF2980B9)},
      {'emoji': '⚖️', 'label': 'Droit', 'color': const Color(0xFF1A5C38)},
      {'emoji': '🎲', 'label': 'Dominos', 'color': const Color(0xFF16A085)},
      {'emoji': '📊', 'label': 'Économie', 'color': const Color(0xFFD4A017)},
    ];

    return matieres.asMap().entries.map((entry) {
      final i = entry.key;
      final m = entry.value;
      final color = m['color'] as Color;

      return AnimatedBuilder(
        animation: _floatAnim,
        builder: (_, child) {
          final offset = math.sin(_floatAnim.value * 0.1 + i * 0.8) * 2.5;
          return Transform.translate(
            offset: Offset(0, offset),
            child: child,
          );
        },
        child: _ScaleTapWidget(
          onTap: () => widget.onGoToMatieres?.call(),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(m['emoji'] as String, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  m['label'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PAINTER : Particules flottantes dorées dans l'en-tête
// ═══════════════════════════════════════════════════════════════════════
class _HeaderParticlePainter extends CustomPainter {
  final double progress;
  static final _random = math.Random(42);
  static late List<_Particle> _particles;
  static bool _initialized = false;

  _HeaderParticlePainter({required this.progress}) {
    if (!_initialized) {
      _particles = List.generate(30, (i) => _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 1.5 + _random.nextDouble() * 3,
        speed: 0.15 + _random.nextDouble() * 0.25,
        opacity: 0.2 + _random.nextDouble() * 0.6,
        phase: _random.nextDouble(),
      ));
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final phase = (progress * p.speed + p.phase) % 1.0;
      final y = size.height * (1 - phase);
      final x = p.x * size.width + math.sin(phase * 2 * math.pi) * 20;

      // Scintillement
      final alpha = math.sin(phase * math.pi) * p.opacity;

      final paint = Paint()
        ..color = const Color(0xFFD4A017).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      // Étoile ou cercle
      if (p.size > 3) {
        _drawStar(canvas, Offset(x, y), p.size * 1.2, paint);
      } else {
        canvas.drawCircle(Offset(x, y), p.size, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 4;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final radius = i.isEven ? size : size * 0.4;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HeaderParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, size, speed, opacity, phase;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

// ══════════════════════════════════════════════════════════════════════
// WIDGET EFFET SCALE AU CLIC — Micro-amélioration #2
// Applique un léger rebond (scale down/up) au clic
// ══════════════════════════════════════════════════════════════════════
class _ScaleTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ScaleTapWidget({required this.child, this.onTap});

  @override
  State<_ScaleTapWidget> createState() => _ScaleTapWidgetState();
}

class _ScaleTapWidgetState extends State<_ScaleTapWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    widget.onTap?.call();
  }
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// WIDGET CITATION BURKINABÈ DU JOUR — Micro-amélioration #1
// ══════════════════════════════════════════════════════════════════════
class _CitationBurkinabeWidget extends StatefulWidget {
  const _CitationBurkinabeWidget();

  @override
  State<_CitationBurkinabeWidget> createState() => _CitationBurkinabeWidgetState();
}

class _CitationBurkinabeWidgetState extends State<_CitationBurkinabeWidget>
    with SingleTickerProviderStateMixin {
  static const List<Map<String, String>> _citations = [
    {
      'texte': 'L\'effort d\'aujourd\'hui est la victoire de demain.',
      'source': 'Sagesse burkinabè',
    },
    {
      'texte': 'Celui qui avance lentement mais sûrement arrive toujours à bon port.',
      'source': 'Proverbe mooré',
    },
    {
      'texte': 'La connaissance est le meilleur héritage que tu peux laisser à tes enfants.',
      'source': 'Sagesse africaine',
    },
    {
      'texte': 'Un seul bracelet ne fait pas de bruit. Ensemble, nous réussirons.',
      'source': 'Proverbe burkinabè',
    },
    {
      'texte': 'Chaque question maîtrisée est une pierre posée sur ta maison de réussite.',
      'source': 'EF-FORT.BF',
    },
    {
      'texte': 'Le courage n\'est pas l\'absence de peur, c\'est décider que quelque chose est plus important que la peur.',
      'source': 'Sagesse africaine',
    },
    {
      'texte': 'Révise comme si tu devais passer le concours demain. Vis comme si tu avais toute la vie.',
      'source': 'EF-FORT.BF',
    },
    {
      'texte': 'L\'étalon du Faso ne recule jamais. Avance, candidat !',
      'source': 'Burkina Faso',
    },
    {
      'texte': 'Si tu veux aller vite, marche seul. Si tu veux aller loin, marchons ensemble.',
      'source': 'Proverbe africain',
    },
    {
      'texte': 'La persévérance est la clé qui ouvre toutes les portes de la réussite.',
      'source': 'Sagesse burkinabè',
    },
  ];

  late final int _citationIndex;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    // Choisir une citation basée sur le jour de l'année
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    _citationIndex = dayOfYear % _citations.length;

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final citation = _citations[_citationIndex];
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A5C38).withValues(alpha: 0.08),
                const Color(0xFFD4A017).withValues(alpha: 0.08),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF1A5C38).withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drapeau BF stylisé
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5C38),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🦁', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💬 Citation du jour',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A5C38),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${citation['texte']}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF2D2D2D),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '— ${citation['source']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// _TickerText — Widget de texte défilant automatique pour les actualités
// ══════════════════════════════════════════════════════════════════════
class _TickerText extends StatefulWidget {
  final List<String> items;
  final TextStyle? textStyle;
  const _TickerText({required this.items, this.textStyle});

  @override
  State<_TickerText> createState() => _TickerTextState();
}

class _TickerTextState extends State<_TickerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _ctrl.forward();
    _startRotation();
  }

  void _startRotation() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      _ctrl.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.items.length;
        });
        _ctrl.forward().then((_) {
          _startRotation();
        });
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.items.isEmpty ? '' : widget.items[_currentIndex];
    return FadeTransition(
      opacity: _anim,
      child: Text(
        '▶  $text',
        style: widget.textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
