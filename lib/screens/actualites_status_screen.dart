import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Écran Actualités style "Statuts WhatsApp"
/// Navigation : swipe horizontal gauche/droite ou tap zones
class ActualitesStatusScreen extends StatefulWidget {
  final List<dynamic> actualites;
  final int initialIndex;

  const ActualitesStatusScreen({
    super.key,
    required this.actualites,
    this.initialIndex = 0,
  });

  @override
  State<ActualitesStatusScreen> createState() => _ActualitesStatusScreenState();
}

class _ActualitesStatusScreenState extends State<ActualitesStatusScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;

  // Progression bar animation
  late AnimationController _progressController;
  static const Duration _statusDuration = Duration(seconds: 7);

  // Palette de couleurs pour les fonds (style WhatsApp vibrant)
  static const List<List<Color>> _gradients = [
    [Color(0xFF1A5C38), Color(0xFF0E3D24)],   // Vert EF-FORT
    [Color(0xFF6B21A8), Color(0xFF4C1D95)],   // Violet profond
    [Color(0xFFD4A017), Color(0xFFB8860B)],   // Or Burkina
    [Color(0xFFCE1126), Color(0xFF8B0000)],   // Rouge Faso
    [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],   // Bleu royal
    [Color(0xFF0F766E), Color(0xFF134E4A)],   // Teal
    [Color(0xFFB45309), Color(0xFF92400E)],   // Orange brûlé
    [Color(0xFF7C3AED), Color(0xFF5B21B6)],   // Violet vif
    [Color(0xFF059669), Color(0xFF047857)],   // Vert émeraude
    [Color(0xFFDC2626), Color(0xFFB91C1C)],   // Rouge vif
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: _statusDuration,
    );
    _startProgress();
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward().then((_) {
      if (mounted) {
        _nextStatus();
      }
    });
  }

  void _nextStatus() {
    if (_currentIndex < widget.actualites.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStatus() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  List<Color> _getGradient(int index) {
    return _gradients[index % _gradients.length];
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays == 1) return 'Hier, ${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── PageView principal ──
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _startProgress();
            },
            itemCount: widget.actualites.length,
            itemBuilder: (context, index) {
              final actu = widget.actualites[index] as Map<String, dynamic>;
              final gradient = _getGradient(index);
              return _buildStatusCard(actu, gradient, size);
            },
          ),

          // ── Zones de tap : gauche = précédent, droite = suivant ──
          Positioned.fill(
            child: Row(
              children: [
                // Zone gauche (40% écran)
                GestureDetector(
                  onTap: _prevStatus,
                  onLongPressStart: (_) => _progressController.stop(),
                  onLongPressEnd: (_) => _progressController.forward(),
                  child: Container(
                    width: size.width * 0.4,
                    color: Colors.transparent,
                  ),
                ),
                // Zone droite (60% écran)
                GestureDetector(
                  onTap: _nextStatus,
                  onLongPressStart: (_) => _progressController.stop(),
                  onLongPressEnd: (_) => _progressController.forward(),
                  child: Container(
                    width: size.width * 0.6,
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),

          // ── Barre de progression + Header ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  // Barres de progression (une par actualité)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: List.generate(
                        widget.actualites.length,
                        (i) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: i == _currentIndex
                                ? AnimatedBuilder(
                                    animation: _progressController,
                                    builder: (_, __) => FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: _progressController.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: i < _currentIndex
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Header : Avatar + Nom + Heure + Bouton fermer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        // Avatar circulaire EF-FORT
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                            ),
                          ),
                          child: const Center(
                            child: Text('E', style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            )),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EF-FORT.BF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _formatDate(
                                  widget.actualites[_currentIndex]
                                      ['created_at']?.toString(),
                                ),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bouton fermer
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bouton Répondre en bas ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Répondre',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton coeur (like)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: Colors.white,
                        size: 22,
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

  Widget _buildStatusCard(
    Map<String, dynamic> actu,
    List<Color> gradient,
    Size size,
  ) {
    final titre = actu['titre'] ?? '';
    final contenu = actu['contenu'] ?? '';

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Stack(
        children: [
          // Motif décoratif en arrière-plan
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Contenu centré
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 120),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône décorative
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('📢', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(height: 24),

                  // Titre
                  if (titre.isNotEmpty)
                    Text(
                      titre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                  if (titre.isNotEmpty && contenu.isNotEmpty)
                    const SizedBox(height: 16),

                  // Contenu
                  if (contenu.isNotEmpty)
                    Text(
                      contenu,
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                        shadows: const [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Badge catégorie en haut à droite du contenu
          if (actu['categorie'] != null && actu['categorie'].toString().isNotEmpty)
            Positioned(
              top: size.height * 0.22,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Text(
                  actu['categorie'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
