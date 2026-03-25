import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/logo_widget.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': null,
      'showLogo': true,
      'title': 'Bienvenue sur EF-FORT.BF',
      'subtitle': 'La plateforme N.1 de preparation aux concours directs de la Fonction Publique du Burkina Faso',
      'bgColor': AppColors.primary,
    },
    {
      'icon': Icons.menu_book_rounded,
      'showLogo': false,
      'title': '+250 QCM Reelles',
      'subtitle': 'Questions tirees de vrais concours passes : Culture Generale, Francais, Mathematiques, Droit, Economie...',
      'bgColor': AppColors.secondary,
    },
    {
      'icon': Icons.timer_outlined,
      'showLogo': false,
      'title': 'Simulation d\'Examen',
      'subtitle': '50 questions en 1h30 avec bareme officiel : +1 bonne reponse, -1 mauvaise, 0 sans reponse',
      'bgColor': AppColors.primary,
    },
    {
      'icon': Icons.people_alt_rounded,
      'showLogo': false,
      'title': 'Communaute d\'Entraide',
      'subtitle': 'Echangez conseils et experiences avec d\'autres candidats. Ensemble, on est plus forts !',
      'bgColor': AppColors.secondary,
    },
    {
      'icon': Icons.description_rounded,
      'showLogo': false,
      'title': 'Corrections Detaillees',
      'subtitle': 'Chaque question est corrigee avec une explication claire. Comprenez vos erreurs et progressez !',
      'bgColor': AppColors.primary,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
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
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              final bgColor = slide['bgColor'] as Color;
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bgColor,
                      bgColor == AppColors.primary ? AppColors.primaryDark : const Color(0xFFB8860B),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (slide['showLogo'] == true) ...[
                          const LogoWidget(size: 140, borderRadius: 24),
                        ] else ...[
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              slide['icon'] as IconData,
                              size: 60,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                        const SizedBox(height: 48),
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          slide['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.white
                                : AppColors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        if (_currentPage > 0)
                          TextButton(
                            onPressed: _goToLogin,
                            child: const Text(
                              'Passer',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        const Spacer(),
                        ElevatedButton(
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
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            _currentPage == _slides.length - 1
                                ? 'Commencer'
                                : 'Suivant',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
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
