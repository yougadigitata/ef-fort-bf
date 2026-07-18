import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/bell_service.dart';
import '../widgets/logo_widget.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

// ══════════════════════════════════════════════════════════════════════
// SPLASH SCREEN — EF-FORT.BF v9.0 (Auth persistante)
// FLUX INTELLIGENT :
//   1. Vérifier si session stockée → si oui, aller directement au dashboard
//   2. Si non → OnboardingScreen → LoginScreen
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
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _particleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

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
    _playIntroSound();
    _checkAuthAndNavigate();
  }

  Future<void> _playIntroSound() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    try {
      await BellService.playStart();
    } catch (_) {}
  }

  /// ── LOGIQUE D'AUTH INTELLIGENTE ──────────────────────────────────
  /// Si l'utilisateur a déjà une session stockée → HomeScreen directement
  /// Sinon → OnboardingScreen
  Future<void> _checkAuthAndNavigate() async {
    // Laisser l'animation se jouer (minimum 2.5s)
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Tenter de charger le token sauvegardé
    final hasSession = await ApiService.loadToken();

    if (!mounted) return;

    if (hasSession && ApiService.currentUser != null) {
      // ✅ Session valide → aller directement au dashboard sans repasser par login
      Navigator.pushReplacement(
        context,
        _fadeRoute(const HomeScreen()),
      );
    } else {
      // ❌ Pas de session → flux normal (onboarding → login)
      Navigator.pushReplacement(
        context,
        _fadeRoute(const OnboardingScreen()),
      );
    }
  }

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
            // ── Bulles animées en fond ──
            AnimatedBuilder(
              animation: _particleAnim,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _BubblePainter(bubbles: _bubbles, progress: _particleAnim.value),
              ),
            ),

            // ── Contenu principal ──
            Positioned.fill(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnim.value,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
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
                              'E-Learning Burkina',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Apprends. Pratique. Réussis.',
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

class _Bubble {
  final double x, y, size, speed, opacity, phase;
  const _Bubble({
    required this.x, required this.y, required this.size,
    required this.speed, required this.opacity, required this.phase,
  });
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double progress;

  const _BubblePainter({required this.bubbles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final p = ((progress * b.speed + b.phase) % 1.0);
      final x = b.x * size.width + math.sin(p * math.pi * 2 + b.phase * 6) * 18;
      final y = size.height - (p * (size.height + b.size * 2)) + b.y * 40;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: b.opacity * (1.0 - p * 0.6))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x, y), b.size / 2, paint);
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
