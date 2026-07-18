import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/bell_service.dart';
import 'dashboard_screen.dart';
import 'apprendre_screen.dart';
import 'explorer_screen.dart';
import 'examen_selection_screen.dart';
import 'profil_screen.dart';

// ══════════════════════════════════════════════════════════════
// HOME SCREEN v10.0 — Navigation e-learning style Coursera
// 5 onglets : Accueil · Explorer · Apprendre · Formations · Profil
// ══════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _goToExplorer() {
    setState(() => _currentIndex = 1);
  }

  void _goToApprendre() {
    setState(() => _currentIndex = 2);
  }

  void _goToFormations() {
    setState(() => _currentIndex = 3);
  }

  void _goToProfil() {
    setState(() => _currentIndex = 4);
  }

  void _navigateToIndex(int index) {
    BellService.playWelcome();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onGoToExplorer: _goToExplorer,
        onGoToMatieres: _goToApprendre,
        onGoToSimulation: _goToFormations,
        onGoToProgres: _goToApprendre,
      ),
      const ExplorerScreen(),         // Explorer les domaines
      const ApprendreScreen(),         // Apprendre — tableau de bord + cours + certifications
      const ExamenSelectionScreen(),   // Formations — Examens & simulations
      const ProfilScreen(),            // Profil
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Accueil'),
              _buildNavItem(1, Icons.explore_rounded, Icons.explore_outlined, 'Explorer'),
              _buildNavItem(2, Icons.school_rounded, Icons.school_outlined, 'Apprendre'),
              _buildNavItem(3, Icons.assignment_rounded, Icons.assignment_outlined, 'Examens'),
              _buildNavItem(4, Icons.person_rounded, Icons.person_outlined, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;

    return _NavItemBounce(
      onTap: () => _navigateToIndex(index),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                size: 24,
                color: isActive ? AppColors.primary : AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textSubtle,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Micro-interaction rebond ─────────────────────────────────────
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
      reverseDuration: const Duration(milliseconds: 200),
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
