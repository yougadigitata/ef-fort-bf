import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'dashboard_screen.dart';
import 'matieres_screen.dart';
import 'simulation_screen.dart';
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
    setState(() => _currentIndex = 2);
  }

  void _goToMatieres() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onGoToSimulation: _goToSimulation,
        onGoToMatieres: _goToMatieres,
      ),
      const MatieresScreen(),
      const SimulationLaunchScreen(),
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
                _buildNavItem(2, '⏱️', 'Examen'),
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
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: isActive ? 26 : 22,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
