import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../screens/actualites_status_screen.dart';

/// Widget de prévisualisation des actualités style "bulles WhatsApp Status"
/// Affiche des cercles colorés défilables horizontalement sur le Dashboard
class ActualitesStatusWidget extends StatelessWidget {
  final List<dynamic> actualites;

  const ActualitesStatusWidget({super.key, required this.actualites});

  // Mêmes gradients que ActualitesStatusScreen
  static const List<List<Color>> _gradients = [
    [Color(0xFF1A5C38), Color(0xFF0E3D24)],
    [Color(0xFF6B21A8), Color(0xFF4C1D95)],
    [Color(0xFFD4A017), Color(0xFFB8860B)],
    [Color(0xFFCE1126), Color(0xFF8B0000)],
    [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
    [Color(0xFF0F766E), Color(0xFF134E4A)],
    [Color(0xFFB45309), Color(0xFF92400E)],
    [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    [Color(0xFF059669), Color(0xFF047857)],
    [Color(0xFFDC2626), Color(0xFFB91C1C)],
  ];

  List<Color> _getGradient(int index) => _gradients[index % _gradients.length];

  String _getFirstLetter(String title) {
    if (title.isEmpty) return 'E';
    return title[0].toUpperCase();
  }

  String _formatDateShort(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}min';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays == 1) return 'Hier';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (actualites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header section ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '📰 Actualités',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'NOUVEAU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ),
              const Spacer(),
              // Compteur d'actualités
              Text(
                '${actualites.length} actu.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),

        // ── Bulles défilables horizontalement ──
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 16),
            itemCount: actualites.length,
            itemBuilder: (context, index) {
              final actu = actualites[index] as Map<String, dynamic>;
              final gradient = _getGradient(index);
              final titre = (actu['titre'] ?? '').toString();
              final dateStr = _formatDateShort(actu['created_at']?.toString());

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ActualitesStatusScreen(
                        actualites: actualites,
                        initialIndex: index,
                      ),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
                child: Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      // Cercle avec bordure colorée (style WhatsApp)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Bordure gradient externe
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          // Cercle blanc interne (gap)
                          Container(
                            width: 59,
                            height: 59,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                          // Avatar intérieur avec gradient
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getFirstLetter(titre),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Titre tronqué
                      Text(
                        titre.isNotEmpty
                            ? titre
                            : (dateStr.isNotEmpty ? dateStr : 'Actualité'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
