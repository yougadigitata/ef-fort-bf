import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/bell_service.dart';
import 'abonnement_screen.dart';
import 'dashboard_screen.dart';
import 'matieres_screen.dart';
import 'examen_selection_screen.dart';
import 'entraide_screen.dart';
import 'profil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _goToSimulation() {
    // Simulation = section Premium (onglet 2 = Concours)
    final isAbonne = ApiService.isAbonne || ApiService.isAdmin;
    if (!isAbonne) {
      _showPremiumWall(2);
      return;
    }
    setState(() => _currentIndex = 2);
  }

  void _goToMatieres() {
    setState(() => _currentIndex = 1);
  }

  // ── Vérification accès premium avant navigation ───────────────────
  void _navigateToIndex(int index) {
    // Onglets 2 (Concours/Examens) et 3 (Entraide) = Premium uniquement
    final isPremiumSection = index == 2 || index == 3;
    final isAbonne = ApiService.isAbonne || ApiService.isAdmin;

    if (isPremiumSection && !isAbonne) {
      BellService.playClick();
      _showPremiumWall(index);
      return;
    }
    BellService.playTransition();
    setState(() => _currentIndex = index);
  }

  void _showPremiumWall(int targetIndex) {
    final sectionName = targetIndex == 2 ? 'Concours & Examens' : 'Entraide';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Text('👑', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Text(
              'Accès Premium',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La section "$sectionName" est réservée aux abonnés Premium.',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Plan gratuit : Accès à la 1ère série de chaque matière.',
              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Plan Premium : Toutes les séries + Examens + Simulations + Entraide.',
              style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AbonnementScreen()),
              );
            },
            icon: const Icon(Icons.star_rounded, size: 16, color: Colors.white),
            label: const Text('S\'abonner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A5C38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onGoToSimulation: _goToSimulation,
        onGoToMatieres: _goToMatieres,
      ),
      const MatieresScreen(),
      const ExamenSelectionScreen(),   // Phase 3 : 10 examens
      const EntraideScreen(),
      const ProfilScreen(),
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
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, '🏠', 'Accueil'),
                _buildNavItem(1, '📚', 'Matières'),
                _buildNavItem(2, '🎓', 'Concours'),
                _buildNavItem(3, '🤝', 'Entraide'),
                _buildNavItem(4, '👤', 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String emoji, String label) {
    final isActive = _currentIndex == index;
    // Badge cadenas pour sections premium
    final isPremiumSection = (index == 2 || index == 3);
    final isAbonne = ApiService.isAbonne || ApiService.isAdmin;
    final showLock = isPremiumSection && !isAbonne;

    return _NavItemBounce(
      onTap: () => _navigateToIndex(index),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                if (showLock)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, size: 9, color: Colors.white),
                    ),
                  ),
              ],
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
