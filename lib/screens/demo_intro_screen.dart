import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/bell_service.dart';
import '../widgets/logo_widget.dart';
import 'bienvenue_screen.dart';
import 'demo_examen_screen.dart';
import 'post_login_welcome_screen.dart';

// ══════════════════════════════════════════════════════════════════════
// DEMO INTRO SCREEN — Page de présentation de la démo gratuite
// POSITION FIGÉE DANS LE FLUX :
//   APRÈS OnboardingScreen (5 slides) → AVANT BienvenueScreen / Dashboard
//
// Comportement :
//   - Pour les NOUVEAUX visiteurs (non connectés) : la démo est
//     fortement encouragée. Bouton « Découvrir la démo gratuite »
//     mis en avant + bouton secondaire « Passer ».
//   - Pour les utilisateurs DÉJÀ connectés : possibilité de passer
//     directement vers le dashboard via PostLoginWelcomeScreen.
// ══════════════════════════════════════════════════════════════════════

class DemoIntroScreen extends StatefulWidget {
  const DemoIntroScreen({super.key});

  @override
  State<DemoIntroScreen> createState() => _DemoIntroScreenState();
}

class _DemoIntroScreenState extends State<DemoIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  bool _isLoggedIn = false;
  String _userName = '';
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final hasToken = await ApiService.loadToken();
    if (!mounted) return;
    if (hasToken && ApiService.currentUser != null) {
      final user = ApiService.currentUser!;
      final nom = '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim();
      setState(() {
        _isLoggedIn = true;
        _userName = nom.isNotEmpty ? nom : 'Candidat';
        _checkingAuth = false;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
        _checkingAuth = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goToDemo() {
    BellService.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DemoExamenScreen(),
      ),
    );
  }

  void _skipDemo() {
    BellService.playClick();
    if (_isLoggedIn) {
      // Utilisateur déjà connecté → animation bienvenue retour
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => PostLoginWelcomeScreen(
            userName: _userName,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      // Nouveau visiteur → vers BienvenueScreen puis Login
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const BienvenueScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A2E1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4A017)),
        ),
      );
    }

    // PopScope bloque le retour arrière
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.3),
              radius: 1.6,
              colors: [
                Color(0xFF1E6B42),
                Color(0xFF0F3D24),
                Color(0xFF0A2E1A),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: Column(
                  children: [
                    // Bouton "Passer" en haut à droite (visible pour les
                    // utilisateurs déjà connectés OU les nouveaux visiteurs
                    // qui veulent absolument passer)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _skipDemo,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isLoggedIn ? 'Aller au tableau de bord' : 'Passer',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Logo
                    const LogoWidget(size: 80, borderRadius: 18),
                    const SizedBox(height: 20),

                    // Badge "Nouveau"
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4A017).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFD4A017).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        '🎁  100% GRATUIT — SANS INSCRIPTION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD4A017),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Titre principal
                    const Text(
                      'Avant de continuer…',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFD4A017), Color(0xFFFFD451)],
                      ).createShader(bounds),
                      child: const Text(
                        'Teste l\'application\nen conditions réelles',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Découvre une simulation d\'examen blanc complète : '
                      '50 questions, 1h30 chrono, surveillant virtuel, sons, '
                      'feuille de réponses et PDF imprimables.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Carte points forts
                    _buildFeatureCard(),
                    const SizedBox(height: 24),

                    // Bouton principal pulsant — DÉCOUVRIR LA DÉMO
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _goToDemo,
                          icon: const Icon(
                            Icons.play_circle_filled_rounded,
                            size: 28,
                            color: Color(0xFF0A2E1A),
                          ),
                          label: const Text(
                            'DÉCOUVRIR LA DÉMO GRATUITE',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                              color: Color(0xFF0A2E1A),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A017),
                            foregroundColor: const Color(0xFF0A2E1A),
                            elevation: 8,
                            shadowColor:
                                const Color(0xFFD4A017).withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bouton secondaire — Passer (lien discret)
                    TextButton.icon(
                      onPressed: _skipDemo,
                      icon: Icon(
                        _isLoggedIn
                            ? Icons.dashboard_rounded
                            : Icons.login_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      label: Text(
                        _isLoggedIn
                            ? 'Continuer vers mon tableau de bord'
                            : 'J\'ai déjà un compte — Me connecter',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Footer rassurant
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Aucune carte bancaire · Aucun engagement',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard() {
    final features = <_DemoFeature>[
      _DemoFeature(
        icon: Icons.quiz_rounded,
        emoji: '📝',
        title: '50 questions officielles',
        sub: 'Niveau concours direct',
      ),
      _DemoFeature(
        icon: Icons.timer_rounded,
        emoji: '⏱️',
        title: '1h30 chrono',
        sub: 'Comme le jour J',
      ),
      _DemoFeature(
        icon: Icons.record_voice_over_rounded,
        emoji: '👮',
        title: 'Surveillant virtuel',
        sub: 'Messages d\'encouragement',
      ),
      _DemoFeature(
        icon: Icons.notifications_active_rounded,
        emoji: '🔔',
        title: 'Sons de cloches',
        sub: 'Atmosphère réelle',
      ),
      _DemoFeature(
        icon: Icons.picture_as_pdf_rounded,
        emoji: '📄',
        title: 'PDF imprimables',
        sub: 'Sujet + correction',
      ),
      _DemoFeature(
        icon: Icons.check_circle_rounded,
        emoji: '✅',
        title: 'Correction détaillée',
        sub: 'Score + explications',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD4A017).withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CE QUI T\'ATTEND',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFFD4A017),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFD4A017).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          f.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            f.sub,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _DemoFeature {
  final IconData icon;
  final String emoji;
  final String title;
  final String sub;
  const _DemoFeature({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.sub,
  });
}


