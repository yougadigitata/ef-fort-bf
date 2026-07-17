import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/bell_service.dart';
import 'dashboard_screen.dart';
import 'cours_list_screen.dart';
import 'matieres_screen.dart';
import 'examen_selection_screen.dart';
import 'entraide_screen.dart';
import 'profil_screen.dart';
import 'mes_progres_screen.dart';

// ══════════════════════════════════════════════════════════════
// HOME SCREEN v2.0 — Navigation e-learning redesignée
// 5 onglets : Accueil · Apprendre · S'entraîner · Entraide · Progrès
// ══════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _goToSimulation() {
    setState(() => _currentIndex = 3);
  }

  void _goToMatieres() {
    setState(() => _currentIndex = 2);
  }

  void _goToProgres() {
    setState(() => _currentIndex = 5);
  }

  // ── Navigation libre — accès complet pour tous ───────────────────
  void _navigateToIndex(int index) {
    BellService.playWelcome();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onGoToSimulation: _goToSimulation,
        onGoToMatieres: _goToMatieres,
        onGoToProgres: _goToProgres,
      ),
      const CoursListScreen(),         // "Cours" — Chapitres & Leçons e-learning v2
      const MatieresScreen(),          // "Apprendre" — QCM par matière
      const ExamenSelectionScreen(),   // "S'entraîner" — Examens & simulations
      const EntraideScreen(),          // Communauté
      const MesProgresScreen(),        // "Mes Progrès" — Tableau de bord
      const ProfilScreen(),            // Profil (accessible depuis Profil)
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, '🏠', 'Accueil'),
                _buildNavItem(1, '🎓', 'Cours'),
                _buildNavItem(2, '📚', 'QCM'),
                _buildNavItem(3, '🎯', 'Examens'),
                _buildNavItem(4, '🤝', 'Entraide'),
                _buildNavItem(5, '📊', 'Progrès'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String emoji, String label) {
    final isActive = _currentIndex == index;

    return _NavItemBounce(
      onTap: () => _navigateToIndex(index),
      child: SizedBox(
        width: 55,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isActive ? 27 : 22,
                ),
                child: Text(emoji),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textLight,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Micro-interaction rebond sur les items de navigation ─────────────
class _NavItemBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _NavItemBounce({required this.child, required this.onTap});

  @override
  State<_NavItemBounce> createState() => _NavItemBounceState();
}

class _NavItemBounceState extends State<_NavItemBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
