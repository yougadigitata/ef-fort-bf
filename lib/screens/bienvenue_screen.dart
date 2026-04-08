import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/bell_service.dart';
import 'login_screen.dart';

// ══════════════════════════════════════════════════════════════════════
// PAGE D'ACCUEIL DE BIENVENUE PREMIUM — EF-FORT.BF v2.0
// POSITION FIGÉE DANS LE FLUX :
//   APRÈS OnboardingScreen (5 slides) → AVANT LoginScreen
// Son de bienvenue + message chaleureux + animations premium
// Design: Vert forêt + Or / "Le savoir est une arme"
// Le retour arrière est désactivé — parcours d'accueil non contournable.
// ══════════════════════════════════════════════════════════════════════

class BienvenueScreen extends StatefulWidget {
  const BienvenueScreen({super.key});

  @override
  State<BienvenueScreen> createState() => _BienvenueScreenState();
}

class _BienvenueScreenState extends State<BienvenueScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late AnimationController _typewriterController;

  // ── Animations ──────────────────────────────────────────────────────
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _particleAnim;

  // ── État ────────────────────────────────────────────────────────────
  bool _soundPlayed = false;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  int _visibleSection = 0;
  final List<Timer> _sectionTimers = [];

  // ── Messages défilants du bandeau ───────────────────────────────────
  final List<String> _bannerMessages = [
    '🇧🇫  Plateforme N°1 au Burkina Faso',
    '📚  20 000+ QCM · 18 Matières · Illimité',
    '🏆  Conçue par des Burkinabè, pour des Burkinabè',
    '⏱️  Simulation Examen · Conditions Réelles',
    '🤝  Communauté Burkinabè Active 24h/24',
    '👑  Premium : 12 000 FCFA = 2+ ans d\'accès',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
    _typewriterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    _particleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );
  }

  Future<void> _startSequence() async {
    // Délai initial puis lancement des animations
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _fadeController.forward();
    _slideController.forward();
    _typewriterController.forward();

    // Son de bienvenue immédiat
    await _playWelcomeSound();

    // Affichage progressif des sections
    for (int i = 1; i <= 6; i++) {
      _sectionTimers.add(Timer(Duration(milliseconds: 300 + i * 350), () {
        if (mounted) setState(() => _visibleSection = i);
      }));
    }

    // Bandeau défilant
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (t) {
      if (mounted) {
        setState(() => _currentBannerIndex =
            (_currentBannerIndex + 1) % _bannerMessages.length);
      }
    });
  }

  Future<void> _playWelcomeSound() async {
    if (_soundPlayed) return;
    _soundPlayed = true;
    try {
      // BellService gère Web (Web Audio API) ET Mobile (audioplayers)
      await BellService.playStart();
    } catch (_) {
      // Silencieux si erreur
    }
  }

  void _continuerVersLogin() {
    _bannerTimer?.cancel();
    for (final t in _sectionTimers) {
      t.cancel();
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _typewriterController.dispose();
    _bannerTimer?.cancel();
    for (final t in _sectionTimers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // PopScope bloque le retour arrière vers l'Onboarding
    return PopScope(
      canPop: false,
      child: Scaffold(
      body: Stack(
        children: [
          // ── Fond dégradé premium ────────────────────────────────────
          _buildBackground(),

          // ── Particules lumineuses flottantes ────────────────────────
          AnimatedBuilder(
            animation: _particleAnim,
            builder: (_, __) => CustomPaint(
              painter: _GlowParticlePainter(
                progress: _particleAnim.value,
                screenSize: size,
              ),
              size: Size.infinite,
            ),
          ),

          // ── Cercles décoratifs ──────────────────────────────────────
          _buildDecorCircles(size),

          // ── Contenu principal ───────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
                  child: Column(
                    children: [
                      // Bandeau défilant
                      _buildSection(0, _buildScrollBanner()),
                      const SizedBox(height: 22),

                      // Logo + Titre avec shimmer
                      _buildSection(1, _buildHeader()),
                      const SizedBox(height: 26),

                      // Message de bienvenue principal
                      _buildSection(2, _buildWelcomeCard()),
                      const SizedBox(height: 18),

                      // Stats clés
                      _buildSection(3, _buildStatsRow()),
                      const SizedBox(height: 18),

                      // Points essentiels
                      _buildSection(4, _buildKeyPoints()),
                      const SizedBox(height: 18),

                      // Badge Premium
                      _buildSection(5, _buildPremiumCard()),
                      const SizedBox(height: 28),

                      // Bouton d'entrée
                      _buildSection(6, _buildCTAButton()),
                      const SizedBox(height: 16),

                      // Footer
                      _buildSection(6, _buildFooter()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    )); // PopScope + Scaffold fermés
  }

  // ── Fond dégradé ─────────────────────────────────────────────────────
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.1, -0.3),
          radius: 1.8,
          colors: [
            Color(0xFF1E6B42),
            Color(0xFF0F3D24),
            Color(0xFF0A2E1A),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  // ── Cercles décoratifs ─────────────────────────────────────────────
  Widget _buildDecorCircles(Size size) {
    return Stack(
      children: [
        Positioned(
          right: -size.width * 0.25,
          top: -size.width * 0.25,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4A017).withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          left: -size.width * 0.3,
          bottom: size.height * 0.2,
          child: Container(
            width: size.width * 0.75,
            height: size.width * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4A017).withValues(alpha: 0.04),
            ),
          ),
        ),
        Positioned(
          right: -size.width * 0.1,
          bottom: -size.width * 0.1,
          child: Container(
            width: size.width * 0.5,
            height: size.width * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.02),
            ),
          ),
        ),
      ],
    );
  }

  // ── Animation par section ────────────────────────────────────────────
  Widget _buildSection(int index, Widget child) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _visibleSection >= index ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 450),
        offset: _visibleSection >= index ? Offset.zero : const Offset(0, 0.12),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  // ── Bandeau défilant ─────────────────────────────────────────────────
  Widget _buildScrollBanner() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.25, 0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_currentBannerIndex),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFD4A017).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFFD4A017).withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          _bannerMessages[_currentBannerIndex],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 142.5,
            color: Color(0xFFD4A017),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  // ── En-tête avec shimmer ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        // Icône pulsante
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD4A017), Color(0xFFF5C840)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4A017).withValues(alpha: 0.5),
                  blurRadius: 35,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: Text('🎓', style: TextStyle(fontSize: 48)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // "Bienvenue sur"
        const Text(
          'Bienvenue sur',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w400,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),

        // Titre EF-FORT.BF avec effet shimmer
        AnimatedBuilder(
          animation: _shimmerAnim,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [
                    Color(0xFFD4A017),
                    Color(0xFFFFF3CD),
                    Color(0xFFFFFFFF),
                    Color(0xFFFFF3CD),
                    Color(0xFFD4A017),
                  ],
                  stops: [
                    (_shimmerAnim.value - 0.5).clamp(0.0, 1.0),
                    (_shimmerAnim.value - 0.2).clamp(0.0, 1.0),
                    _shimmerAnim.value.clamp(0.0, 1.0),
                    (_shimmerAnim.value + 0.2).clamp(0.0, 1.0),
                    (_shimmerAnim.value + 0.5).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: const Text(
                'EF-FORT.BF',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Colors.white, // requis pour ShaderMask
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),
        // Sous-titre badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD4A017).withValues(alpha: 0.25),
                const Color(0xFFD4A017).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFD4A017).withValues(alpha: 0.5),
            ),
          ),
          child: const Text(
            '🏆 La Plateforme N°1 du Burkina Faso 🇧🇫',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFFD4A017),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ── Card message de bienvenue ────────────────────────────────────────
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.13),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A017).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🔊', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message de Bienvenue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD4A017),
                    ),
                  ),
                  Text(
                    'EF-FORT.BF vous accueille',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildGoldDivider(),
          const SizedBox(height: 14),

          // Message principal
          _buildMsgLine(
            '🌟',
            'Bienvenue, futur(e) fonctionnaire du Burkina Faso !',
            isHighlight: true,
          ),
          const SizedBox(height: 10),
          _buildMsgLine(
            '📚',
            'Cette plateforme est la N°1 de préparation et de renforcement '
            'des capacités au Burkina Faso. Conçue pour un apprentissage réel, '
            'riche et varié — parce que le savoir est la plus puissante des armes.',
          ),
          const SizedBox(height: 10),
          _buildMsgLine(
            '🏛️',
            'Que vous prépariez un concours direct de la Fonction Publique '
            'ou que vous désiriez simplement vous former, vous trouverez ici '
            'toutes les vraies ressources nécessaires à votre réussite.',
          ),
          const SizedBox(height: 10),
          _buildMsgLine(
            '📰',
            'Consultez la section Actualités pour les infos concours en '
            'temps réel. Ne manquez aucune annonce officielle.',
          ),
          const SizedBox(height: 10),
          _buildMsgLine(
            '🤝',
            'Rejoignez notre communauté burkinabè : posez vos questions, '
            'aidez les autres, et échangez vos contacts WhatsApp pour des '
            'discussions extérieures enrichissantes.',
          ),
          const SizedBox(height: 10),
          _buildMsgLine(
            '🛡️',
            'Lisez notre document sur la Super Sécurité en Afrique '
            '(section À propos) pour adopter les bonnes pratiques '
            'de protection en ligne.',
          ),
          const SizedBox(height: 10),
          _buildMsgLine(
            '💝',
            'Partagez EF-FORT.BF à vos proches qui désirent réellement '
            'se former. Ensemble, nous serons plus forts.',
          ),

          const SizedBox(height: 16),
          // Message final encadré
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              children: [
                Text('✨', style: TextStyle(fontSize: 14)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nous vous souhaitons un excellent apprentissage '
                    'et que la réussite soit au rendez-vous ! '
                    'Bonne chance à vous. 🇧🇫',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF22C55E),
                      fontWeight: FontWeight.w600,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMsgLine(String emoji, String text, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isHighlight ? 14.5 : 13.5,
                color: isHighlight ? Colors.white : Colors.white70,
                height: 1.6,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      {'value': '20 000+', 'label': 'QCM', 'icon': Icons.quiz_rounded},
      {'value': '18', 'label': 'Matières', 'icon': Icons.menu_book_rounded},
      {'value': '24h/24', 'label': 'Accès', 'icon': Icons.access_time_rounded},
      {'value': '100%', 'label': '🇧🇫 BF', 'icon': Icons.flag_rounded},
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD4A017).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(s['icon'] as IconData,
                    color: const Color(0xFFD4A017), size: 20),
                const SizedBox(height: 5),
                Text(
                  s['value'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  s['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Points essentiels ─────────────────────────────────────────────────
  Widget _buildKeyPoints() {
    final points = [
      (
        '📰',
        'Actualités',
        'Infos concours, résultats et annonces officielles en temps réel.'
      ),
      (
        '🤝',
        'Communauté',
        'Forum d\'entraide burkinabè — posez vos questions 24h/24.'
      ),
      (
        '📱',
        'Réseau Local',
        'Échangez vos contacts WhatsApp avec d\'autres candidats BF.'
      ),
      (
        '⏱️',
        'Simulation',
        '50 questions · 1h30 · Barème officiel · Conditions réelles.'
      ),
      (
        '🛡️',
        'À Propos',
        'Guide Super Sécurité en Afrique — protégez-vous en ligne.'
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: points.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A017).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(p.$1, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.$2,
                        style: const TextStyle(
                          fontSize: 143.5,
                          color: Color(0xFFD4A017),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        p.$3,
                        style: const TextStyle(
                          fontSize: 142.5,
                          color: Colors.white60,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Card Premium ──────────────────────────────────────────────────────
  Widget _buildPremiumCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD4A017).withValues(alpha: 0.18),
            const Color(0xFFD4A017).withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD4A017).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Titre
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👑', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accès Premium EF-FORT.BF',
                    style: TextStyle(
                      fontSize: 144.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD4A017),
                    ),
                  ),
                  Text(
                    'Un véritable cadeau pour les Burkinabè',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildGoldDivider(),
          const SizedBox(height: 12),

          // Détails premium
          _buildPremiumDetail('💰', '12 000 FCFA seulement',
              'Pour plus de 2 ans d\'accès illimité complet'),
          _buildPremiumDetail('📅', 'Valable jusqu\'en 2028',
              'Pas d\'abonnement mensuel — payez une fois, profitez 2+ ans !'),
          _buildPremiumDetail('🇧🇫', 'Prix burkinabè juste',
              'Conçu pour être accessible à chaque citoyen BF'),
          _buildPremiumDetail('♾️', 'Accès illimité total',
              '20 000+ QCM · Simulations · Examens Blancs · Communauté · PDF'),

          const SizedBox(height: 14),
          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildChip('✅ Illimité'),
              _buildChip('📅 Jusqu\'en 2028'),
              _buildChip('🇧🇫 100% Burkinabè'),
              _buildChip('♾️ Sans mensualité'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDetail(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title — ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: desc,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A017).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFFD4A017),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Bouton principal ──────────────────────────────────────────────────
  Widget _buildCTAButton() {
    return ScaleTransition(
      scale: _pulseAnim,
      child: GestureDetector(
        onTap: _continuerVersLogin,
        child: Container(
          width: double.infinity,
          height: 62,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4A017), Color(0xFFF0C840), Color(0xFFD4A017)],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A017).withValues(alpha: 0.55),
                blurRadius: 25,
                offset: const Offset(0, 8),
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rocket_launch_rounded,
                  color: Color(0xFF0A2E1A), size: 26),
              SizedBox(width: 12),
              Text(
                'Commencer mon apprentissage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A2E1A),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          '"Le savoir est la plus puissante des armes."',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFFD4A017),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Prépare-toi · Bats-toi · Décroche-le 🏆',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {}, // Action partage à implémenter
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share_rounded,
                  size: 15, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 5),
              Text(
                'Partagez EF-FORT.BF à vos proches',
                style: TextStyle(
                  fontSize: 141.5,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Séparateur or ────────────────────────────────────────────────────
  Widget _buildGoldDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFFD4A017).withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ── Painter de particules lumineuses ────────────────────────────────────
class _GlowParticlePainter extends CustomPainter {
  final double progress;
  final Size screenSize;

  const _GlowParticlePainter({
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42); // Seed fixe pour cohérence
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 18; i++) {
      final baseX = rng.nextDouble() * size.width;
      final startY = rng.nextDouble();
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final particleSize = 1.5 + rng.nextDouble() * 3.0;
      final opacity = 0.08 + rng.nextDouble() * 0.18;
      final amplitude = 20.0 + rng.nextDouble() * 40.0;

      final t = ((progress * speed) + startY) % 1.0;
      final y = size.height - (t * size.height * 1.15);
      final x = baseX + amplitude * math.sin(t * math.pi * 2 + i);

      if (y < 0 || y > size.height) continue;

      paint.color = const Color(0xFFD4A017).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(_GlowParticlePainter old) => old.progress != progress;
}

// v3.0 — 2026-04-01 — MathText Web fix + Score pourcentage + Onboarding flow
