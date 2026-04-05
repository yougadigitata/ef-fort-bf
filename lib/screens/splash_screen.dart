import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/bell_service.dart';
import '../widgets/logo_widget.dart';
import 'onboarding_screen.dart';
import 'bienvenue_screen.dart';
import 'home_screen.dart';

// ══════════════════════════════════════════════════════════════════════
// SPLASH SCREEN — EF-FORT.BF
// FLUX FIGÉ (verrouillé) :
//   1. SplashScreen    → Animation logo + SON d'intro
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
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
      // Utilisateur connecté → Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        // Déjà vu l'onboarding → Page de bienvenue directement
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BienvenueScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}
