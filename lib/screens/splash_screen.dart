import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/bell_service.dart';
import '../widgets/logo_widget.dart';
import 'onboarding_screen.dart';
import 'bienvenue_screen.dart';
import 'home_screen.dart';
import 'post_login_welcome_screen.dart';

// ══════════════════════════════════════════════════════════════════════
// SPLASH SCREEN — EF-FORT.BF v2.1 (Particules + Son rétabli)
// FLUX FIGÉ (verrouillé) :
//   1. SplashScreen    → Animation logo + SON d'intro + bulles
//   2. OnboardingScreen → 5 slides pédagogiques
//   3. BienvenueScreen  → Animation bienvenue premium + SON
//   4. LoginScreen      → Authentification
//   5. Dashboard        → Espace utilisateur
// NE PAS MODIFIER L'ORDRE DE CES ÉTAPES
// ══════════════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _particleAnim;

  // Bulles fixes générées une seule fois
  final List<_Bubble> _bubbles = [];
  final math.Random _rng = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _particleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    // Générer les bulles (positions aléatoires fixes)
    for (int i = 0; i < 18; i++) {
      _bubbles.add(_Bubble(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 6.0 + _rng.nextDouble() * 18.0,
        speed: 0.15 + _rng.nextDouble() * 0.35,
        opacity: 0.08 + _rng.nextDouble() * 0.18,
        phase: _rng.nextDouble(),
      ));
    }

    _controller.forward();
    // ── Son d'introduction de la première animation ──────────────────
    _playIntroSound();
    _checkAuth();
  }

  /// Joue le son d'intro au lancement du Splash Screen (première animation)
  Future<void> _playIntroSound() async {
    // Petit délai pour laisser l'animation démarrer avant le son
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    try {
      await BellService.playStart();
    } catch (_) {
      // Silencieux en cas d'erreur
    }
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final hasToken = await ApiService.loadToken();
    if (!mounted) return;

    if (hasToken) {
      // Utilisateur déjà connecté → Animation bienvenue OBLIGATOIRE à chaque fois
      final user = ApiService.currentUser;
      final nom = user != null
          ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
          : '';
      Navigator.pushReplacement(
        context,
        _fadeRoute(PostLoginWelcomeScreen(
          userName: nom.isNotEmpty ? nom : 'Candidat',
        )),
      );
    } else {
      // Vérifier si c'est la première fois (onboarding pas encore vu)
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_done') ?? false;
      if (!mounted) return;

      if (!onboardingDone) {
        // 1ère fois → Onboarding complet
        Navigator.pushReplacement(
          context,
          _fadeRoute(const OnboardingScreen()),
        );
      } else {
        // Déjà vu l'onboarding → Page de bienvenue directement
        Navigator.pushReplacement(
          context,
          _fadeRoute(const BienvenueScreen()),
        );
      }
    }
  }

  /// Transition fade douce depuis le splash
  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Stack(
          children: [
            // ── Bulles / particules animées en fond ──────────────
            AnimatedBuilder(
              animation: _particleAnim,
              builder: (_, __) {
                return CustomPaint(
                  size: size,
                  painter: _BubblePainter(
                    bubbles: _bubbles,
                    progress: _particleAnim.value,
                  ),
                );
              },
            ),

            // ── Contenu principal animé ──────────────────────────
            Positioned.fill(
              child: Center(
                child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LogoWidget(size: 160, borderRadius: 24),
                        const SizedBox(height: 32),
                        const Text(
                          'EF-FORT.BF',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Concours Directs',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Prépare-toi. Bats-toi. Décroche-le.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.white,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 60),
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modèle d'une bulle ───────────────────────────────────────────────
class _Bubble {
  final double x;     // position X relative [0..1]
  final double y;     // position Y de départ relative [0..1]
  final double size;  // diamètre en pixels
  final double speed; // vitesse relative
  final double opacity;
  final double phase; // décalage de phase [0..1]

  const _Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

// ── Peintre des bulles animées ───────────────────────────────────────
class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double progress; // [0..1] en boucle

  const _BubblePainter({required this.bubbles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      // Progression propre à chaque bulle (avec phase)
      final p = ((progress * b.speed + b.phase) % 1.0);
      // La bulle monte de bas en haut
      final x = b.x * size.width + math.sin(p * math.pi * 2 + b.phase * 6) * 18;
      final y = size.height - (p * (size.height + b.size * 2)) + b.y * 40;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: b.opacity * (1.0 - p * 0.6))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(Offset(x, y), b.size / 2, paint);

      // Petite étoile dans la bulle (toutes les 3 bulles)
      if (bubbles.indexOf(b) % 3 == 0) {
        final paintFill = Paint()
          ..color = Colors.white.withValues(alpha: b.opacity * 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), b.size / 6, paintFill);
      }
    }
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
