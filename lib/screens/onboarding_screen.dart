import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _slides = [
    {
      'emoji': '🏆',
      'showLogo': false,
      'title': 'EF-FORT.BF\nLa Réussite N°1',
      'subtitle':
          'La seule plateforme 100% Burkinabè pour réussir les concours de la Fonction Publique. Conçue par des Burkinabè, pour des Burkinabè.',
      'bgColor': const Color(0xFF1A5C38),
      'bgColor2': const Color(0xFF0F3D26),
      'accent': const Color(0xFFD4A017),
      'badges': ['20 000+ QCM', '18 Matières', '100% Gratuit*'],
    },
    {
      'emoji': '📚',
      'showLogo': false,
      'title': 'Maîtrisez TOUTES\nles Matières',
      'subtitle':
          'Droit · Économie · Informatique · Anglais · Mathématiques · SVT et bien plus. Chaque matière avec des séries progressives de QCM réels.',
      'bgColor': const Color(0xFFD4A017),
      'bgColor2': const Color(0xFFB8860B),
      'accent': AppColors.white,
      'badges': ['Droit', 'Informatique', 'Anglais', '+15 matières'],
    },
    {
      'emoji': '⏱️',
      'showLogo': false,
      'title': 'Simulation Examen\nComme le VRAI Jour',
      'subtitle':
          '50 questions · 1h30 · Barème officiel\nEntraînez-vous dans les conditions réelles du concours. Analysez vos forces et faiblesses.',
      'bgColor': const Color(0xFF1A5C38),
      'bgColor2': const Color(0xFF0F3D26),
      'accent': const Color(0xFFD4A017),
      'badges': ['50 questions', '1h30 chrono', 'Barème officiel'],
    },
    {
      'emoji': '📄',
      'showLogo': false,
      'title': '10 000+ Copies PDF\nImprimables',
      'subtitle':
          'Imprimez vos corrections, révisez hors connexion. Partagez vos fiches. Construisez votre bibliothèque personnelle de révision.',
      'bgColor': const Color(0xFFD4A017),
      'bgColor2': const Color(0xFFB8860B),
      'accent': AppColors.white,
      'badges': ['Export PDF', 'Mode hors-ligne', 'Partage facile'],
    },
    {
      'emoji': '🤝',
      'showLogo': false,
      'title': 'Une Communauté\nQui Vous Booste',
      'subtitle':
          'Échangez avec des candidats du Burkina. Posez vos questions. Recevez les infos en temps réel. Progressez ensemble vers la réussite.',
      'bgColor': const Color(0xFF1A5C38),
      'bgColor2': const Color(0xFF0F3D26),
      'accent': const Color(0xFFD4A017),
      'badges': ['Communauté active', 'Actualités concours', 'Entraide 24h/24'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Slides
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              final bgColor = slide['bgColor'] as Color;
              final bgColor2 = slide['bgColor2'] as Color;
              final accent = slide['accent'] as Color;
              final isGold = bgColor == const Color(0xFFD4A017);

              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bgColor, bgColor2],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icône 3D (emoji grand format dans container stylisé)
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: 0.15),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                slide['emoji'] as String,
                                style: const TextStyle(fontSize: 72),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Badge numéro de slide
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: accent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${index + 1} / ${_slides.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Titre
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: isGold ? const Color(0xFF1A5C38) : AppColors.white,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sous-titre
                        Text(
                          slide['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: (isGold ? const Color(0xFF1A5C38) : AppColors.white)
                                .withValues(alpha: 0.85),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Badges
                        if (slide['badges'] != null)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: (slide['badges'] as List<String>).map((badge) =>
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  badge,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isGold ? const Color(0xFF1A5C38) : accent,
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Bouton "Passer" en haut à droite
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: TextButton(
                onPressed: _goToLogin,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Passer',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bas : dots + boutons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
                child: Column(
                  children: [
                    // Indicateurs de pages
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) {
                          final isActive = _currentPage == index;
                          final isGoldPage = _slides[_currentPage]['bgColor'] ==
                              const Color(0xFFD4A017);
                          final dotColor =
                              isGoldPage ? const Color(0xFF1A5C38) : AppColors.white;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? dotColor
                                  : dotColor.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Bouton principal
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _slides.length - 1) {
                            _goToLogin();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _slides[_currentPage]['bgColor'] ==
                                  const Color(0xFFD4A017)
                              ? const Color(0xFF1A5C38)
                              : const Color(0xFFD4A017),
                          foregroundColor: AppColors.white,
                          elevation: 6,
                          shadowColor: Colors.black.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _slides.length - 1
                                  ? '🚀  Commencer maintenant'
                                  : 'Suivant',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (_currentPage < _slides.length - 1) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
